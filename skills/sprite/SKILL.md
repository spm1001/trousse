---
name: sprite
user-invocable: false
description: Manages Sprites.dev remote Ubuntu VMs with checkpoint/restore. **Load this skill BEFORE any sprite exec, bootstrap, or troubleshooting.** Triggers on 'sprite', 'create a sprite', 'checkpoint', 'remote dev', 'sprites.dev', 'bootstrap sprite', 'proxy port', 'sprite exec'. Complements server-checkup for remote machine management. (user)
---

# Sprite Skill

Manage [Sprites.dev](https://sprites.dev/) remote development environments — persistent Ubuntu VMs with checkpoint/restore from Fly.io.

## When to Load This Skill

**Load before ANY of these operations:**
- `sprite exec` — critical patterns for output capture
- Bootstrap/setup workflows — many gotchas
- Running Claude Code on sprites — requires PTY trick
- Troubleshooting connectivity or auth issues

**Safe without skill:**
- `sprite list`, `sprite checkpoint list` — simple read operations
- `sprite console` — interactive, you'll see what happens

## When NOT to Use

- Local development (just use terminal directly)
- Anthropic's Claude Code Web (different product, ephemeral VMs)
- Server administration on non-sprite machines (use server-checkup)

## Quick Reference

| Command | What it does |
|---------|--------------|
| `sprite list` | List all sprites |
| `sprite create <name>` | Create new sprite |
| `sprite use <name>` | Activate sprite for current directory |
| `sprite exec <cmd>` | Run command (uses active sprite) |
| `sprite exec -s <name> <cmd>` | Run command on specific sprite |
| `sprite console` | Interactive shell |
| `sprite checkpoint create` | Snapshot current state |
| `sprite checkpoint list` | List checkpoints |
| `sprite restore <id>` | Restore to checkpoint |
| `sprite proxy <port>` | Forward local port to sprite |
| `sprite url` | Show sprite's public URL |
| `sprite url update --auth public` | Make URL publicly accessible |
| `sprite destroy` | Delete current sprite |
| `sprite upgrade` | Update CLI to latest version |

## What Sprites Are

- Persistent Ubuntu VMs with auto-hibernate (no charge when sleeping)
- Wake instantly on any command
- Checkpoints capture full filesystem state (milliseconds, copy-on-write)
- Pre-installed: Claude Code, gh, Python, Node.js, Go

**Sprite States:**
- `cold` — Hibernated, no resources consumed
- `warm` — Waking up
- `running` — Active, executing commands

## First-Time Setup (per sprite)

Fresh sprites have `gh` but not authenticated:

```bash
# 1. Authenticate with GitHub (one-time, interactive)
gh auth login

# 2. Clone config (HTTPS works with gh auth)
rm -rf ~/.claude
git clone --recurse-submodules https://github.com/spm1001/claude-config.git ~/.claude

# 3. Run setup
cd ~/.claude && ./scripts/setup-machine.sh

# 4. Set up shared memory (optional but recommended)
# See "Memory Integration" section below

# 5. Checkpoint so you don't repeat this
sprite checkpoint create
```

## Common Workflows

### Bootstrap a new sprite
```bash
sprite create my-sprite
sprite use my-sprite                    # Activate for current directory
sprite exec gh auth login               # Follow browser auth flow
sprite exec bash -c "rm -rf ~/.claude && git clone --recurse-submodules https://github.com/spm1001/claude-config.git ~/.claude && ~/.claude/scripts/setup-machine.sh"
sprite checkpoint create
```

### Run commands on sprite
```bash
# Single command (after `sprite use`)
sprite exec ls -la

# With explicit sprite
sprite exec -s my-sprite ls -la

# Multi-command (use bash -c)
sprite exec bash -c "cd ~/Repos/foo && git pull && npm test"
```

### Access a web server on sprite
```bash
# Start server on sprite
sprite exec -s my-sprite bash -c "cd ~/app && npm start"

# In another terminal, proxy the port
sprite proxy 3000

# Now access http://localhost:3000 locally
```

### Make sprite publicly accessible
```bash
sprite url                      # Show current URL
sprite url update --auth public # Make public (no auth required)
sprite url update --auth sprite # Restore auth requirement
```

### Sync config changes
```bash
sprite exec bash -c "cd ~/.claude && git pull origin main"
```

## Exec Options

The exec API supports several parameters:

| Parameter | Description |
|-----------|-------------|
| `tty` | Enable TTY mode (interactive, detachable) |
| `env` | Set environment variables (`KEY=VALUE`) |
| `max_run_after_disconnect` | How long command runs after disconnect |
| `rows`, `cols` | Terminal dimensions |

TTY sessions persist after disconnect — start a dev server, disconnect, reconnect later.

## Network Policy

Sprites support DNS-based outbound filtering:

```bash
# Via API - restrict to specific domains
sprite api POST /v1/sprites/{name}/policy/network \
  -d '{"rules": [{"domain": "github.com", "action": "allow"}]}'
```

Use for security-sensitive environments where you need to restrict network access.

## SDKs

Programmatic access beyond the CLI:

| Language | Package | Install |
|----------|---------|---------|
| Python | `sprites-py` | `pip install sprites-py` |
| Node.js | `@fly/sprites` | `npm install @fly/sprites` |
| Go | `sprites-go` | `go get github.com/superfly/sprites-go` |
| Elixir | `sprites-ex` | `{:sprites, github: "superfly/sprites-ex"}` |

**Python example:**
```python
import os
from sprites import SpritesClient

client = SpritesClient(os.environ["SPRITE_TOKEN"])
output = client.sprite("my-sprite").command("ls", "-la").output()
print(output.decode())
```

**API Base:** `https://api.sprites.dev/v1/` with `Authorization: Bearer $SPRITES_TOKEN`

## Running Claude on Sprites (Critical)

**Problem:** `sprite exec` + `claude -p` produces no output. Claude needs a TTY.

**Solution:** Use the `script` command to create a pseudo-TTY:

```bash
# This captures output correctly
sprite exec -s my-sprite bash -c 'script -q /dev/null -c "claude -p \"your prompt here\"" 2>&1'

# Example: Ask sprite-Claude to list skills
sprite exec -s my-sprite bash -c 'script -q /dev/null -c "claude -p \"What skills do I have?\"" 2>&1'
```

**Why this works:** The `script` command creates a PTY (pseudo-terminal). Claude's `-p` mode requires a TTY for output — without it, the command exits successfully but produces nothing.

**For interactive sessions:** Use `sprite console` instead, then run `claude` normally inside.

**Multi-turn conversations:** Use `--continue` flag:
```bash
# First message
sprite exec -s my-sprite bash -c 'script -q /dev/null -c "claude -p \"Start a project\"" 2>&1'

# Continue conversation
sprite exec -s my-sprite bash -c 'script -q /dev/null -c "claude -p \"Add tests\" --continue" 2>&1'
```

## Empirical Learnings

Things discovered through use that may not be obvious:

| Finding | Implication |
|---------|-------------|
| Fresh sprites have `gh` but not authenticated | Need `gh auth login` before cloning private repos |
| Checkpoints are per-sprite | Can't restore sprite-A's checkpoint to sprite-B |
| HTTPS + gh credential helper works | Use HTTPS URLs, not SSH |
| Auth survives checkpoints | Checkpoint after `gh auth login` to preserve |
| `sprite use` avoids `-s` flag | Set once per directory, simpler commands |
| `claude -p` needs PTY for output | Use `script -q /dev/null -c "..."` wrapper |
| Sprite Claude ≠ local Claude | Fresh sprite has no skills/config until setup |

## Memory Integration

Sprites can access shared memory via `claude-mem` — a searchable index of past sessions, handoffs, and beads. Memory syncs through Turso (SQLite edge database), so searches on a sprite pull context from all machines.

**The memory follows the human, not the machine.**

### Setup on Sprite

```bash
# 1. Clone and install
git clone https://github.com/spm1001/claude-mem.git ~/Repos/claude-mem
cd ~/Repos/claude-mem && uv sync

# 2. Set credentials (add to ~/.bashrc for persistence)
export TURSO_CLAUDE_MEMORY_URL="libsql://claude-memory-spm1001.aws-eu-west-1.turso.io"
export TURSO_CLAUDE_MEMORY_TOKEN="<token-from-keychain-on-mac>"

# 3. Test
cd ~/Repos/claude-mem && uv run mem status
```

### What Works on Sprites

| Command | Purpose |
|---------|---------|
| `mem search "query"` | FTS5 search across all sources |
| `mem status` | Database stats |
| `mem drill <id>` | Deep dive into specific source |
| `mem recent` | Recently indexed sources |

### What NOT to Do on Sprites

- `mem scan` — source files live on Mac, not sprite
- `mem backfill` — requires API key and source data
- `mem migrate-turso` — already migrated

### Value on Sprites

- Search memory from remote dev environments
- Access learnings from Mac sessions while working remotely
- Resume work with full handoff context on any machine

## Docs

- [sprites.dev/api](https://sprites.dev/api) — Official API documentation (comprehensive)
- [sprites.dev](https://sprites.dev/) — Main site, features overview
- [community.fly.io](https://community.fly.io/) — Fly.io forum (search "sprites")
- CLI has good `--help`: `sprite --help`, `sprite checkpoint --help`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Permission denied (publickey)" | Use HTTPS not SSH, or run `gh auth login` |
| "could not read Username" | Run `gh auth login` to configure credential helper |
| Checkpoint not found | Checkpoints are per-sprite, can't cross-restore |
| Command not found in exec | Pass full command to bash: `sprite exec bash -c "..."` |
| Port not accessible | Use `sprite proxy <port>` to tunnel locally |
| `claude -p` returns empty output | Use PTY wrapper: `script -q /dev/null -c "claude -p ..."` |
| Sprite-Claude missing skills | Run setup on sprite — it's a fresh environment |

## Anti-Patterns

| Don't | Do Instead | Why |
|-------|------------|-----|
| Use SSH URLs for git clone | Use HTTPS URLs | gh credential helper works with HTTPS |
| Try to restore checkpoint across sprites | Each sprite has its own checkpoints | Checkpoints are per-sprite storage |
| Run `sprite exec "multi word command"` | Use `sprite exec bash -c "..."` | exec needs command as separate args |
| Skip `gh auth login` on fresh sprite | Always auth first | Private repos won't clone without it |
| Manually specify `-s` every time | Use `sprite use <name>` first | Sets default for directory |
| Run `sprite exec claude -p "..."` directly | Wrap with `script -q /dev/null -c "..."` | Claude needs TTY for output |
| Assume sprite-Claude has your config | Set up skills/config on sprite first | Sprites start fresh |
