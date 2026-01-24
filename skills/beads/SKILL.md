---
name: beads
user-invocable: false
description: Tracks complex, multi-session work with dependency graphs using bd (beads) issue tracker. Triggers on 'multi-session', 'complex dependencies', 'resume after weeks', 'project memory', 'persistent context', 'side quest tracking', 'portfolio', 'all my beads', 'cross-project beads', 'show beads', 'list beads', 'beads grouped by', 'epic', 'bd command', or when TodoWrite is insufficient for scope. For simple single-session linear tasks, TodoWrite remains appropriate. (user)
---

## Reference Files Quick Index

beads has extensive reference material. To avoid reading all files:

**When you need...**
- CLI commands → `references/CLI_BOOTSTRAP_ADMIN.md`
- When to use bd vs TodoWrite → `references/BOUNDARIES.md`
- Session handoff → `references/WORKFLOWS.md` (Session Handoff section)
- Dependency semantics (A blocks B vs B blocks A) → `references/DEPENDENCIES.md`
- **Hierarchy view** → Pre-computed at startup in `=== BEADS_HIERARCHY ===` (see "Commands for Hierarchy" for mid-session queries)
- Troubleshooting → `references/TROUBLESHOOTING.md`
- Design context capture → `references/WORKFLOWS.md` (Design Context section)
- Resumability after compaction → `references/RESUMABILITY.md`
- **Molecules, wisps, protos** → `references/MOLECULES.md` (v0.34.0+)
- **Formulas, gates, activity** → `references/MOLECULES.md` (v0.36.0+)
- **Cross-project dependencies** → `references/MOLECULES.md` (v0.34.0+)
- **Portfolio view (cross-project)** → Run `~/.claude/scripts/beads-portfolio.sh` or see `references/PORTFOLIO.md`
- **Database hygiene / archiving** → "Database Hygiene" section in this file
- **Dangerous commands** → "Dangerous Commands" section in this file

Read SKILL.md first, then load specific references as needed.

**BEFORE running bd commands:** Check `references/CLI_BOOTSTRAP_ADMIN.md` for correct flags.

# Beads Issue Tracking

## Overview

bd is a graph-based issue tracker for persistent memory across sessions, designed for AI-supervised coding workflows. Use for multi-session work with complex dependencies; use TodoWrite for simple single-session tasks.

**Interface:** CLI via Bash tool (bd commands). All operations return JSON with `--json` flag for structured parsing.

## When to Use bd vs TodoWrite

### Use bd when:
- **Multi-session work** - Tasks spanning multiple compaction cycles or days
- **Complex dependencies** - Work with blockers, prerequisites, or hierarchical structure
- **Knowledge work** - Strategic documents, research, or tasks with fuzzy boundaries
- **Side quests** - Exploratory work that might pause the main task
- **Project memory** - Need to resume work after weeks away with full context

### Use TodoWrite when:
- **Single-session tasks** - Work that completes within current session
- **Linear execution** - Straightforward step-by-step tasks with no branching
- **Immediate context** - All information already in conversation
- **Simple tracking** - Just need a checklist to show progress

**Key insight**: If resuming work after 2 weeks would be difficult without bd, use bd. If the work can be picked up from a markdown skim, TodoWrite is sufficient.

**For detailed decision criteria and examples:** [references/BOUNDARIES.md](references/BOUNDARIES.md)

## Session Start Protocol

**bd is available when:**
- Project has a `.beads/` directory (project-local database), OR
- `~/.beads/` exists (global fallback database for any directory)

**Portfolio view:** Run `~/.claude/scripts/beads-portfolio.sh` to see all beads across repos (read-only aggregation).

### NOT in Google Drive (Cloud-Synced Folders)

**SQLite + cloud sync = data corruption.** Do not create or use beads in:
- `~/Library/CloudStorage/GoogleDrive-*/`
- Any Dropbox, iCloud Drive, or OneDrive synced folder

**When user asks for a bead in Drive context:**

> "Beads don't work reliably in cloud-synced folders — SQLite conflicts corrupt the database. Instead, I'll capture this in the handoff with artifact links:
> - Working folder link
> - Specific docs touched this session
> - What changed and next steps
>
> This surfaces at /open just like beads would. Want me to do that now, or at /close?"

