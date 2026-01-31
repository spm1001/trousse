---
name: beads
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
- **Molecules, wisps, protos, formulas** → `references/MOLECULES.md` (v0.34.0+)
- **Portfolio view (cross-project)** → See `references/PORTFOLIO.md`
- **Database hygiene / archiving** → "Database Hygiene" section in this file
- **Dangerous commands** → "Dangerous Commands" section in this file

Read SKILL.md first, then load specific references as needed.

**BEFORE running bd commands:** Check `references/CLI_BOOTSTRAP_ADMIN.md` for correct flags.

# Beads Issue Tracking

## Overview

bd is a graph-based issue tracker for persistent memory across sessions, designed for AI-supervised coding workflows. Use for multi-session work with complex dependencies; use TodoWrite for simple single-session tasks.

**Interface:** CLI via Bash tool (bd commands). All operations return JSON with `--json` flag for structured parsing.

## When to Use

- **Multi-session work** — tasks spanning days or compaction cycles
- **Complex dependencies** — work with blockers or hierarchical structure
- **Project memory** — need to resume after weeks with full context

## When NOT to Use

- **Single-session tasks** — use TodoWrite instead
- **Linear execution** — straightforward step-by-step, no branching
- **Cloud-synced folders** — SQLite + Google Drive/Dropbox = corruption

**Test:** If resuming after 2 weeks would be difficult without bd, use bd.

**For detailed decision criteria:** [references/BOUNDARIES.md](references/BOUNDARIES.md)

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

## Database Hygiene

**Keep databases small.** Performance degrades with >200 issues.

```bash
bd cleanup --older-than 7 --cascade --force   # Delete old closed issues
bd doctor --fix                               # Auto-fix problems
bd upgrade                                    # Keep bd current (weekly)
```

**For archive patterns and monthly maintenance:** [references/CLI_BOOTSTRAP_ADMIN.md](references/CLI_BOOTSTRAP_ADMIN.md)

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

Field Reports capture observations and friction points for future Claudes. Use `--label field-report` and don't close them — they persist as institutional memory.

**For template and lifecycle:** [references/PATTERNS.md](references/PATTERNS.md)

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

- Design field: HOW to build (can change)
- Acceptance criteria: WHAT success looks like (should remain stable)
- **Test:** "If I changed the approach, would criteria still apply?" Yes → good criteria.

**For detailed creation guidance:** [references/ISSUE_CREATION.md](references/ISSUE_CREATION.md)

## Error Recovery & Troubleshooting

```bash
bd dep remove A B && bd dep add B A   # Fix wrong dependency
bd reopen <id> --reason "..."         # Reopen closed issue
bd delete <id> --force                # Remove duplicate
bd stats --json                       # Project health
```

**For detailed recovery patterns:** [references/TROUBLESHOOTING.md](references/TROUBLESHOOTING.md)

## Database Selection & Cross-Project

- **Project-local** (`.beads/` in project) is used automatically
- **Cross-project writes:** Always `cd ~/Repos/X && bd command` (never use `--db` for writes)
- **Portfolio view:** `~/.claude/scripts/beads-portfolio.sh` (read-only aggregation)

**For detailed patterns:** [references/PORTFOLIO.md](references/PORTFOLIO.md)

## Bootstrap

```bash
bd init --prefix wy       # Use short 2-3 char prefix
bd hooks install          # Git hooks for auto-sync
bd daemon                 # Start daemon (usually auto-starts)

# Compact old closed issues
bd compact --all
```

**For complete bootstrap guide:** [references/CLI_BOOTSTRAP_ADMIN.md](references/CLI_BOOTSTRAP_ADMIN.md)

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Skip draw-down | Drift compounds, scope gaps | Always create TodoWrite from acceptance criteria |
| Work from bead directly | No checkpoints | Break into TodoWrite items first |
| Use `--db` for writes | Wrong prefix, pollution | `cd` to target repo instead |
| Beads in cloud folders | SQLite corruption | Use ~/Repos only |

## Common Patterns

**For detailed pattern examples:** [references/PATTERNS.md](references/PATTERNS.md)

## Reference Files

See **Quick Index** at top of this file for when to read each reference.
