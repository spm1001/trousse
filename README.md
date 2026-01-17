# claude-suite

Behavioral skills for Claude Code. One command to install, restart to activate.

## Install

```bash
git clone https://github.com/spm1001/claude-suite ~/Repos/claude-suite
cd ~/Repos/claude-suite
./install.sh
```

Then restart Claude Code (`/exit` → `claude`).

## What You Get

**Session lifecycle** — runs automatically after install:
- On startup: Time, previous handoffs, and ready work shown
- `/open` — Resume context from previous session
- `/close` — Create handoff for next session

**Issue tracking** — for work spanning multiple sessions:
- `beads` — Track work with dependencies (requires [bd CLI](https://github.com/beads-dev/bd))

**Utilities:**
- `/diagram` — Create diagrams with iterative render-and-check
- `/screenshot` — Capture screen to verify changes
- `/filing` — Organize files (PARA method)
- `/picture` — Generate images with AI
- `/server-checkup` — Linux server management
- `/github-cleanup` — Audit repos, find stale forks
- `/sprite` — Manage Sprites.dev remote VMs

## Verify Installation

```bash
./install.sh --verify
```

## Optional Tools

These provide CLI integrations with their own skills:

| Repo | What it adds |
|------|--------------|
| [todoist-gtd](https://github.com/spm1001/todoist-gtd) | GTD-flavored Todoist integration |
| [claude-mem](https://github.com/spm1001/claude-mem) | Search past Claude sessions |

## Troubleshooting

**Skills don't appear in Claude?**
Restart required. Run `/exit` then start `claude` again.

**Hooks not firing?**
Check `~/.claude/settings.json` has a `hooks` section. Run `./install.sh --verify`.

**Missing dependencies?**
Install.sh checks for `jq`. On Mac: `brew install jq`. On Linux: `apt install jq`.

## Updating

```bash
cd ~/Repos/claude-suite
git pull
# Symlinks automatically point to updated content
```

## Uninstall

```bash
./install.sh --uninstall
```
