---
name: session-opening
description: >
  Re-orient to session context on demand. Loads companion skills (beads, todoist-gtd)
  based on what's present. Use when you missed the startup context, want a fresh look
  at what's available, or after cd'ing to a different project.
  Triggers on /open, 'what were we working on', 'where did we leave off'.
  Pairs with /ground and /close. (user)
---

# /open

Interpret context and load companion skills.

## When to Use

**Context is surfaced automatically at session start via hook.** The hook provides data; this skill provides behavior.

Use `/open` for:
- **Re-orientation** — "Show me the context again"
- **Skill loading** — Ensures beads/todoist-gtd patterns are available
- **After directory change** — Context is project-specific; if you cd'd, context may differ

## Prerequisites

**Before running /open, verify infrastructure is healthy.** Silent failures here cause downstream confusion.

| Check | How | If Broken |
|-------|-----|-----------|
| open-context.sh exists | `[ -x ~/.claude/scripts/open-context.sh ]` | Run `claude-doctor.sh` |
| Script symlinks valid | `~/.claude/scripts/check-symlinks.sh` | Fix symlinks, see ERROR_PATTERNS.md |
| bd available (if .beads/) | `command -v bd` | Install: `brew install bd` |

**Quick pre-flight:**
```bash
[ -x ~/.claude/scripts/open-context.sh ] && echo "OK" || echo "BROKEN: open-context.sh missing"
```

If pre-flight fails, **STOP and diagnose** before proceeding. See `~/Repos/claude-advanced/references/ERROR_PATTERNS.md` for common issues.

---

## Structure

```
Prerequisites → Verify infrastructure
Gate          → Load required companion skills
Gather        → Script output (already present from hook, or re-run if needed)
Orient        → Synthesize what matters
Decide        → User picks direction
Act           → Draw-down to TodoWrite
```

---

## 1. Gate: Load Companion Skills

**Before synthesizing, load skills based on what's present.** Do not proceed until loaded.

| Condition | Action | Why |
|-----------|--------|-----|
| `.beads/` exists | `Skill(beads)` | Draw-down patterns, bead lifecycle |
| @Claude items in context OR Todoist in handoff | Offer `Skill(todoist-gtd)` | GTD framing, inbox check |
| User seems disoriented about past work | Offer `Skill(memory)` | Ancestral lookup |

**Beads is mandatory when present.** The draw-down pattern (bead → TodoWrite checkpoints) is where drift gets caught. Without it, Claude works from bead directly → no checkpoints → drift compounds.

**Todoist-gtd is conditional.** Offer it when relevant, don't load by default.

> **Skill loading bias (Jan 2026 learning):** Loading todoist-gtd primes Claude to think about "where work belongs" (Todoist vs bd). This caused misinterpretation when user said "refactor beads into proper epics" — Claude proposed moving to Todoist instead of organizing within bd. When todoist-gtd is loaded, stay anchored to the user's explicit tool references ("the beads", "in bd").

**Memory is optional.** Offer when user seems confused about history, not by default.

---

## 2. Gather

Context comes from hook output (already in your context at session start).

If re-orienting mid-session or after cd:
```bash
~/.claude/scripts/open-context.sh
```

Outputs: TIME, HANDOFF, BEADS (ready + recently closed), UPDATE_NEWS, TODOIST prompt.

### Script Failure Handling

**If the script fails (exit code 127 = file not found, or any other error):**

1. **STOP.** Do not continue with partial context.
2. **Tell the user:** "The open-context.sh script failed. This usually means a broken symlink."
3. **Diagnose:** Run `~/.claude/scripts/check-symlinks.sh` to identify the issue.
4. **Fix before continuing:** The script provides critical context — proceeding without it means missing handoffs, beads, and update news.

**Why this matters:** Silent script failures caused 54 sessions to run without context (Jan 3-10 2026). The /open felt "janky" but continued anyway. Never repeat this.

---

## 3. Orient

Synthesize what matters from context:

- **Handoff** — Done, Next, Gotchas from previous session
- **Beads hierarchy** — show the `BEADS_HIERARCHY` block directly, don't re-summarize it. The pre-computation happened so you wouldn't have to interpret.
- **Beads ready** — what's unblocked
- **Commands** — if handoff has a Commands section, offer to run them
- **Update news** — if actionable items (e.g., `bd upgrade review`, `gh release view`), offer them
- **Scope mismatches** — if handoff "Next" doesn't match `bd ready`, flag it

