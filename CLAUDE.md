# claude-suite — Project Context

This repo provides two things for Claude Code:

1. **A session protocol** — hooks and scripts that give Claude session memory. At startup, a hook briefs Claude on previous work. At close, a skill writes a handoff for the next session. The handoff contract (`references/HANDOFF-CONTRACT.md`) specifies the format.

2. **A skill drawer** — 16 SKILL.md files that teach Claude specialized workflows (diagramming, code review, file organization, etc.). Installed as symlinks into `~/.claude/skills/`.

The session protocol is the load-bearing part — other tools (like [aboyeur](https://github.com/spm1001/aboyeur)) depend on its handoff format and encoding scheme. The skills are useful but modular — any can be removed without breaking the protocol.

## Compatibility

**Tested with Claude Code:** 2.1.x
**Minimum required:** 2.0 (hooks API)
**Dependencies:** `jq` (critical — used by all hooks for arc state reads)

## How the Session Protocol Works

### Hook Chain

Three hooks fire on Claude Code events:

| Hook | Event | What it does |
|------|-------|--------------|
| `hooks/session-start.sh` | SessionStart | Calls `scripts/open-context.sh` to generate a briefing |
| `hooks/arc-tactical.sh` | UserPromptSubmit | Injects current work step into every prompt |
| `hooks/session-end.sh` | SessionEnd | Cleanup (with subagent guard to prevent fork bombs) |

**Performance:** Session start ~106ms, per-prompt ~8ms. Hooks read arc state via jq on `.arc/items.jsonl` (~3ms) instead of the Python arc CLI (~30ms).

### Briefing Output

`open-context.sh` writes two things:
- **stdout** — compact briefing Claude sees immediately (outcomes, last session summary, ready work)
- **disk** — `~/.claude/.session-context/<encoded-path>/arc.txt` with full hierarchy for deeper digs

### Handoff Protocol

`/close` writes a handoff file to `~/.claude/handoffs/<encoded-path>/`. The next session's startup hook reads it. Handoffs contain three sections: **Done**, **Next**, **Gotchas**. See `references/HANDOFF-CONTRACT.md` for the full specification.

### Path Encoding

Handoffs and context files are stored in directories named after the project path. The encoding replaces all non-alphanumeric characters with `-`:

```bash
pwd -P | sed 's/[^a-zA-Z0-9-]/-/g'
# /Users/modha/Repos/claude-suite → -Users-modha-Repos-claude-suite
```

This matches Claude Code's own encoding for `~/.claude/projects/`. **If this encoding changes, handoffs become orphaned.** The canonical implementation lives in `scripts/open-context.sh:11` and `scripts/close-context.sh:133`.

## Session Behaviour

**When the session-start hook provides context, orient the user in your first response.** Don't wait for /open — the briefing is there for both of you. Present the outcomes, mention the last session, and ask what they want to work on.

The `/open` skill is still available for re-orientation mid-session or after changing directories.

### GODAR Pattern

Session lifecycle skills follow GODAR:
- **Gather** — Collect context (run scripts, read files)
- **Orient** — Synthesize what matters
- **Decide** — Present choices to user
- **Act** — Execute selected actions
- **Remember** — Persist for future sessions

## Skill Architecture

### Types

| Type | Trigger | Example |
|------|---------|---------|
| User-invocable | Slash command | `/diagram`, `/titans` |
| Alias | Slash command → delegates | `/review` → titans |
| Companion | Loaded by other skills | arc (loaded by /open when `.arc/` exists) |

### Conventions

- Description ends with `(user)` tag for user-facing skills
- `user-invocable: false` for skills loaded programmatically (companion skills)
- Reference files live in `references/` subdirectory, linked from main SKILL.md

### Current Skills (16)

beads, close, diagram, filing, github-cleanup, ia-presenter, open, picture, review, screenshot, server-checkup, setup, skill-check, skill-forge, sprite, titans

### Titans Review

`/titans` (or `/review`) dispatches three parallel Opus reviewers:

| Titan | Lens |
|-------|------|
| **Epimetheus** | Hindsight — bugs, debt, fragility |
| **Metis** | Craft — clarity, idiom, structure |
| **Prometheus** | Foresight — vision, extensibility |

Uses `Task` tool with `subagent_type: "explore-opus"`. Worth it for substantial work; overkill for quick fixes.

## Script Dependencies

| Script | Depends On | Note |
|--------|------------|------|
| `session-start.sh` | `open-context.sh` | Same repo |
| `session-start.sh` | `update-all.sh` | Lives in claude-config, not this repo |
| `open-context.sh` | `arc-read.sh` | Same repo. Falls back to arc CLI if missing |
| `arc-tactical.sh` | `jq` + `.arc/items.jsonl` | Direct jq read, no Python |
| `close-context.sh` | `check-home.sh` | Same repo |
| Multiple scripts | `jq` | Critical dependency for arc reads and hook output |

**Arc CLI** is used for writes (validation, ID generation, tactical step management). **arc-read.sh** handles reads via jq (~3ms vs ~30ms Python startup). The JSONL file is the interface between them — see `FIELD_REPORT_jq_consumers.md` in the arc repo for the field dependency list.

## Extending claude-suite

### Adding a New Skill

1. Create `skills/<name>/SKILL.md` with frontmatter
2. Add `skills/<name>/README.md` (optional but recommended)
3. Run `./install.sh` to create symlink (install.sh globs `skills/*/`, no hardcoded list)

### Adding a New Script

1. Create `scripts/<name>.sh` with `set -euo pipefail`
2. Scripts are auto-symlinked by install.sh (must have `.sh` suffix)
3. Document any dependencies in this file

### Reference Files

Skills can have a `references/` subdirectory:
- Read as-needed, not loaded automatically
- Linked from main SKILL.md with "When to read" guidance
- Naming: UPPERCASE for major references, lowercase for specific topics

## Testing

### Mechanical (pytest)

```bash
uv run pytest           # All tests
uv run pytest -x        # Stop on first failure
uv run pytest -k beads  # Single skill
```

Tests check:
- CSO linter pass + score >= 95/100
- Referenced files exist
- Scripts executable with shebang
- Anti-patterns table format consistency
- arc-read.sh edge cases (empty JSONL, malformed input, all-done items, tactical steps)

### Semantic (titans)

For "does this skill actually make sense?" — use `/titans`. Three Opus reviewers catch issues the linter can't see (stale references, semantic contradictions, missing error handling).

## Error Handling

Scripts use `set -euo pipefail`:
- `-e`: Exit on any command failure
- `-u`: Error on unset variables
- `-o pipefail`: Pipe failures propagate

Hooks are designed to fail gracefully — a broken hook should never prevent Claude Code from starting. All jq reads have `2>/dev/null || true` guards.

## Architecture References

| Document | What it covers |
|----------|---------------|
| `references/HOOKS_AND_SCRIPTS.md` | Full hook architecture audit |
| `references/HANDOFF-CONTRACT.md` | Handoff format specification (encoding, sections, signals) |
| `references/ERROR_PATTERNS.md` | Common issues and troubleshooting |
