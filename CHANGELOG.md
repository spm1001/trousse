# Changelog

## [0.5.12] - 2026-06-20

### Docs
- Post-cutover staleness sweep. Removed decommissioned garde-manger references from the plugin description ("Best with: bon, garde-manger" → "bon"), `CLAUDE.md` (past-session-recall guidance), and the `deglacer` skill (frontmatter + "When NOT to Use"). Fixed the `deglacer` skill's install path (`~/Repos/batterie/deglacer` → `git+https`) and the `CLAUDE.md` plugin-install nav path (`batterie-de-savoir` → `claude plugin marketplace add spm1001/batterie` + `trousse@batterie`). README: corrected the skills table (dropped removed sprite/claude-survey/amp-close, added deglacer/peer-review/tamis, count 17→18) and `~/Repos` path casing.

## [0.5.11] - 2026-06-12

### Added
- `tamis` skill — inspects which ad/martech/analytics/affiliate tags fire on any site, by driving a clean headless Chrome that bypasses ControlD DNS filtering and uBlock via DoH (IP-literal `1.1.1.1`, set by a managed policy). Captures the full network with cookies accepted, groups every host by vendor against a taxonomy, and flags unknowns for hand identification. Composes with `passe`. Ships `references/tag-taxonomy.md` (~70 vendors) and `scripts/tag_scan.py` (stdlib-only helper).

## [0.5.10] - 2026-06-11

Packaging-only: top-level `scripts/` (ardoise.sh) ships in the marketplace package again — the batterie assembler's lean copy-list dropped it at the 2026-06-10 cutover, breaking the ardoise skill's `${CLAUDE_PLUGIN_ROOT}/scripts/ardoise.sh` entry point. Fix is in batterie's assemble.sh; this bump propagates it.

## [0.5.9] - 2026-05-31

Restore `github-cleanup` (removed in 0.5.8) — broadened from ad-hoc GitHub cleanup into a standing cross-machine repo-hygiene checkup, which now justifies the catalog slot.

### Added
- `github-cleanup` skill, with a new **Phase 0.5: cross-machine working-tree sweep** — flags uncommitted/unpushed/drift across local + ssh hosts before the GitHub-side audit
- `scripts/repo-sweep.sh` — reusable engine (`local` / `ssh <host>` / `--no-fetch` modes); fetches by default to avoid stale-ref false "ahead" readings
- Plugin **version-bump guard** — warns when a plugin repo has changes but no `plugin.json` bump (changes won't propagate to clients)

## [0.5.8] - 2026-04-24

Catalog cleanup pass — drop unused skills, trim bloated descriptions, fix toise CSO regression.

### Removed
- `amp-close` — author moved off Amp; CC-only now
- `claude-survey` — design-research niche, rarely fired
- `github-cleanup` — easy enough to invoke ad-hoc, didn't justify catalog space
- `sprite` — Sprites.dev VM testing no longer in active use

### Changed
- `ardoise` description: 1500 → 425 chars (cut env-scrub mechanics, two-mode breakdown, cross-platform note). CSO score 95 → 100.
- `mandoline` description: 1500 → 368 chars (cut 7-phase workflow listing — body content only).
- `google-devdocs` description: 548 → 392 chars (cut curl+jq detail and full site list).
- `ardoise` body: flipped script-locate to `${CLAUDE_PLUGIN_ROOT}` primary with `find | sort -r | head -1` fallback (was the other way round — fragile when multiple cached versions exist).
- `ardoise` composition table: dropped dangling `sandbox` row (no such trousse skill) and `sprite` row (deleted in this release).
- `toise` description: added timing condition (INVOKE BEFORE / WHEN) — was missing.
- `toise` anti-patterns table: added `Fix` column to match house format.
- `toise` synthesis section: rewrote "What NOT to do" prohibitions as positive guidance — fixes register negation.
- `CLAUDE.md`: skill count 18 → 16, list refreshed.

### Fixed
- `toise` CSO score: 94 → 100. Brings CI green.

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
- Ardoise: context-isolated Claude via env scrub (renamed from neutral-claude)
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
- Claude-survey skill with ardoise isolation pattern
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
