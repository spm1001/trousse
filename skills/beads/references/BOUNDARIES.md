# Boundaries: When to Use bd vs TodoWrite

Decision criteria for choosing between bd issue tracking and TodoWrite.

## Contents

- [The Core Question](#the-core-question)
- [Decision Matrix](#decision-matrix)
- [Integration Patterns](#integration-patterns)
- [Real-World Examples](#real-world-examples)
- [Common Mistakes](#common-mistakes)
- [The Transition Point](#the-transition-point)
- [Summary Heuristics](#summary-heuristics)

## The Core Question

**"Could I resume this work after 2 weeks away?"**

- If bd would help resume → **use bd**
- If markdown skim suffices → **TodoWrite is fine**

## Decision Matrix

### Use bd for:

**Multi-Session Work** - Spans multiple days/sessions where context must persist
- Strategic documents, split features, bug investigations

**Complex Dependencies** - Blockers, prerequisites, hierarchical structure
- OAuth integration, research threads, sequential migrations
- Why: `bd ready` automatically surfaces unblocked work

**Knowledge Work** - Fuzzy boundaries, exploration, evolving understanding
- Architecture decisions, API design, performance optimization
- Why: `design` and `acceptance_criteria` capture evolving understanding

**Side Quests** - Discoveries that might pause main work
- Better patterns found during implementation, architectural improvements
- Why: `discovered-from` preserves context for both tracks

**Project Memory** - Resume after significant gaps with full context
- Open source contributions, part-time projects, long investigations
- Why: Git-backed, survives compaction

### Use TodoWrite for:

**Single-Session Tasks** - Completes within current conversation
- Single function implementation, bug fix with known cause, unit tests

**Linear Execution** - Straightforward steps, no branching
- Database migrations, deployment checklists, code cleanup

**Immediate Context** - All information in current conversation
- Complete spec provided, bug with repro steps, clear refactoring

**Simple Tracking** - Show progress to user
- Break down implementation, demonstrate systematic approach
- Why: Visible in conversation, not background structure

## Comparison

| Aspect | bd | TodoWrite |
|--------|-----|-----------|
| **Persistence** | Git-backed, survives compaction | Session-only |
| **Dependencies** | Graph-based, auto ready detection | Manual |
| **Complexity** | Nested epics, blockers | Flat list |
| **Visibility** | Background | Visible in chat |
| **Best for** | Multi-session, explorative | Single-session, linear |

## Integration Patterns

### Pattern 1: bd as Strategic, TodoWrite as Tactical

bd tracks high-level issues/dependencies, TodoWrite tracks current session execution.

```
bd: "Implement user authentication" (epic)
  ├─ "Create login endpoint"
  ├─ "Add JWT validation" ← Currently working
  └─ "Implement logout"

TodoWrite (JWT validation):
- [ ] Install JWT library
- [ ] Create middleware
- [ ] Add tests
```

Use when: Complex features with clear implementation steps, user wants progress visibility.

### Pattern 2: TodoWrite as Working Copy

Extract TodoWrite from bd issue's acceptance criteria, update bd with learnings.

Use when: bd issue ready but execution straightforward, need structured approach.

### Pattern 3: Transition Mid-Session

**TodoWrite → bd** when complexity emerges:
- Discovering blockers/dependencies
- Won't complete this session
- Side quests found
- Need to pause/resume later

**bd → TodoWrite** (rare) when issue simpler than expected:
- All context clear, no dependencies, completes within session

## Real-World Examples

### Database Migration Planning - Use bd

Multi-session work, fuzzy boundaries, side quests (schema incompatibilities), dependencies (schema before migration).

```
db-epic: "Migrate to PostgreSQL"
  ├─ db-1: "Audit MySQL schema"
  ├─ db-2: "Research PostgreSQL equivalents" (blocks db-3)
  ├─ db-3: "Design PostgreSQL schema"
  └─ db-4: "Create migration scripts" (blocked by db-3)
```

TodoWrite role: Might use for single-session testing once scripts ready.

### Simple Feature - Use TodoWrite

Single session, linear execution, all context in conversation.

```
- [ ] Import logging library
- [ ] Add log statements
- [ ] Add test
- [ ] Run tests
```

### Bug Investigation - Transition from TodoWrite to bd

Started TodoWrite for simple bug fix. Discovered intermittent race condition with multiple potential causes. Transition to bd for multi-session investigation with hypothesis tracking.

### Refactoring with Dependencies - Use bd

Dependencies (extract before updating callers), multi-file coordination, need to track which controllers updated.

```
refactor-1: "Create shared validation" blocks refactor-2, 3, 4
refactor-2: "Update auth controller"
refactor-3: "Update user controller"
refactor-4: "Update payment controller"
```

bd ensures no controllers forgotten. TodoWrite could track individual controller updates during execution.

## Common Mistakes

### Using TodoWrite for Multi-Session Work

Problem: Next session, forget context, lose design decisions.

Solution: Use bd to persist context.

### Using bd for Simple Tasks

Problem: Overhead not justified, user can't see progress.

Solution: Use TodoWrite for single-session linear work.

### Not Transitioning When Complexity Emerges

Problem: Start TodoWrite, discover blockers mid-way, lose context at session end.

Solution: Transition to bd when complexity signals appear.

### Creating Too Many bd Issues

Problem: Every tiny task gets issue, cluttered database, hard to find meaningful work.

Solution: Use "2 week test" - would bd help resume after 2 weeks? If no, skip it.

### When to Create Issues Directly vs Ask First

**Create directly** (no question needed):
- Bug reports with clear scope
- Research tasks
- Technical TODOs discovered during implementation
- Side quest capture

Why: Asking slows discovery capture.

**Ask first**:
- Strategic work (fuzzy boundaries, multiple approaches)
- Potential duplicates
- Large epics with unclear scope
- Major scope changes

Why: Ensures alignment, prevents duplicate effort.

**Rule**: Clear one-sentence issue = create directly. Need user input to clarify = ask first.

## The Transition Point

**"This looks straightforward"** → TodoWrite

**As work progresses:**
- ✅ Stays straightforward → Continue TodoWrite
- ⚠️ Complexity emerges → Transition to bd

**Transition signals:**
- Taking longer than expected
- Discovered blocker
- Needs more research
- Should pause and investigate X first
- User might not be available to continue
- Found multiple related issues

**Action**: Create bd issue, preserve context, work from structured foundation.

## Summary Heuristics

| Factor | TodoWrite | bd |
|--------|-----------|-----|
| **Time** | Same session | Multiple sessions |
| **Structure** | Linear steps | Blockers/prerequisites |
| **Scope** | Well-defined | Exploratory |
| **Context** | In conversation | External/evolving |
| **Visibility** | User watching | Background |
| **Resume** | Easy from markdown | Need structured history |

**When in doubt**: Use the 2-week test. If you'd struggle to resume after 2 weeks without bd, use bd.
