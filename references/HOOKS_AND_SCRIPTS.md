# Hooks and Scripts Architecture

A complete map of what fires when, who owns it, and how it's wired.

Last audited: 2026-02-08

---

## Quick Reference: What Fires When

### SessionStart

```
settings.json SessionStart (matcher: "")
  |
  +--> session-start.sh              [no guard] [owner: trousse]
         |
         +--> open-context.sh         latest handoff + arc (via jq) -> stdout
         +--> check .close-checkpoint incomplete /close warning
         +--> update-all.sh           background (nohup &)
               |
               +-- QUICK (always): check-symlinks, submodules
               +-- HEAVY (daily): brew, npm, claude update, MCP deps
```

**Removed in Feb 2026 cleanup:** sync-config.sh pull, quick_health_check(), sync-skill-permissions.sh, timing telemetry. These were per-session overhead for rare events. Health checks moved to claude-doctor.sh (on-demand).

### UserPromptSubmit

```
settings.json UserPromptSubmit (matcher: "")
  |
  +--> arc-tactical.sh               [no guard] [owner: trousse]
         reads .arc/items.jsonl via jq (~3ms)
         injects current arc step into every prompt
```

### PostToolUse

```
settings.json PostToolUse
  |
  +--> [WebFetch matcher] inline     warns: AI summary, not raw content
  +--> [Bash matcher] inline         warns: detached HEAD detected
```

### SessionEnd

```
settings.json SessionEnd (matcher: "")
  |
  +--> session-end.sh                [env var guard] [owner: trousse]
  |      |
  |      +--> auto-handoff.sh        synchronous: writes minimal handoff if /close didn't
  |      |
  |      +--> daemonized background:
  |             garde process (index session transcript)
  |             garde scan (handoffs + beads)
  |             garde backfill --limit 10 (Meeting Notes)
  |
  +--> sync-config.sh push           [owner: claude-config]
         git add/commit/push ~/.claude
```

---

## Design Principle: Fast and Graceful

**Hooks should be cheap enough that accidental firing is harmless.** No guards needed if the cost is negligible.

| Hook | Time | Why it's fast |
|------|------|--------------|
| session-start.sh | ~106ms | jq reads items.jsonl instead of 3x Python arc CLI |
| arc-tactical.sh | ~8ms | jq reads items.jsonl instead of Python arc CLI |
| session-end.sh | ~5ms | Just launches a daemon, actual work is backgrounded |

**Exception: session-end.sh** keeps an env var guard (`GARDE_SUBAGENT`, `MEM_SUBAGENT`, `CLAUDE_SUBAGENT`) because its side effect (garde process) spawns `claude -p` subagents — recursive fork bomb risk. The guard isn't about speed, it's about preventing recursion.

---

## Ownership Map

### trousse (this repo)

Symlinked by `install.sh` to `~/.claude/`.

| File | Type | Symlinked to |
|------|------|-------------|
| `hooks/session-start.sh` | Hook | `~/.claude/hooks/session-start.sh` |
| `hooks/session-end.sh` | Hook | `~/.claude/hooks/session-end.sh` |
| `hooks/arc-tactical.sh` | Hook | `~/.claude/hooks/arc-tactical.sh` |
| `scripts/open-context.sh` | Script | `~/.claude/scripts/open-context.sh` |
| `scripts/arc-read.sh` | Script | `~/.claude/scripts/arc-read.sh` |
| `scripts/close-context.sh` | Script | `~/.claude/scripts/close-context.sh` |
| `scripts/check-home.sh` | Script | `~/.claude/scripts/check-home.sh` |
| `scripts/check-symlinks.sh` | Script | `~/.claude/scripts/check-symlinks.sh` |
| `scripts/auto-handoff.sh` | Script | `~/.claude/scripts/auto-handoff.sh` |
| `scripts/claude-doctor.sh` | Script | `~/.claude/scripts/claude-doctor.sh` |

### claude-config (~/.claude, standalone)

Not symlinked — these live directly in `~/.claude/`.

