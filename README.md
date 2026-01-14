# claude-suite

Behavioral skills for Claude Code. Point a fresh Claude here and say "help me install."

## What's Included

**Session Lifecycle** — Structured handoffs between sessions
- `/open` — Start session with context from previous work
- `/ground` — Mid-session checkpoint when things feel off
- `/close` — End session with reflection and handoff

**Issue Tracking** — Multi-session work with dependencies
- `beads` — Track work across sessions (requires [bd CLI](https://github.com/beads-dev/bd))

**Utilities**
- `diagram` — Create diagrams with iterative render-and-check
- `screenshot` — Capture screen to verify changes
- `filing` — Organize files with PARA-influenced structure
- `github-cleanup` — Audit and clean GitHub repos
- `picture` — Generate images with AI
- `server-checkup` — Linux server management
- `skill-check` — Validate skills before sharing
- `sprite` — Manage Sprites.dev remote VMs
- `dbt` — DBT skills practice

## Quick Install

```bash
# Clone this repo
gh repo clone spm1001/claude-suite ~/Repos/claude-suite

# Ask Claude to set up
# In Claude Code, say: "help me install from ~/Repos/claude-suite"
```

Or manually:
```bash
# Create directories
mkdir -p ~/.claude/skills

# Symlink all skills
for skill in ~/Repos/claude-suite/skills/*/; do
    ln -sf "$skill" ~/.claude/skills/
done

# Restart Claude to load new skills
```

## Optional Tool Repos

These provide CLI/MCP integrations with co-located skills:

| Repo | What it adds |
|------|--------------|
| [todoist-gtd](https://github.com/spm1001/todoist-gtd) | GTD-flavored Todoist integration |
| [claude-mem](https://github.com/spm1001/claude-mem) | Search past Claude sessions |

## Architecture

This repo contains **behavioral skills** — patterns, workflows, and knowledge that don't require their own CLI.

**Tool skills** (CLI + skill together) live in their own repos:
- CLI and skill evolve together for better ergonomics
- Install separately as needed

## Contributing

Skills welcome. Run `/skill-check` before submitting to validate structure.
