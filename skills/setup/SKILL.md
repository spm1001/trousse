---
name: setup
description: >
  Install behavioral skills from claude-suite. Creates symlinks for session lifecycle,
  utilities, and optionally offers tool repos (todoist-gtd, claude-mem).
  Triggers on 'help me set up', 'install skills', '/setup'.
---

# Setup

Install Claude behavioral skills with one command.

## Quick Start

```
/setup           # Interactive — installs all behavioral skills, offers tool repos
/setup --verify  # Check existing setup
```

## What Gets Installed

**Behavioral skills** (all installed together):
- Session lifecycle: `/open`, `/close`
- Issue tracking: `beads`
- Utilities: diagram, screenshot, filing, github-cleanup, picture, server-checkup, skill-check, sprite, dbt

**Optional tool repos** (offered after core install):
- `todoist-gtd` — GTD-flavored Todoist integration
- `claude-mem` — Searchable memory across sessions

## Workflow

### Phase 1: Check Prerequisites

```bash
# Check for required tools
command -v gh &>/dev/null || echo "MISSING: GitHub CLI (brew install gh)"
command -v uv &>/dev/null || echo "MISSING: uv (brew install uv)"

# Create directories
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/scripts
mkdir -p ~/.claude/hooks
```

### Phase 2: Clone and Symlink

```bash
# Clone claude-suite if not present
if [ ! -d ~/Repos/claude-suite ]; then
    gh repo clone spm1001/claude-suite ~/Repos/claude-suite
fi

SUITE="$HOME/Repos/claude-suite"

# Symlink all skills
for skill in "$SUITE/skills/"*/; do
    name=$(basename "$skill")
    ln -sf "$skill" ~/.claude/skills/"$name"
done
```

### Phase 3: Symlink Scripts and Hooks

```bash
# Scripts (if present)
if [ -d "$SUITE/scripts" ]; then
    for script in "$SUITE/scripts/"*.sh; do
        [ -f "$script" ] && ln -sf "$script" ~/.claude/scripts/
    done
fi

# Hooks (if present)
if [ -d "$SUITE/hooks" ]; then
    for hook in "$SUITE/hooks/"*.sh; do
        [ -f "$hook" ] && ln -sf "$hook" ~/.claude/hooks/
    done
fi
```

### Phase 4: Offer Tool Repos

Use AskUserQuestion:

```
Core skills installed. Want to add tool integrations?

[ ] todoist-gtd — GTD task management with Todoist
[ ] claude-mem — Search past sessions
```

**If todoist-gtd selected:**
```bash
gh repo clone spm1001/todoist-gtd ~/Repos/todoist-gtd
ln -sf ~/Repos/todoist-gtd/skills/todoist-gtd ~/.claude/skills/todoist-gtd

# Run OAuth
~/.claude/.venv/bin/python ~/Repos/todoist-gtd/scripts/todoist.py auth
```

**If claude-mem selected:**
```bash
gh repo clone spm1001/claude-mem ~/Repos/claude-mem
cd ~/Repos/claude-mem && uv sync
ln -sf ~/Repos/claude-mem/skill ~/.claude/skills/mem

# Initial scan
cd ~/Repos/claude-mem && uv run mem scan
```

### Phase 5: Verify

```bash
# List installed skills
ls ~/.claude/skills/

# Test key skills
ls -la ~/.claude/skills/session-opening
ls -la ~/.claude/skills/beads
```

Tell user to restart Claude (`/exit` then `claude`) to load new skills.

## Verification

| Check | Command | Expected |
|-------|---------|----------|
| Skills directory | `ls ~/.claude/skills/` | 13+ skill symlinks |
| Session skills | `ls -la ~/.claude/skills/session-opening` | Points to claude-suite |
| Beads | `bd --version` | Shows version (install separately if missing) |

## Updating

```bash
cd ~/Repos/claude-suite && git pull
# Symlinks automatically point to updated content
```