| File | Type | Location |
|------|------|----------|
| `scripts/sync-config.sh` | Script | `~/.claude/scripts/sync-config.sh` |
| `scripts/update-all.sh` | Script | `~/.claude/scripts/update-all.sh` (scaffolded from `scripts/update-all.template.sh`) |
| `scripts/rescue-handoffs.sh` | Script | `~/.claude/scripts/rescue-handoffs.sh` |
| `scripts/todoist-mcp.sh` | Script | `~/.claude/scripts/todoist-mcp.sh` |
| `scripts/todoist` | Script | `~/.claude/scripts/todoist` |
| `scripts/chrome-log` | Script | `~/.claude/scripts/chrome-log` |

### install.sh Registration

`install.sh` registers **all** hook events:

| Event | Hook | Registered by install.sh |
|-------|------|------------------------|
| SessionStart | session-start.sh | Yes |
| SessionEnd | session-end.sh | Yes |
| UserPromptSubmit | arc-tactical.sh | Yes |
| PostToolUse (WebFetch) | Inline | Yes |
| PostToolUse (Bash) | Inline | Yes |

---

## arc-read.sh: jq-Based Arc Reads

Hooks and scripts that read arc state use `arc-read.sh` instead of the Python arc CLI. This avoids ~30ms Python startup per invocation.

```bash
arc-read.sh list          # Full hierarchy (outcomes + actions)
arc-read.sh ready         # Ready items only (open, not waiting)
arc-read.sh current       # Active tactical steps
```

Reads `.arc/items.jsonl` directly with jq. Falls back to arc CLI if arc-read.sh isn't installed.

**Principle:** Python for writes (validation, ID generation, tactical management). jq for reads (hooks, scripts, briefing). The JSONL format is the interface between them.

---

## Script Details

### Session Lifecycle

| Script | Called by | Purpose |
|--------|----------|---------|
| `open-context.sh` | session-start.sh | Reads latest handoff + arc state (via jq). Produces stdout briefing. Writes arc.txt to disk for /open. |
| `close-context.sh` | /close skill | Gathers close-time context: git state, arc state, location check. Structured `=== SECTION ===` output |
| `check-home.sh` | /close skill | Detects CWD drift from session start |

### Health and Diagnostics

| Script | Called by | Purpose |
|--------|----------|---------|
| `check-symlinks.sh` | update-all.sh | Verifies critical symlinks intact |
| `auto-handoff.sh` | session-end.sh | Writes minimal handoff if /close didn't run. Reads git log + arc state. |
| `claude-doctor.sh` | Manual | Comprehensive health check: symlinks, tools, config, skills, memory, MCP |

### Infrastructure

| Script | Called by | Purpose |
|--------|----------|---------|
| `sync-config.sh` | settings.json (push at end only) | Git sync for `~/.claude` repo |
| `update-all.sh` | session-start.sh (background) | Two-tier updater: quick (always) + heavy (daily) |

---

## Context Encoding

The path encoding convention used for per-project directories:

```bash
encoded=$(pwd -P | sed 's/[^a-zA-Z0-9-]/-/g')
# /Users/modha/Repos/trousse -> -Users-modha-Repos-trousse
```

Used in:
- `~/.claude/.session-context/<encoded>/` — per-project context cache (regeneratable)
- `~/.claude/handoffs/<encoded>/` — per-project handoff archive (permanent)

**Canonical implementation:** `open-context.sh:11`

**Contract:** Aboyeur depends on this encoding. See `references/HANDOFF-CONTRACT.md`.

---

## Known Issues

1. **update-all.sh has blind spots.** The heavy tier updates brew, npm, and claude CLI, but doesn't update high-velocity tools like `gh` and `gcloud` CLI.

2. **CLAUDE_SUBAGENT env var is forward-looking.** session-end.sh checks for it, but nothing currently sets it. Intended for aboyeur or future spawners.

3. **arc-read.sh jq queries assume arc's JSONL shape.** If arc evolves its schema, the jq queries may diverge from `arc list` output silently. Testing against arc CLI output would catch this.
