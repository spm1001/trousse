---
name: session-grounding
description: >
  Mid-session checkpoint when things feel squiffy. Anchor to what matters, reset for the second half.
  Triggers on /ground, 'let's take stock', 'where are we'. **Claude should proactively offer this**
  when user seems lost, TodoWrite is stale, or drift is visible. Pairs with /open and /close. (user)
---

# /ground

Halftime. Context partially spent, insights accumulated, drift may have crept in.

**Claude-initiated:** Don't wait for `/ground` — offer it when you sense:
- User seems confused or lost ("wait, what were we doing?")
- TodoWrite items stale (in_progress but untouched)
- Conversation drifted visibly from stated goal
- Context ~50% used (halftime)
- Momentum stalled, energy off

## Structure

```
Gather  → todos, beads, drift detection
Orient  → "here's what we've done vs what we said"
Decide  → continue, adjust, or pivot
Act     → update beads notes, reset todos
```

---

## Pre-flight: Return Home (MANDATORY)

You may have `cd`'d during work. Your system prompt contains `Working directory: /path/...` in the `<env>` block — this is immutable, where the session actually started.

1. Extract that exact path from your system prompt
2. Run: `~/.claude/scripts/check-home.sh "/that/path"`
3. If `CD_REQUIRED=true`, run `cd <HOME_DIR>` immediately

**Do not skip. Do not trust pwd. Do not reason about whether you moved back. The script is authoritative.**

---

## 1. Gather

Quick time check (for greetings and year awareness):
```bash
date '+%Y-%m-%d %H:%M (%A)'
```

**Gate check:** If `.beads/` exists and beads skill not yet loaded:
```
Skill(beads)
```
This ensures workflow patterns are available for pivot decisions.

**Show the beads hierarchy** (epics → children, standalone items):
```bash
~/.claude/scripts/open-context.sh 2>/dev/null | sed -n '/=== BEADS_HIERARCHY/,/===/p' | head -40
```
This is "prestidigitation easier with code" — the script computes the tree, don't reconstruct it manually.

Check current state:

- **TodoWrite** — what's done, what's in_progress, what's stale?
- **Beads** — `bd list --status in_progress` — still accurate?
- **Drift** — compare to /open (or previous /ground) orientation:
  - What did we say we'd do?
  - What did we actually do?
  - Any side quests that became main quests?

**If no prior /open ran this session:** Skip drift detection — there's no baseline. Instead, ask user: "No /open orientation to compare against. What were you working toward?" This becomes the baseline for remainder of session.

No full script needed — this is conversational review.

---

## 2. Orient

Articulate the gap:

> "We started with [X from /open]. We've done [Y]. We drifted into [Z] because [reason]."

Be honest about drift. Side quests are fine — just name them.

Surface what's accumulated:
- Insights worth capturing
- Questions that emerged
- Decisions that got made implicitly

---

## 3. Decide

Three options:

1. **Continue** — we're on track, keep going
2. **Adjust** — update TodoWrite to reflect actual direction
3. **Pivot** — this side quest is now the main quest; update beads accordingly

User decides. If they're unsure, help them articulate what feels off.

---

## 4. Act

Based on decision:

**If continuing:**
- Update beads notes with progress checkpoint
- Trim stale TodoWrite items

**If adjusting:**
- Rewrite TodoWrite to match actual work
- Update beads notes with what changed and why

**If pivoting:**
- Create/update beads for new direction
- Note the original work as paused (not abandoned)
- Fresh draw-down for new focus

**Always:** Write beads notes as if context might vanish. This is your crash recovery checkpoint.

---

## 5. Memory Lookup (Optional)

After tactical drift check, offer ancestral memory search if relevant.

**When to offer:**
- Topic has likely history beyond current session
- User seems uncertain about past decisions
- Drift check revealed possible connection to prior work

**How to offer:**
> "Checked drift — we're [on track / drifted into X]. Want to search ancestral memory for context on [topic]?"

**If user says yes:**
1. **Invoke the `memory` skill** for search → triage → drill workflow
2. Synthesize findings with current context
3. Cross-reference with beads state if relevant

**If user declines:**
- Continue with tactical adjustments from Phase 4
- Memory lookup is purely optional enhancement

---

## When to /ground (or offer it)

**User-initiated:**
- User says "wait, where are we?" or "let's take stock"
- User explicitly runs `/ground`

**Claude-initiated (proactive):**
- Things feel "squiffy" — can't articulate why, but momentum is off
- Natural pause point — finished a chunk, about to start another
- Context is ~50% used — halftime
- TodoWrite has stale items (in_progress but forgotten)
- User seems confused about what they were doing

**How to offer:** "We've been at this a while and I'm sensing some drift. Want to do a quick /ground check?"

Don't overuse. If momentum is good, keep going.

---

## Mirrors (GODAR)

| Phase | /open | /ground | /close |
|-------|-------|---------|--------|
| **G**ather | Handoff, beads, script | Todos, beads, drift | Todos, beads, git, drift |
| **O**rient | "Where we left off" | "What's drifted" | Reflect (AskUserQuestion) |
| **D**ecide | User picks direction | Continue or adjust | Crystallize actions (STOP) |
| **A**ct | Draw-down → TodoWrite | Update beads, reset | Execute, handoff, commit |
| **R**emember | — | Optional: memory skill | Captured in handoff |

---

## See Also

**Memory vs Session-Grounding:** If you're unsure which skill to use, see the decision tree in the `memory` skill. Key distinction: `/ground` checks drift within THIS session; `memory` searches PAST sessions.