**The redirect isn't "no" — it's "yes, differently."** The handoff's Artifacts section serves the same purpose (cross-session memory) without the sync risk.

See `session-closing` skill for the Knowledge Work Context pattern.

**At session start, always check for bd availability and run ready check:**

```bash
# Check recent version changes (if bd recently upgraded)
bd info --whats-new

# Find unblocked work
bd ready --json

# Check active work
bd list --status in_progress --json

# If in_progress exists, read notes for context
bd show <issue-id> --json
```

**Report format:** "I can see X items ready to work on: [summary]. Issue Y is in_progress - last session: [from notes]. Should I continue with that?"

This establishes immediate shared context about available and active work.

**For detailed session handoff workflow:** [references/WORKFLOWS.md](references/WORKFLOWS.md#session-handoff)

## Presenting Beads to User

When showing beads, use GTD vocabulary (see CLAUDE.md) and visual hierarchy that distinguishes Desired Outcomes from Next Actions.

**Maximum 2 levels of hierarchy:**
- Level 1: Desired Outcome (epic)
- Level 2: Next Actions (tasks/bugs)

No nested epics. If you see an epic parented under another epic, flag it — the structure needs flattening.

### Desired Outcomes (type=epic)

```
📦 skill-beads-24w: Beads skill speaks GTD, not Agile
   ├── skill-beads-sl1: Add GTD vocabulary mapping ✅
   ├── skill-beads-03o: Add hierarchy presentation rules
   └── skill-beads-3rb: Document Field Reports pattern
```

### Standalone Next Actions (no parent)

```
• skill-beads-oz5: Add bd-portfolio.sh to PATH
• skill-beads-tig: Slim down SKILL.md
```

### Status Indicators

| Symbol | Meaning |
|--------|---------|
| ✅ | Done |
| ⏳ | In progress |
| 🚫 | Waiting for (blocked) |
| (no symbol) | Ready |

### Commands for Hierarchy

**Hierarchy is pre-computed at session start** — look for `=== BEADS_HIERARCHY ===` in the startup context. Nested epics are flagged with `⚠️ [NESTED EPIC - flatten]`.

**If you need to query mid-session:**

```bash
bd list --parent <epic-id>    # Children of one epic
```

**⚠️ Anti-patterns — don't try these:**
- `bd list --json | jq ... .parent` — NO parent field exists
- `bd dep tree <id>` — shows BLOCKERS, not children
- `bd dep children <id>` — command doesn't exist

**Why "direction up"?** Children *depend on* parents in bd's model. "Up" = "what depends on me" = children. This inverts the intuitive mental model.

### Example: Full Portfolio View

```
📦 skill-beads-24w: Beads skill speaks GTD, not Agile
   ├── skill-beads-sl1: Add vocabulary mapping ✅
   ├── skill-beads-03o: Add presentation rules ⏳
   └── skill-beads-3rb: Document Field Reports

📦 skill-beads-36b: Beads integrates with session rituals
   ├── skill-beads-tyj: Add bd calls to scripts
   ├── skill-beads-e4e: Add bd blocked check
   └── skill-beads-3g5: Add means-ends gate

Standalone:
• skill-beads-oz5: Add bd-portfolio.sh to PATH
• skill-beads-tig: Slim down SKILL.md
```

**Key principle:** Present work as goals with cascading actions, not flat ticket lists.

## Database Hygiene (Yegge Best Practices)

**Keep your database small.** Performance degrades with large issue counts (agents search issues.jsonl directly).

```bash
# Delete closed issues older than N days
bd cleanup --older-than 7 --cascade --force   # Standard cleanup
bd cleanup --older-than 2 --cascade --force   # Aggressive if moving fast

# Run periodically
bd doctor               # Check for issues
bd doctor --fix         # Auto-fix problems

# Prune old tombstones (summaries of deleted issues)
bd compact --prune --older-than 30
```

**Target sizes:**
- ⚠️ >200 issues: Consider cleanup or archiving
- 🛑 >500 issues: Performance problems likely
- Deleted issues remain in git history - always recoverable

**Upgrade regularly:** `bd upgrade` (at least weekly). Bug fixes are frequent.

### Archive Pattern (Preserve History)

When a repo's beads grow large, archive closed issues before deleting:

```bash
# 1. Export closed issues to dated archive file
mkdir -p ~/.beads-archive
bd list --status closed --json | jq -c '.[]' >> ~/.beads-archive/$(date +%Y-%m)-$(basename $PWD).jsonl

# 2. Delete closed issues
bd list --status closed --json | jq -r '.[].id' | xargs -I {} bd delete {} --force

# 3. Export clean state
bd export -o .beads/issues.jsonl --force
git add .beads/issues.jsonl && git commit -m "Archive closed issues"
```

**Archive location:** `~/.beads-archive/` — JSONL files by month and repo, searchable with grep/jq.

**Searching archives:**
```bash
grep "issue-id" ~/.beads-archive/*.jsonl
jq -r 'select(.title | test("keyword"; "i")) | "\(.id): \(.title)"' ~/.beads-archive/*.jsonl
```

### Monthly Maintenance Routine

Run monthly to keep beads healthy across all repos:

```bash
# 1. Portfolio view — see what's active
~/.claude/scripts/beads-portfolio.sh

# 2. For each active repo, sync JSONL with DB
for repo in ~/Repos/*/.beads; do
  cd "$(dirname "$repo")"
  bd export -o .beads/issues.jsonl --force 2>/dev/null
  git add .beads/issues.jsonl 2>/dev/null
done

# 3. Commit any changes
cd ~/Repos && for d in *; do
  [ -d "$d/.beads" ] && cd "$d" && git diff --quiet .beads/issues.jsonl || \
    git commit -m "Sync beads JSONL with database" .beads/issues.jsonl 2>/dev/null
  cd ~/Repos
done
```

**Why this matters:** The database (`.db`) and JSONL can drift. Periodic export ensures JSONL (which is git-tracked and backed up) matches the database.

## Dangerous Commands — Avoid

| Command | Why | Alternative |
|---------|-----|-------------|
| `bd sync --rename-on-import` | Renames ALL issues to wrong prefix | Never use. If sync fails, investigate manually. |
| `bd init` inside `.beads/` directory | Creates nested `.beads/.beads/` | Always run `bd init` from project root |
| `bd --db ... create/update` | Easy to hit wrong database | `cd ~/Repos/target && bd create/update` instead |

### Deleting Issues Properly

`bd delete` removes from the SQLite DB but not from `issues.jsonl`. For permanent deletion:

```bash
# 1. Delete from DB
bd delete PREFIX-xxx --force

# 2. Export clean state to JSONL
bd export -o .beads/issues.jsonl --force

# 3. Commit
git add .beads/issues.jsonl && git commit -m "Remove issue PREFIX-xxx"
```

## When to File Issues

**File issues liberally.** Any work taking >2 minutes deserves an issue.

- During code reviews, file issues as you find them
- Capture context immediately rather than losing it when conversation ends
- Models often file spontaneously - nudging helps

**Plan outside Beads, then import.** For larger plans:
1. Use external planning tool first (refine with model)
2. Ask agent to file detailed epics/issues with dependencies
3. Ask agent to review, proofread, refine the filed beads
4. Can iterate up to 5 times on both plan and beads

**Restart agents frequently.** One task at a time → kill process → start fresh. Beads is the working memory between sessions. Saves money, better model performance.

## Field Reports (Claude-to-Claude)

Field Reports are a distinct bead genre for Claude-to-Claude knowledge transfer — observations, friction points, learnings filed by one Claude for future Claudes to find.

### What Makes Field Reports Different

| Aspect | Work Item | Field Report |
|--------|-----------|--------------|
| **Intent** | "Do X" | "I observed Y" |
| **Author** | Human or Claude | Claude (specifically) |
| **Audience** | Next Claude working on it | Future Claudes generally |
| **Lifecycle** | Open → Done → Closed | Filed → Persists as knowledge |
| **Voice** | Task description | Observational judgement |

### When to File

- Friction with a tool or API that others will hit
- Mental model mismatch ("expected X, got Y, here's what I think that means")
- Workarounds discovered during implementation
- Patterns that worked well (or didn't)
- Ergonomic observations about skills or workflows

### Template

```bash
bd create "Field Report: [brief observation]" \
  --type task \
  --label field-report \
  --description "[What I noticed — dense, Claude-to-Claude style]" \
  --design "$(cat <<'EOF'
## Context
[What I was trying to do]

## Observation
[What happened, with judgement — not just facts]

## Suggestion
[What might help future Claudes]
EOF
)"
```

### Lifecycle

**Don't close field reports** — they persist as institutional memory.

**Review periodically:**
- Extract patterns → update skills
- Close only if fully addressed (rare)
- Promote to actionable work if needed

### Why "Field Report" Not "Bug Ticket"

LLMs are judgement machines. A field report expresses a considered view: "this felt harder than it should", "the mental model didn't match the API". That's qualitatively different from mechanical steps-to-reproduce.

The voice is dense and efficient — Claude briefing Claude, not Claude filing a ticket.

## Core CLI Operations

All commands support `--json` for structured output. JSON always returns an array.

```bash
# Essential workflow
bd ready --json                              # Find unblocked work
bd update <id> --status in_progress          # Claim work
bd close <id> --reason "What was done"       # Complete work

# jq patterns for parsing
bd show <id> --json | jq '.[0].title'        # Single issue field
bd list --json | jq -r '.[] | "\(.id): \(.title)"'  # Format list
```

**For complete CLI reference:** [references/CLI_BOOTSTRAP_ADMIN.md](references/CLI_BOOTSTRAP_ADMIN.md)

## Understanding Dependencies (CRITICAL)

**The mental model trap:** `bd dep add A B` means "A depends on B", NOT "A blocks B"!

**Mnemonic:** "DEPENDENT depends-on PREREQUISITE"

```bash
bd dep add implementation setup   # implementation waits for setup
bd dep add child parent --type parent-child  # Desired Outcome structure
```

**Dependency types:** blocks (default), related, parent-child, discovered-from

**For detailed patterns and examples:** [references/DEPENDENCIES.md](references/DEPENDENCIES.md)

## Session Continuity

**The notes field is your only persistent memory.** Compaction deletes conversation history; beads survive.

**Write notes for future Claude with zero context:**
- COMPLETED: what was done
- KEY DECISION: what was decided and why
- IN PROGRESS: current state
- NEXT: what to do next

**Checkpoint triggers:** context low, milestone reached, blocker hit, task transition, before user decision.

**Test:** "If compaction happened now, could future-me resume from these notes?"

**For detailed workflows:** [references/WORKFLOWS.md](references/WORKFLOWS.md#compaction-survival)

## Molecules and Workflow Automation (v0.34.0+)

| Term | What it is | Use case |
|------|-----------|----------|
| **Proto** | Template (epic with `template` label) | Reusable workflow pattern |
| **Mol** | Persistent instance from proto | Tracked work with audit trail |
| **Wisp** | Ephemeral instance | Operational loops, no clutter |
| **Formula** | TOML workflow definition | Declarative multi-step workflows |
| **Gate** | Async coordination point | Timer/GitHub/human waits |

```bash
bd mol catalog                           # List templates
bd pour mol-release --var version=2.0    # Create persistent mol
bd wisp create mol-patrol                # Create ephemeral wisp
```

**For detailed patterns and commands:** [references/MOLECULES.md](references/MOLECULES.md)

user-invocable: false
---

## Issue Lifecycle

```
Discovery → Execution → Closure
   ↓           ↓          ↓
bd create   in_progress  bd close
```

**Discovery:** File immediately with `--type discovered-from` link. Capture context before conversation ends.

**Execution:** `bd update <id> --status in_progress` → work → `bd close <id> --reason "..."`

**Planning:** Create Desired Outcome (epic) → child Next Actions → link with parent-child + ordering deps.

**For complete workflow patterns:** [references/WORKFLOWS.md](references/WORKFLOWS.md)

## Field Usage Reference

| Field | Purpose | When to Set | Update Frequency |
|-------|---------|-------------|------------------|
| **description** | Immutable problem statement | At creation | Never (fixed forever) |
| **design** | Initial approach, architecture, decisions | During planning | Rarely (only if approach changes) |
| **acceptance-criteria** | Concrete deliverables checklist (`- [ ]` syntax) | When design is clear | Mark `- [x]` as items complete |
| **notes** | Session handoff (COMPLETED/IN_PROGRESS/NEXT) | During work | At session end, major milestones |
| **status** | Workflow state (open→in_progress→closed) | As work progresses | When changing phases |
| **priority** | Urgency level (0=highest, 3=lowest) | At creation | Adjust if priorities shift |

**Key pattern:** Notes field is your "read me first" at session start.

## Integration with TodoWrite

**TodoWrite and bd complement each other at different timescales:**

- **TodoWrite:** Short-term working memory (this hour) - tactical execution, ephemeral
- **bd:** Long-term episodic memory (this week/month) - strategic context, persistent

**The handoff pattern:** Session start → read bd notes → create TodoWrite → work → update bd at milestones → TodoWrite disappears, bd survives.

**Key principle:** TodoWrite tracks execution ("Implement endpoint"), bd captures meaning ("COMPLETED: Endpoint with JWT auth. KEY DECISION: RS256 for key rotation").

**For temporal layering patterns:** [references/INTEGRATION_PATTERNS.md](references/INTEGRATION_PATTERNS.md#todowrite-integration)

### Draw-Down Pattern

**Draw-down triggers on ALL substantial work, not just explicit bead claims.**

#### Explicit triggers
- User says "let's work on bead X"
- You run `bd update <id> --status in_progress`

#### Implicit triggers (Jan 2026 learnings)

| User says | What to do |
|-----------|------------|
| "continue X", "keep going", "pick up where we left off" | Clarify which bead (epic vs subtask), then draw-down |
| *provides external brief/spec* | Extract acceptance criteria from brief, create TodoWrite |
| "the email thing", "that feature" | Don't guess. Ask which bead, then draw-down |

**The test:** If work will take >10 minutes, it needs TodoWrite items.

**Failure mode (Jan 2026):** User said "continue backfill" → Claude continued existing code without checking epic scope → discovered an hour later that "complete pass" meant more than just file attachments. Draw-down would have caught the scope gap immediately.

#### The draw-down steps

**STOP. Before doing anything else:**

1. `bd show <bead-id> --json` — read design and acceptance-criteria
2. Create TodoWrite items — actual steps, not "work on the bead"
3. Show user: "Breaking this down into: [list]. Sound right?"
4. **VERIFY:** TodoWrite is not empty before proceeding
5. THEN start working

**If TodoWrite is empty after starting substantial work, you have failed.** This is not optional.

At each TodoWrite completion, pause: "Still the right direction?"

**Why this matters:** Beads alone don't create pauses. TodoWrite items create natural breakpoints. These breakpoints are where you catch drift before it compounds.

**The failure mode:** Without draw-down, you work from the bead directly, context accumulates, and by the time /close runs you've drifted. The breakpoints are where course-correction happens.

**Example — Good draw-down:**

```
Bead: "Add user authentication to API"
Design: "JWT with RS256, refresh tokens, password reset flow"
Acceptance: "Login/logout works, tokens expire correctly, reset email sends"

→ TodoWrite:
1. Set up JWT library and key generation
2. Implement login endpoint with token issuance
3. Implement token refresh endpoint
4. Implement logout (token invalidation)
5. Implement password reset flow
6. Add integration tests
```

Each TodoWrite item is a checkpoint. When you complete item 2 and start item 3, that's a moment to ask "still on track?" Not just motor through.

**Example — Bad (no draw-down):**

```
Bead: "Add user authentication to API"
→ Start coding immediately
→ 45 minutes later, deep in password reset edge cases
→ Forgot about token refresh entirely
→ Context exhausted, /close runs, handoff is confused
```

### Session Boundary Pattern

**Trigger:** You just closed a bead (or batch of beads) and there's more ready work.

**STOP. Before summarizing and asking "what's next?":**

1. Check `bd ready` — what's now unblocked?
2. If user wants to continue → **do the draw-down for the next bead**
3. If user wants to stop → proceed to /close

**The gap this fills:** Draw-down happens at session start because `/open` commands it. But mid-session transitions (finishing one bead, starting another) don't have the same trigger. This pattern creates the checkpoint.

**Example — Good session boundary:**

```
[Complete bead .claude-ftz]
bd close .claude-ftz --reason "Fixed container detection"

"Bug fix complete. Ready work now includes:
- .claude-dqg (handoff accumulation) — was blocked, now ready
- .claude-c9j (bidirectional reflection)

Want to continue with .claude-dqg? If so, let me draw down from its acceptance criteria..."
```

**Example — Bad (no boundary check):**

```
[Complete bead .claude-ftz]
bd close .claude-ftz --reason "Fixed container detection"

"Done! What's next?"
→ User says "continue"
→ Start working without draw-down
→ Drift begins
```

**The pattern:** Close bead → check ready → offer next with draw-down commitment.

## Issue Creation Guidelines

**Quick guidelines:**
- Ask user first for knowledge work with fuzzy boundaries
- Create directly for clear bugs, technical debt, or discovered work
- Use clear titles, sufficient context in descriptions
- Design field: HOW to build (can change during implementation)
- Acceptance criteria: WHAT success looks like (should remain stable)

**Self-check for acceptance criteria:**

❓ "If I changed the implementation approach, would these criteria still apply?"
- → **Yes** = Good criteria (outcome-focused)
- → **No** = Move to design field (implementation-focused)

**Standard design field structure:**

```bash
bd create "Title" --design "$(cat <<'EOF'
## Approach
[How you'll build this]

## Workflow
1. DRAW-DOWN: Create TodoWrite items from acceptance criteria
2. Work through items, check direction at each completion
3. Update notes at milestones
EOF
)"
```

Every new bead should include the Workflow section. When you `bd show` later, the reminder is right there in the output. Self-documenting enforcement.

**For detailed creation guidance:** [references/ISSUE_CREATION.md](references/ISSUE_CREATION.md)

## Error Recovery

**Wrong Dependency Created:**
```bash
# Remove wrong dependency
bd dep remove A B

# Create correct dependency (B depends on A)
bd dep add B A

# Verify
bd show B  # Should show "Dependencies: A"
```

**Closed Issue Prematurely:**
```bash
# Reopen the issue
bd reopen <issue-id> --reason "Need to add error handling"

# Issue returns to 'open' status
```

**Duplicate Issues:**
```bash
# Preview deletion
bd delete <issue-dup>

# Force delete if safe
bd delete <issue-dup> --force

# If duplicate has dependencies, reassign first
bd dep remove dependent issue-dup
bd dep add dependent issue-kept
bd delete issue-dup --force
```

### Database Recovery

If a repo's beads are corrupted (wrong prefixes, duplicate issues), see [references/TROUBLESHOOTING.md](references/TROUBLESHOOTING.md) for recovery patterns.

## Statistics and Monitoring

```bash
# Project health overview
bd stats --json

# Find blocked work
bd blocked --json

# Check daemon status
bd daemon --status
```

Use stats to report progress, identify bottlenecks, and understand project velocity.

## Troubleshooting

**For comprehensive troubleshooting guide:** [references/TROUBLESHOOTING.md](references/TROUBLESHOOTING.md)

**Common issues:**
- Dependencies not persisting → Check bd version (need v0.15.0+)
- Status updates delayed → Daemon sync timing (3-5s delay expected)
- Daemon won't start → Git repository required
- Cloud storage errors → SQLite incompatible with Google Drive/Dropbox

## Database Selection

bd automatically selects the appropriate database:
- **Project-local** (`.beads/` in project): Used for project-specific work
- **Global fallback** (`~/.beads/`): Used when no project-local database exists

**Use --db flag explicitly when:**
- Accessing a specific database outside current directory
- Working with multiple databases (e.g., project database + reference database)

**Cross-project writes (Claude coordination):**
To modify another project's beads, `cd` to that repo first. This ensures you're working with the correct database and prefix.

```bash
# To file/modify beads in another repo:
cd ~/Repos/other-project && bd create "Issue discovered while working elsewhere" -p 1

# To reorganize another repo's beads:
cd ~/Repos/itv-slides-formatter && bd update itv-slides-formatter-x9d --parent itv-slides-formatter-bzd
```

**Why cd, not --db?** The `--db` flag is error-prone for writes — wrong paths, wrong prefixes, pollution. Being "in" the repo makes the target explicit. Use `--db` only for read-only queries.

**Note:** Working directory doesn't persist between Bash calls, so always chain: `cd ~/Repos/X && bd command`

**Moving issues between repos:**
Issues can't truly "move" — the prefix IS the identity. When relocating an issue:

1. Create new issue in target repo
2. Add "(Moved from old-id)" to the description
3. Delete old issue

That's it. No alias files, no infrastructure. Just a note in the description so future Claudes can trace lineage.

## Portfolio View (Cross-Project)

To see all beads across repos, use the portfolio script:

```bash
~/.claude/scripts/beads-portfolio.sh
```

This reads from all repos and displays a unified view. **It never writes** — just aggregates for visibility.

**Key principle: Per-repo databases are authoritative.**
- Each repo's `.beads/` is the source of truth
- No sync between repos (sync caused corruption)
- Portfolio script reads on-demand, not continuously

**To modify beads:** Always `cd` to the target repo first:
```bash
cd ~/Repos/itv-slides-formatter && bd update ...   # Correct
bd --db ~/Repos/itv-slides-formatter/...           # Avoid for writes
```

**Cross-project visibility without cross-project sync:**
- Portfolio shows what's ready across all projects
- You pick which project to focus on
- Work happens in that project's database only

## Bootstrap and Initialization

**Use short prefixes** (2-3 chars): `bd-`, `vc-`, `wy-`. Makes everything more readable.

```bash
# Initialize new project (auto-detects prefix from folder name)
bd init

# Initialize with explicit short prefix
bd init --prefix wy

# Install git hooks for auto-sync
bd hooks install

# Start daemon (auto-starts on first command)
bd daemon

# Compact old closed issues
bd compact --all
```

**For complete bootstrap guide:** [references/CLI_BOOTSTRAP_ADMIN.md](references/CLI_BOOTSTRAP_ADMIN.md)

## Common Patterns

**Quick patterns for typical scenarios:**

- **Knowledge work:** Read bd notes → create TodoWrite → work → update notes at milestones
- **Side quests:** Create issue immediately, link with discovered-from, assess blocker vs defer
- **Multi-session resume:** `bd ready` → `bd show` → read notes → begin work
- **Compaction recovery:** Read notes field to reconstruct full context
- **Status transitions:** open → in_progress → blocked/closed as appropriate

**For detailed pattern examples:** [references/PATTERNS.md](references/PATTERNS.md)

## Reference Files

Detailed information organized by topic:

| Reference | Read When |
|-----------|-----------|
| [TROUBLESHOOTING.md](references/TROUBLESHOOTING.md) | **Encountering errors** - dependencies not saving, sync delays, daemon issues |
| [WORKFLOWS.md](references/WORKFLOWS.md) | Need step-by-step workflows with checklists for common scenarios |
| [DEPENDENCIES.md](references/DEPENDENCIES.md) | Need deep understanding of dependency types or relationship patterns |
| [BOUNDARIES.md](references/BOUNDARIES.md) | Need detailed decision criteria for bd vs TodoWrite |
| [PATTERNS.md](references/PATTERNS.md) | Need detailed examples of common patterns and status transitions |
| [INTEGRATION_PATTERNS.md](references/INTEGRATION_PATTERNS.md) | Need integration with TodoWrite or writing-plans |
| [ISSUE_CREATION.md](references/ISSUE_CREATION.md) | Need guidance on when to ask vs create issues, issue quality |
| [CLI_BOOTSTRAP_ADMIN.md](references/CLI_BOOTSTRAP_ADMIN.md) | Need CLI commands for bootstrap or admin operations |
| [RESUMABILITY.md](references/RESUMABILITY.md) | Need patterns for writing resumable notes |
| [STATIC_DATA.md](references/STATIC_DATA.md) | Want to use bd for reference databases instead of work tracking |
| [MOLECULES.md](references/MOLECULES.md) | **Reusable templates** - protos, mols, wisps, cross-project deps (v0.34.0+) |
| [PORTFOLIO.md](references/PORTFOLIO.md) | **Cross-project view** - see all beads across repos, triage, audit skeleton beads |
