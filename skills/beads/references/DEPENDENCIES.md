# Dependency Types Guide

bd's four dependency types: blocks, related, parent-child, and discovered-from.

## Contents

- [Overview](#overview)
- [blocks - Hard Blocker](#blocks---hard-blocker)
- [related - Soft Link](#related---soft-link)
- [parent-child - Hierarchical](#parent-child---hierarchical)
- [discovered-from - Provenance](#discovered-from---provenance)
- [Decision Guide](#decision-guide)
- [Common Mistakes](#common-mistakes)
- [Advanced Patterns](#advanced-patterns)
- [Summary](#summary)

## Overview

| Type | Purpose | Affects `bd ready`? | Common Use |
|------|---------|---------------------|------------|
| **blocks** | Hard blocker | Yes - blocked issues excluded | Sequential work, prerequisites |
| **related** | Soft link | No - just informational | Context, related work |
| **parent-child** | Hierarchy | No - structural only | Epics and subtasks |
| **discovered-from** | Provenance | No - tracks origin | Side quests, research findings |

Only `blocks` affects what work is ready. The other three provide structure and context.

---

## blocks - Hard Blocker

**Semantics**: Issue A blocks issue B. B cannot start until A is complete.

**Effect**: B disappears from `bd ready` until A is closed.

### When to Use

Use `blocks` when work literally cannot proceed:

- Prerequisites: Database schema before endpoints
- Sequential steps: Migration phases in order
- Build dependencies: Foundation before features
- Technical blockers: Library before code

### When NOT to Use

- Soft preferences ("should do X before Y but could do either")
- Parallel work (both can proceed independently)
- Mere relationships (use `related`)
- Recommendations (use `related` or notes)

### Examples

```
db-schema-1: "Create users table"
  blocks api-endpoint-2: "Add GET /users endpoint"
# Endpoint needs table to exist

migrate-1: "Backup production database"
  blocks migrate-2: "Run schema migration"
  blocks migrate-3: "Verify data integrity"
# Sequential pipeline; bd ready shows only current step

setup-1: "Install JWT library"
  blocks auth-2: "Implement JWT validation"
# Code needs library
```

### Creating blocks Dependencies

**CRITICAL**: Syntax is INVERTED from intuition!

**CLI**: `bd dep add DEPENDENT PREREQUISITE`
```bash
bd dep add api-endpoint db-schema
# api-endpoint depends on db-schema (db-schema blocks api-endpoint)
```

**MCP**: `mcp__plugin_beads_beads__dep`
```json
{
  "from_issue": "blocked-issue",
  "to_issue": "prerequisite-issue",
  "type": "blocks"
}
```

**Direction**: `from_issue` depends on `to_issue`. The thing that WAITS goes first.

**Verify**: `bd show blocked-issue` should list prerequisite under "Dependencies (blocks this issue)". If it's under "Dependents" instead, direction is backwards.

### Common Patterns

```
# One foundation blocks multiple features
foundation-1 blocks feature-2, feature-3, feature-4

# Sequential pipeline
step-1 blocks step-2 blocks step-3 blocks step-4
# bd ready shows only current step

# Parallel then merge
research-1, research-2, research-3 all block decision-4
# All research must complete before decision
```

**Automatic unblocking**: Closing a blocking issue automatically updates `bd ready` to show newly unblocked work.

---

## related - Soft Link

**Semantics**: Issues are related but neither blocks the other.

**Effect**: No impact on `bd ready`. Informational only.

### When to Use

- Similar work (same problem, different angles)
- Shared context (insight transfer)
- Alternative approaches
- Complementary features (work well together but not required)

### Examples

```
refactor-1: "Extract validation logic"
  related to refactor-2: "Extract error handling logic"
# Similar patterns, independent work

feature-1: "Add OAuth login"
  related to docs-2: "Document OAuth setup"
# Connected but any order

perf-1: "Investigate Redis caching"
  related to perf-2: "Investigate CDN caching"
# Alternative approaches, explore both
```

### Creating

```bash
bd dep add issue-1 issue-2 --type related
```

**Direction doesn't matter** - symmetric link.

---

## parent-child - Hierarchical

**Semantics**: Issue A is parent of issue B (typically epic/subtask).

**Effect**: No impact on `bd ready`. Structural only.

### When to Use

- Epics and subtasks (breaking down large work)
- Hierarchical organization
- Progress tracking
- Work breakdown structure

### Examples

```
oauth-epic: "Implement OAuth integration"
  parent of:
    - oauth-1: "Set up OAuth credentials"
    - oauth-2: "Implement authorization flow"
    - oauth-3: "Add token refresh"
    - oauth-4: "Create login UI"
# All show in bd ready unless blocked
```

### Creating

```bash
bd dep add parent-epic-id child-task-id --type parent-child
```

**Direction matters**: `from_id` is parent, `to_id` is child.

### Finding Children

**To find children of an epic:**

```bash
# Recommended: direct filter
bd list --parent <epic-id>

# Alternative: query dependents
bd dep list <epic-id> --direction up --type parent-child
```

**Anti-pattern:** `bd dep tree <epic>` shows **blockers**, not children. Use `bd dep tree <epic> --direction up --type parent-child` for hierarchy.

**Why "direction up"?** Children depend on parents in bd's model. "Up" = "what depends on me" = children.

### Combining with blocks

```
auth-epic (parent of all)
  ├─ auth-1: "Install library"
  ├─ auth-2: "Create middleware" (blocked by auth-1)
  ├─ auth-3: "Add endpoints" (blocked by auth-2)
  └─ auth-4: "Add tests" (blocked by auth-3)

# parent-child for structure, blocks for ordering
```

---

## discovered-from - Provenance

**Semantics**: Issue B was discovered while working on issue A.

**Effect**: No impact on `bd ready`. Tracks origin.

### When to Use

- Side quests found during implementation
- Research findings
- Bugs found during feature work
- Follow-up work identified during current work

**Value**: Preserves context for understanding why issue was created and whether it's still relevant.

### Examples

```
feature-10: "Add user profiles"
  discovered-from → bug-11: "Auth doesn't handle profile permissions"
# Context: Bug revealed by feature work

research-5: "Investigate caching options"
  discovered-from →
    finding-6: "Redis supports persistence"
    finding-7: "CDN incompatible with auth"
    decision-8: "Choose Redis"
# Findings branch from research

refactor-20: "Extract validation logic"
  discovered-from →
    debt-21: "Validation inconsistent"
    debt-22: "No edge case validation"
# Refactoring revealed debt
```

### Creating

```bash
bd dep add original-work-id discovered-issue-id --type discovered-from
```

**Direction matters**: `to_id` was discovered while working on `from_id`.

### Combining with blocks

```
feature-10 discovered-from → bug-11 blocks → feature-10
# Found bug during feature work, bug now blocks feature
```

---

## Decision Guide

```
Does A prevent B from starting? → blocks
Is B a subtask of A? → parent-child
Was B discovered while working on A? → discovered-from
Are A and B just related? → related
```

| Situation | Use |
|-----------|-----|
| B needs A complete to start | blocks |
| B is part of A (epic/task) | parent-child |
| Found B while working on A | discovered-from |
| A and B similar/connected | related |
| A and B alternatives | related |

---

## Common Mistakes

### Using blocks for Preferences

Wrong: `docs blocks feature` with reason "prefer docs first"

Problem: Docs don't actually block feature. Use `related` or notes instead.

### Using discovered-from for Planning

Wrong: `epic discovered-from → task` for planned decomposition

Problem: `discovered-from` is for emergent discoveries, not planning. Use `parent-child`.

### Not Using Dependencies

Long flat issue list with no structure = can't tell what's blocked, what's related.

Solution: Group (parent-child), order (blocks), link (related), track discovery (discovered-from).

### Over-Using blocks

Everything in strict sequence = no parallel work, `bd ready` shows only one issue.

Only use `blocks` for actual technical dependencies.

### Wrong Direction

Wrong: `bd dep add api-endpoint db-schema` means api-endpoint blocks db-schema (backwards!)

Right: `bd dep add db-schema api-endpoint` means db-schema blocks api-endpoint

Remember: Thing that WAITS goes first.

---

## Advanced Patterns

```
# Diamond: setup blocks both impl-a and impl-b, both block testing
        setup
       /    \
   impl-a  impl-b
       \    /
       testing

# Discovery cascade: research generates findings, findings generate deeper findings
research-main
  discovered-from → finding-1
  discovered-from → finding-2
    discovered-from → deep-finding-3

# Epic with phases: nested hierarchy + phase ordering
auth-epic
  parent of phase-1-epic (blocks phase-2-epic)
    parent of: setup-1, setup-2
  parent of phase-2-epic (blocks phase-3-epic)
    parent of: implement-1, implement-2
```

---

## Summary

1. **blocks**: Sequential work, prerequisites - affects `bd ready`
2. **related**: Context and connections - informational only
3. **parent-child**: Epics and subtasks - structural only
4. **discovered-from**: Side quests and findings - tracks origin

Only `blocks` affects what work is ready. Others provide context without constraining execution.

Dependencies create a graph that maintains ready work, preserves discovery context, shows structure, and survives compaction.
