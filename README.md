# trousse

## Status

**Robustness:** Stable — used daily
**Works with:** Claude Code (plugin or manual install)
**Requires:** Claude Code CLI 2.0+

A skill drawer for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — slash commands that teach Claude specialized workflows.

## What This Does

Trousse provides 18 skills as SKILL.md files. Each one is a structured instruction set Claude reads and follows when you invoke the slash command.

Session lifecycle (startup briefings, handoffs, tactical tracking) is handled by [bon](https://github.com/spm1001/bon), not trousse. Trousse is purely skills.

## Quick Start

### Via plugin (recommended)

```
claude plugin marketplace add spm1001/batterie
/plugin install trousse@batterie
```

### Via manual clone

```bash
git clone https://github.com/spm1001/trousse ~/repos/spm1001/trousse
```

The plugin system discovers skills from `skills/*/SKILL.md` automatically.

## Skills

| Skill | What it does |
|-------|--------------|
| `/titans` (or `/review`) | Three-lens code review: hindsight, craft, foresight |
| `/skill-forge` | Build and validate new skills |
| `/ardoise` | Context-isolated Claude (blank-slate testing) |
| `/deglacer` | CC session JSONL parsing — schema reference + CLI |

## Directory Structure

```
trousse/
├── skills/                 # 18 skill definitions (SKILL.md files)
│   ├── titans/             #   → three-lens code review
│   ├── diagram/            #   → diagramming workflow
│   ├── skill-forge/        #   → skill development + validation
│   └── ...
├── scripts/                # Utility scripts used by skills
│   ├── ardoise.sh          #   → context isolation for spawned Claudes
│   └── bon-survey.py       #   → survey automation for claude-survey skill
├── hooks/
│   └── hooks.json          #   → empty (trousse registers no hooks)
├── references/             # Architecture docs (not loaded automatically)
│   └── ERROR_PATTERNS.md   #   → troubleshooting guide
├── tests/                  # pytest suite
└── CLAUDE.md               # Instructions Claude reads when working in this repo
```

## Updating

```bash
cd ~/repos/spm1001/trousse && git pull
# Plugin cache refreshes on next session start
```

## Uninstalling

Use `/plugin uninstall trousse` to remove the plugin.

## The Kitchen

Trousse is part of [Batterie de Savoir](https://spm1001.github.io/batterie-de-savoir/) — a suite of tools for AI-assisted knowledge work.