### Orphaned Local Handoffs

When `ORPHANED_HANDOFFS=true` in script output:

1. **Tell the user:** "Found local .handoff* files — these are invisible to /open"
2. **Offer to rescue:** "Want me to move them to the central location so /open can find them?"
3. **If yes:** `mv .handoff* ~/.claude/handoffs/-Users-modha-Repos-<project>/`

**Why this matters (Jan 2026):** Some Claudes wrote handoffs locally instead of centrally. These contained valuable context but were invisible — /open showed stale handoffs instead.

### Multiple Handoffs

When `HANDOFF_MULTIPLE=true` in script output, multiple sessions have written handoffs to this folder. The script shows a picker list like:

```
  1. 51d17dc5 · 42m ago
     MIT Contract Stewardship work

  2. a3f82b1c · 3h ago
     DCMS RFI response drafting
```

**Present this to user and ask which to continue.** Don't assume most recent is correct — parallel sessions may have different workstreams.

Use AskUserQuestion:
```
AskUserQuestion([{
  header: "Handoff",
  question: "Multiple handoffs found. Which workstream to continue?",
  options: [
    { label: "1. MIT Contract...", description: "42 minutes ago" },
    { label: "2. DCMS RFI...", description: "3 hours ago" },
    { label: "Start fresh", description: "Ignore existing handoffs" }
  ],
  multiSelect: false
}])
```

The script still shows the most recent handoff content as default — if user confirms that one, no re-read needed.

### Single Handoff (default)

Present concisely: "Previous session did X. Next suggested: Y. Z beads ready. Any @Claude items."

---

## 4. Decide

User picks direction. Options typically:
- Continue with handoff "Next"
- Pick from ready beads
- @Claude inbox items
- Something else

---

## 5. Act: Draw-Down

**Draw-down triggers on ALL substantial work, not just explicit bead claims.**

### Explicit bead selection

When user picks a bead to work on:

1. `bd show <bead-id> --json` — read design and acceptance criteria
2. Create TodoWrite items from acceptance criteria
3. Show user: "Breaking this down into: [list]. Sound right?"
4. Mark bead in_progress: `bd update <id> --status in_progress`

### Continuation phrases

When user says "continue X", "keep going", "pick up where we left off":

1. **Clarify scope:** "Which bead? Epic nzr (broad goal) or subtask nzr.1 (specific task)?"
2. Read the bead's acceptance criteria
3. Create TodoWrite items — this catches scope gaps before work begins
4. Proceed with checkpoints

**Failure mode (Jan 2026):** User said "continue backfill" → Claude continued existing code without checking epic scope → discovered an hour later that "complete pass" meant more than file attachments.

### External briefs

When user provides a spec, brief, or requirements from elsewhere:

1. Extract acceptance criteria from the brief
2. Create TodoWrite items from those criteria
3. Show user: "I'm reading this as: [list]. Right?"
4. Proceed with checkpoints

**Failure mode:** User provided brief from another Claude → work completed → "fix" didn't work → second debugging phase had no TodoWrite → drift.

### Ambiguous references

When user says "the email thing", "that feature", or similar:

1. **Don't guess.** Ask: "Do you mean bead X (description) or Y (description)?"
2. Once clarified, do full draw-down

### The test

> If the work will take >10 minutes, it needs TodoWrite items.

**No TodoWrite items = No checkpoints = Drift compounds.**

**Full draw-down patterns live in the beads skill** — that's why gate-loading it matters.

---

## Mirrors (GODAR)

| Phase | /open | /ground | /close |
|-------|-------|---------|--------|
| **G**ate | Load beads, offer todoist | Load beads if not loaded | — |
| **G**ather | Hook output (or script) | Todos, beads, drift | Todos, beads, git, drift |
| **O**rient | "Where we left off" | "What's drifted" | Reflect (AskUserQuestion) |
| **D**ecide | User picks direction | Continue or adjust | Crystallize actions (STOP) |
| **A**ct | Draw-down → TodoWrite | Update beads, reset | Execute, handoff, commit |
| **R**emember | — | Optional: memory skill | Captured in handoff |
