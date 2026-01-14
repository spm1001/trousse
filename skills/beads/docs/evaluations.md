# Skill Evaluation Scenarios

Behavioral test cases for validating the bd-issue-tracking skill. These are not automated tests, but scenarios to check manually when making significant changes to the skill.

## Purpose

These scenarios caught the critical dependency direction bug (2025-10-23) where guidance had semantics completely backwards. Check these scenarios after major skill changes to prevent regressions.

---

## Evaluation 1: Dependency Direction

**What it tests**: Correct dependency semantics (`bd dep add A B` means "A depends on B")

**Setup**:
```bash
bd init test-project
bd create 'Setup database' -t task
bd create 'Create API' -t task
```

**User query**: "Phase 1 (setup-1) must complete before Phase 2 (test-2). Create the dependency."

**Expected behavior**:
- Creates dependency with: `bd dep add test-2 setup-1`
- Verifies with: `bd show test-2`
- Confirms test-2 shows setup-1 under "Dependencies (blocks this issue)"
- Does NOT create reversed dependency (`bd dep add setup-1 test-2`)

**Failure mode**: Creating `bd dep add setup-1 test-2` (backwards - would make setup wait for API!)

**Why this matters**: The intuitive reading is wrong. "A before B" requires `bd dep add B A`, not `bd dep add A B`.

---

## Evaluation 2: Session Start Protocol

**What it tests**: Proactive context establishment at session start

**Setup**: Create project with `.beads/` directory and 3 ready issues

**User query**: "Start a new session in this project"

**Expected behavior**:
- Runs `bd ready` without being asked
- Reports: "I can see 3 items ready to work on: [brief summaries]"
- Asks which to work on or suggests highest priority
- Does NOT wait for user to ask about bd status

**Failure mode**: Not checking bd status proactively, waiting for user to mention bd

**Why this matters**: bd is most valuable when it establishes shared context immediately, not when prompted.

---

## Evaluation 3: Compaction Recovery

**What it tests**: Reconstructing context from bd notes alone after conversation history loss

**Setup**: Simulated compaction - no conversation history available, only bd state

**User query**: "Continue working on project"

**Expected behavior**:
- Runs `bd list --status in_progress`
- Runs `bd show` on in_progress issues
- Reads notes field to understand context
- Reports: "From notes: [summary of COMPLETED]. Currently [IN PROGRESS]. Next: [from NEXT]. Should I continue?"
- Reconstructs working context from bd state alone

**Failure mode**: Asking user "what were we working on?" when notes field contains full context

**Why this matters**: Compaction survival is bd's primary value proposition. Notes must be self-sufficient.

---

## Evaluation 4: Progress Checkpointing

**What it tests**: Proactive checkpointing before token limit crashes session

**Setup**: Working on issue, token usage at 75%

**User query**: "Continue implementation"

**Expected behavior**:
- Notices token usage approaching limit
- Proactively says: "At 75% tokens - should checkpoint to bd?"
- If yes, updates bd notes with COMPLETED/IN_PROGRESS/NEXT format
- Includes KEY DECISIONS in notes, not just status

**Failure mode**: Not checkpointing until session crashes, losing context

**Why this matters**: Checkpoint timing is critical. Wait too long = lose context. Too early = overhead.

---

## Evaluation 5: TodoWrite Integration

**What it tests**: Using both tools appropriately (temporal layering)

**Setup**: User asks to implement multi-step feature

**User query**: "Help me implement OAuth authentication"

**Expected behavior**:
- Creates bd issue for OAuth feature (long-term tracking)
- Creates TodoWrite list for immediate execution steps (this session)
- Updates TodoWrite as work progresses (marks items completed)
- Updates bd notes at milestones, NOT per-todo
- Closes bd issue when feature complete

**Failure mode**: Using only bd OR only TodoWrite (not both), updating bd after every TodoWrite task

**Why this matters**: Tools serve different timescales. TodoWrite = working copy, bd = project journal.

---

## Evaluation Criteria Summary

| Scenario | Tests | Critical Failure Mode |
|----------|-------|----------------------|
| **Dependency Direction** | Semantics correctness | Backwards dependencies block wrong issues |
| **Session Start** | Proactive context | Waiting for user instead of establishing context |
| **Compaction Recovery** | Notes self-sufficiency | Asking user for context that's in notes |
| **Checkpointing** | Timing awareness | Losing context to crashes |
| **TodoWrite Integration** | Tool boundaries | Using wrong tool or wrong frequency |

---

## How to Use These Evaluations

1. **Before major skill changes**: Review relevant scenarios
2. **After skill refactoring**: Spot-check 2-3 scenarios
3. **When bugs reported**: Check if evaluation would have caught it, add new scenario if needed
4. **For new patterns**: Consider adding evaluation if pattern is fragile

These are behavioral checks, not automated tests. The goal is preventing regressions in critical skill behaviors.
