# trousse

## Status

**Robustness:** Stable — used daily
**Works with:** Claude Code (plugin or manual install)
**Requires:** Claude Code CLI 2.0+

A skill drawer for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — slash commands that teach Claude specialized workflows.

## What This Does

Trousse provides 17 skills as SKILL.md files. Each one is a structured instruction set Claude reads and follows when you invoke the slash command.

Session lifecycle (startup briefings, handoffs, tactical tracking) is handled by [bon](https://github.com/spm1001/bon), not trousse. Trousse is purely skills.

## Quick Start

### Via plugin (recommended)

```
/plugin
# → batterie-de-savoir → trousse
```

### Via manual install

```bash
git clone https://github.com/spm1001/trousse ~/Repos/trousse
cd ~/Repos/trousse
./install.sh
```

Then restart Claude Code (`/exit` → `claude`).

**Verify:** `./install.sh --verify`

## Skills

| Skill | What it does |
|-------|--------------|
| `/titans` (or `/review`) | Three-lens code review: hindsight, craft, foresight |
| `/diagram` | Create diagrams with iterative render-and-check |
| `/screenshot` | Capture screen to verify changes |
| `/filing` | Organize files using PARA method |
| `/picture` | Generate images with Google Imagen |
| `/server-checkup` | Linux server audit and management |
| `/github-cleanup` | Audit repos, find stale forks and deps |
| `/sprite` | Manage Sprites.dev remote VMs |
| `/skill-forge` | Build and validate new skills |
| `/ia-presenter` | Write iA Presenter slide decks |
| `/google-devdocs` | Look up Google developer documentation |
| `/mandoline` | Transform raw data into clean BigQuery tables |
| `/toise` | Architecture review (8 checks, letter grades) |
| `/claude-survey` | Survey naive Claude instances for design research |
| `/neutral-claude` | Spawn context-isolated Claude instances |
| `/amp-close` | End-of-session ritual for Amp (CC uses bon's /close) |

## Directory Structure

```
trousse/
├── skills/                 # 17 skill definitions (SKILL.md files)
│   ├── titans/             #   → three-lens code review
│   ├── diagram/            #   → diagramming workflow
│   ├── skill-forge/        #   → skill development + validation
│   └── ...
├── scripts/                # Utility scripts used by skills
│   ├── neutral-claude.sh   #   → context isolation for spawned Claudes
│   └── bon-survey.py       #   → survey automation for claude-survey skill
├── hooks/
│   └── hooks.json          #   → empty (trousse registers no hooks)
├── references/             # Architecture docs (not loaded automatically)
│   └── ERROR_PATTERNS.md   #   → troubleshooting guide
├── tests/                  # pytest suite
├── install.sh              # Manual installer (symlinks skills + scripts)
└── CLAUDE.md               # Instructions Claude reads when working in this repo
```

## Updating

```bash
cd ~/Repos/trousse && git pull
# Symlinks mean changes take effect immediately
```

## Uninstalling

```bash
./install.sh --uninstall
```

Removes symlinks. Does not delete handoff history.

## The Kitchen

Trousse is part of [Batterie de Savoir](https://spm1001.github.io/batterie-de-savoir/) — a suite of tools for AI-assisted knowledge work.
