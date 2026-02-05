# claude-suite — Project Context

Learnings from developing and maintaining the behavioral skills.

## Compatibility

**Tested with Claude Code:** 2.1.x
**Minimum required:** 2.0 (hooks API)
**settings.json format:** As of Jan 2026

## GODAR Pattern

Session lifecycle skills follow GODAR:
- **Gather** — Collect context (run scripts, read files)
- **Orient** — Synthesize what matters
- **Decide** — Present choices to user
- **Act** — Execute selected actions
- **Remember** — Persist for future sessions

This pattern ensures systematic context transfer between sessions. See `/open` and `/close` skill implementations.

## Hook Architecture

**Output contract:** Hooks output *pointers* to content, not content itself. This avoids token bloat.

| Output To | Purpose |
|-----------|---------|
| stdout | Notifications Claude receives directly (brief) |
| Files | Content Claude reads on demand via Read tool |

**Section format:** `=== SECTION ===` markers allow parsing specific parts.

**Hook chain:**
- `hooks/session-start.sh` → calls `scripts/open-context.sh`
- `scripts/close-context.sh` ← called by /close skill

## Titans Review Process

The `/titans` (or `/review`) skill dispatches three parallel Opus reviewers with different lenses:

| Titan | Focus | Typical findings |
|-------|-------|------------------|
| **Epimetheus** | Hindsight — bugs, debt, fragility | Silent failures, missing error handling, race conditions |
| **Metis** | Craft — clarity, idiom, structure | Stale references, naming inconsistencies, magic numbers |
| **Prometheus** | Foresight — vision, extensibility | Undocumented contracts, missing version markers |

**When to use:** After substantial work, before shipping, periodic hygiene.

**Token cost:** Three Opus agents is not cheap. Worth it for substantial work; overkill for quick fixes.

**Self-review is valuable:** The titans skill reviewing itself found real issues (stale paths, PII in scanner config). Self-blindness is real.

**Dispatch mechanism:** Uses `Task` tool with `subagent_type: "explore-opus"`. Partial failures are handled gracefully — if one reviewer fails, synthesis proceeds with available outputs.

## Context Encoding Scheme

**Critical infrastructure — divergence causes data loss.**

The pattern `$(pwd -P | tr '/.' '-')` converts paths to directory-safe names for handoff routing:
- `/Users/modha/Repos/claude-suite` → `-Users-modha-Repos-claude-suite`
- Both `/` and `.` are replaced (`.` because hidden directories would create `.`-prefixed encoded names)

This encoding is used in:
- `~/.claude/.session-context/<encoded>/` — per-project context files (cache, can regenerate)
- `~/.claude/handoffs/<encoded>/` — per-project handoff archives (permanent)

**Canonical location:** `scripts/open-context.sh:11` and `scripts/close-context.sh:133`

**If this encoding changes, handoffs become orphaned.** Any migration would need to move existing directories.

## Skill Architecture

### Skill Taxonomy

| Type | Trigger | Example |
|------|---------|---------|
| User-invocable | Slash command | `/diagram`, `/titans` |
| Alias | Slash command → delegates | `/review` → titans |
| Companion | Loaded by other skills | arc (default), beads (legacy), todoist-gtd |

### SKILL.md Conventions

Per skill-check guidelines:
- Description should end with `(user)` tag for user-facing skills
- `user-invocable: false` for skills loaded programmatically
- Reference files in `references/` subdirectory, linked from main SKILL.md

## Script Dependencies

| Script | Depends On | Note |
|--------|------------|------|
| `session-start.sh` | `open-context.sh` | Same repo |
| `session-start.sh` | `update-all.sh` | Lives in claude-config, not this repo |
| `close-context.sh` | `check-home.sh` | Same repo |
| Multiple scripts | `jq` | External dependency, checked by install.sh |
| `session-start.sh` | `perl` | Falls back to `date` if missing (loses ms precision) |

**Arc CLI:** Default work tracker. Path: `~/Repos/arc/.venv/bin/arc`

## Why Arc over Beads

**Historical context (Jan 2026):** Beads was the original work tracker — powerful but heavy. Epics, dependencies, molecules, hub topology, prefix routing. The ceremony accumulated.

Arc emerged as a lighter alternative: outcomes + actions, GTD vocabulary native, required briefs (forces clarity). No hub, no cross-project wiring, no daemon.

**The decision:** Arc became the default for new projects. Beads remains for existing `.beads/` projects — it works, no reason to force migration. But new work uses arc.

**Migration:** `arc migrate --from-beads` converts existing beads to arc format if needed.

## Extending claude-suite

### Adding a New Skill

1. Create `skills/<name>/SKILL.md` with frontmatter
2. Add `skills/<name>/README.md` (optional but recommended)
3. **Update `install.sh` verification list** (lines 123 and 409) — hardcoded, requires manual sync
4. Run `./install.sh` to create symlink

### Adding a New Script

1. Create `scripts/<name>.sh` with `set -euo pipefail`
2. Scripts are auto-symlinked by install.sh (must have `.sh` suffix)
3. Document any dependencies in this file

### Reference Files Convention

Skills can have a `references/` subdirectory:
- Read as-needed, not loaded automatically
- Linked from main SKILL.md with "When to read" guidance
- Naming: UPPERCASE for major references (WORKFLOWS.md), lowercase for specific topics

## Skill Verification

Run `./install.sh --verify` to check all skills are properly symlinked. The verification list must be kept in sync with actual skills in `skills/` directory.

**Current skills (16):** beads, close, diagram, filing, github-cleanup, ia-presenter, open, picture, review, screenshot, server-checkup, setup, skill-check, skill-forge, sprite, titans

## Testing Skills

**The honest split:** Skill quality has two parts — mechanical checks (automatable) and semantic judgment (requires LLM).

### Mechanical (pytest)

```bash
uv run pytest           # All tests
uv run pytest -x        # Stop on first failure
uv run pytest -k beads  # Single skill
```

Tests check:
- CSO linter pass + 100/100 score
- Referenced files in `references/` exist
- Scripts executable with shebang
- Anti-patterns table format consistency

### Semantic (titans)

For "does this skill actually make sense?" — use `/titans` or `/review`. Three Opus reviewers catch:
- Description/frontmatter contradictions
- Stale references
- Missing error handling
- Semantic issues the linter can't see

**When to use what:**
- After modifying skills → `uv run pytest` (fast, catches regressions)
- Before shipping substantial skill work → `/titans` (thorough, catches judgment issues)

## Script Error Handling

Scripts use `set -euo pipefail` for strict error handling:
- `-e`: Exit on any command failure
- `-u`: Error on unset variables
- `-o pipefail`: Pipe failures propagate

This is stricter than the previous `set -e`. Watch for breakage if scripts relied on unset variables being empty.

**The `--no-daemon` convention:** Scripts use `bd ready --no-daemon` for synchronous results. The daemon introduces async latency unsuitable for script contexts.
