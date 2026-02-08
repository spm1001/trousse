# claude-suite

A toolkit for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic's CLI coding assistant) that gives it session memory and specialized capabilities.

## The Problem

Claude Code is stateless. Every time you start a session, Claude has no memory of what you worked on before — what was done, what's next, what to watch out for. If you're using Claude Code daily, you spend the first few minutes of every session re-explaining context.

## What This Does

claude-suite solves this with two things:

**A session protocol** — shell hooks that fire automatically when Claude Code starts and stops. At startup, Claude sees a briefing: what you were working on, what the previous session accomplished, and what's ready to pick up. At close, it writes a handoff for the next session. The gap between sessions becomes a baton pass, not a cold start.

**A skill drawer** — a collection of slash commands (`/diagram`, `/review`, `/filing`, etc.) that teach Claude Code specialized workflows. Skills are SKILL.md files — structured instructions that Claude reads and follows. They're installed as symlinks into `~/.claude/skills/`.

## Quick Start

```bash
git clone https://github.com/spm1001/claude-suite ~/Repos/claude-suite
cd ~/Repos/claude-suite
./install.sh
```

Then restart Claude Code (`/exit` → `claude`).

**Verify:** `./install.sh --verify`

**Dependencies:** `jq` (required — `brew install jq` on Mac, `apt install jq` on Linux).

## What You Get

### Session Lifecycle (automatic after install)

| What | When | How |
|------|------|-----|
| **Startup briefing** | Every session start | Hook runs `open-context.sh`, shows outcomes and last session summary |
| **Tactical reminders** | Every prompt | Hook shows current work step so Claude doesn't drift |
| `/open` | On demand | Re-orient mid-session or after changing directories |
| `/close` | End of session | Reflect on work done, write handoff for next session |

### Skills (slash commands)

| Skill | What it does |
|-------|--------------|
| `/titans` (or `/review`) | Three-lens code review: hindsight, craft, foresight |
| `/diagram` | Create diagrams with iterative render-and-check |
| `/screenshot` | Capture screen to verify changes |
| `/filing` | Organize files using PARA method |
| `/picture` | Generate images with AI |
| `/server-checkup` | Linux server audit and management |
| `/github-cleanup` | Audit repos, find stale forks and secrets |
| `/sprite` | Manage Sprites.dev remote VMs |
| `/setup` | Install claude-suite on a new machine |
| `/skill-forge` | Build and validate new skills |
| `/skill-check` | Quality gate for skill sharing |

### Companion Skills (loaded by other skills, not invoked directly)

| Skill | Loaded by | Purpose |
|-------|-----------|---------|
| `arc` | `/open` | Work tracking across sessions (outcomes + actions) |
| `beads` | `/open` | Legacy work tracker (deprecated, use arc for new projects) |

## How It Works

### Directory Structure

```
claude-suite/
├── hooks/                  # Shell scripts that fire on Claude Code events
│   ├── session-start.sh    #   → runs open-context.sh at session start
│   ├── session-end.sh      #   → cleanup at session end
│   └── arc-tactical.sh     #   → injects current work step into every prompt
├── scripts/                # Utility scripts called by hooks and skills
│   ├── open-context.sh     #   → generates session briefing
│   ├── close-context.sh    #   → generates session handoff
│   ├── arc-read.sh         #   → fast jq reads from arc's data file
│   ├── claude-doctor.sh    #   → diagnose broken symlinks and config
│   ├── check-home.sh       #   → detect home directory issues
│   └── check-symlinks.sh   #   → verify symlink integrity
├── skills/                 # Skill definitions (SKILL.md files)
│   ├── open/               #   → session orientation
│   ├── close/              #   → session handoff
│   ├── titans/             #   → three-lens code review
│   ├── diagram/            #   → diagramming workflow
│   └── ...                 #   → (16 skills total)
├── references/             # Architecture docs (not loaded automatically)
│   ├── HANDOFF-CONTRACT.md #   → handoff format specification
│   ├── HOOKS_AND_SCRIPTS.md#   → hook architecture audit
│   └── ERROR_PATTERNS.md   #   → troubleshooting guide
├── tests/                  # pytest suite
├── install.sh              # Installer (creates symlinks, registers hooks)
└── CLAUDE.md               # Instructions Claude reads when working in this repo
```

### Installation Mechanics

`install.sh` creates symlinks — it doesn't copy files:
- Each `skills/<name>/` directory gets symlinked to `~/.claude/skills/<name>`
- Each `scripts/<name>.sh` gets symlinked to `~/.claude/scripts/<name>.sh`
- Each `hooks/<name>.sh` gets symlinked to `~/.claude/hooks/<name>.sh`
- Hook events are registered in `~/.claude/settings.json`

This means `git pull` updates everything — symlinks point to the repo, so changes take effect immediately (skills hot-reload; hooks and scripts are re-read each invocation).

### The Handoff Protocol

When a session ends, `/close` writes a handoff file to `~/.claude/handoffs/<project>/`. The next session's startup hook reads it and includes the summary in Claude's briefing. The handoff contains:

- **Done** — what was accomplished
- **Next** — suggested next steps
- **Gotchas** — things to watch out for

The full specification is in `references/HANDOFF-CONTRACT.md`.

## Optional Companion Tools

These are separate repos that add their own skills:

| Repo | What it adds |
|------|--------------|
| [todoist-gtd](https://github.com/spm1001/todoist-gtd) | GTD-flavored Todoist integration |
| [claude-mem](https://github.com/spm1001/claude-mem) | Search past Claude sessions |
| [arc](https://github.com/spm1001/arc) | Work tracker CLI (outcomes + actions) |

## Troubleshooting

**Skills don't appear?** Restart required after first install. Run `/exit` then `claude`.

**Hooks not firing?** Run `./install.sh --verify` to check symlinks. Run `~/.claude/scripts/claude-doctor.sh` for diagnostics.

**Need more help?** See `references/ERROR_PATTERNS.md` for common issues and fixes.

## Updating

```bash
cd ~/Repos/claude-suite && git pull
# Symlinks mean changes take effect immediately
```

## Uninstalling

```bash
./install.sh --uninstall
```

Removes symlinks and hook registrations. Does not delete handoff history.
