# Changelog

## [0.4.0] - 2026-03-20

Maturity realignment and versioning fix.

### Changed
- Version reset from 1.1.1 to 0.4.0 — 1.1.1 was an accidental over-increment, not reflective of stability. Trousse is a skills container; skills churn. 0.4.x is honest.
- Switched to hatchling dynamic versioning: `plugin.json` is now the single source of truth; pyproject.toml no longer has a hardcoded version.
- Note: existing installs at 1.1.1 will not auto-update (batterie-update only fires on version increase). Reinstall from scratch to get 0.4.0.

## [0.2.0] - 2026-03-18

Batterie-wide consistency pass: docs consolidation, CI, versioning.

### Added
- Toise skill: architecture review for Claude-maintained software
- Claude-survey skill for polling model instincts
- Neutral-claude: context-isolated `claude -p` via env scrub
- Mandoline skill (moved from `~/.claude/skills/`)

### Changed
- Migrated scripts from jq to python3 (remove system dependency)
- Removed hooks declaration (auto-discovered by convention)

### Removed
- Open, close, audit skills (moved to bon repo)
- Scripts migrated to bon and garde-manger
- Stale bon ownership claims stripped

## 2026-03-05–10 — New Skills & Survey Tooling

### Added
- Claude-survey skill with neutral-claude isolation pattern
- Universal design rules integrated into diagram skill from Anthropic PPT analysis
- Mandoline: net rows as standard for pre-aggregated Likert tables
- Understanding documents wired into open/close lifecycle
- Negative triggers added to skill-forge CSO patterns

## 2026-02-27 — Plugin System

### Added
- Plugin manifest for Claude Code plugin system
- `hooks.json` for plugin system hook discovery
- Marketplace install note in install.sh

## 2026-02-22 — Audit Skill

### Added
- Audit skill with `audit_survey.py`, SKILL.md, and verification patterns
- Amp-close: consolidated garde extraction into send-amp-extraction.sh

## 2026-02-20–21 — Close Skill Overhaul

### Added
- Integration tests for Amp handoff parsing in open-context.sh
- `send-amp-extraction.sh` for extraction automation

### Changed
- Overhauled /close skill: collapse Orient, invert Decide, bon quality gate
- Wired `stage-extraction.sh` to eliminate session ID naming errors

### Fixed
- Duplicate hook entries: replace by event+matcher, not command string
- Timeout guards on open-context repo sync

## 2026-02-15–16 — Amp Support & Diagram

### Added
- Amp-close skill: end-of-session ritual for Amp threads
- Cross-harness handoffs + Oracle Orient reflection
- Google-devdocs skill
- Diagram skill: strengthened rsvg-convert prerequisite

### Changed
- Arc to Bon rename: beads scrub + URL updates

## 2026-02-13 — Kitchen Rename

### Changed
- Renamed claude-suite to trousse, claude-mem to garde-manger
- Cross-platform fixes for kube brain migration
- Removed deprecated skills (beads, skill-check)
- Hardened path encoding across all scripts

## 2026-02-08–10 — Session Performance

### Changed
- Session hooks optimized from 1.3s to 106ms
- Rewrote README and CLAUDE.md for newcomers
- Guard all hooks against subagent (`claude -p`) invocations
- Matched Claude Code's actual path encoding for session ID discovery

## 2026-02-01–05 — Skill Forge & Filing

### Added
- Skill-forge: unified skill development toolkit
- iA Presenter skill for iA Presenter markdown
- Filing skill updated for mise-en-space v2
- Pytest infrastructure for skill validation
- Buffed all skills to 100/100 CSO

### Changed
- Replaced TodoWrite references with bon in session skills

## 2026-01-25 — Titans & Arc Support

### Added
- Titans skill: three-lens code review (Epimetheus/Metis/Prometheus)
- Arc support in `/close` and open-context.sh

## 2026-01-14–19 — Initial Release

### Added
- Behavioral skills consolidated: /open, /close, /ground
- Session lifecycle scripts and hooks
- Install script with sprite skill PTY pattern
- Diagram skill with learnings from MIT Venn session
- Sprite skill for OuterClaude/InnerClaude tmux pattern
