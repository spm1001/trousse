---
name: open
description: >
  Re-orient to session context on demand. Loads companion skills (arc, todoist-gtd)
  based on what's present. Use when you missed the startup context, want a fresh look
  at what's available, or after cd'ing to a different project.
  Triggers on /open, 'what were we working on', 'where did we leave off'.
  Pairs with /ground and /close. (user)
---

# /open

Interpret context and load companion skills.

## When to Use

**Session start context is now automatic.** The hook outputs a compact briefing (outcomes, last-worked zoom, handoff summary) that Claude should act on in the first response — no /open needed.

Use `/open` for:
- **Re-orientation** — "Show me the context again" (mid-session)
- **Skill loading** — Ensures arc/todoist-gtd patterns are available
- **After directory change** — Context is project-specific; if you cd'd, context may differ
- **Deeper dig** — When you need full handoff content or complete arc hierarchy beyond the briefing

## When NOT to Use

- Session just started and you can see the briefing (orient from it directly)
- Quick question that doesn't need full context
- When you already have clear direction from user

## Prerequisites

**Before running /open, verify infrastructure is healthy.** Silent failures here cause downstream confusion.

| Check | How | If Broken |
|-------|-----|-----------|
| open-context.sh exists | `[ -x ~/.claude/scripts/open-context.sh ]` | Run `claude-doctor.sh` |
| Script symlinks valid | `~/.claude/scripts/check-symlinks.sh` | Fix symlinks, see ERROR_PATTERNS.md |
| arc available | `command -v arc` | Install: see ~/Repos/arc |

**Quick pre-flight:**
```bash
[ -x ~/.claude/scripts/open-context.sh ] && echo "OK" || echo "BROKEN: open-context.sh missing"
```

If pre-flight fails, **STOP and diagnose** before proceeding. See `~/Repos/claude-suite/references/ERROR_PATTERNS.md` for common issues.

---

## Structure

```
Prerequisites → Verify infrastructure
Gate          → Load required companion skills
Gather        → Script output (already present from hook, or re-run if needed)
Orient        → Synthesize what matters
Decide        → User picks direction
Act           → Draw-down from Arc
```

---

## 1. Gate: Load Companion Skills

**Before synthesizing, load skills based on what's present.** Do not proceed until loaded.

| Condition | Action | Why |
|-----------|--------|-----|
| `.arc/` exists | `Skill(arc)` | Default tracker — outcomes and actions, GTD vocabulary |
| `.beads/` exists (no `.arc/`) | Suggest migration | Beads is deprecated — `arc migrate --from-beads .beads/` |
| Both `.arc/` and `.beads/` exist | Use arc only | Arc is authoritative |
| Neither exists | Skip tracker loading | No work tracker in this project |
| @Claude items in context OR Todoist in handoff | Offer `Skill(todoist-gtd)` | GTD framing, inbox check |
| User seems disoriented about past work | Offer `Skill(garde)` | Ancestral lookup |

**Work tracker is mandatory when present.** The draw-down pattern (item → `arc work` → `arc step`) is where drift gets caught. Tactical steps persist in `items.jsonl`, enforce serial execution, and survive session crashes.

- **Arc** is the default — outcomes and actions, simpler CLI, GTD vocabulary built-in
- **Beads** is deprecated — if `.beads/` exists without `.arc/`, suggest migration

**Todoist-gtd is conditional.** Offer it when relevant, don't load by default.

> **Skill loading bias (Jan 2026 learning):** Loading todoist-gtd primes Claude to think about "where work belongs" (Todoist vs arc). This caused misinterpretation in past sessions. When a tracker skill is loaded, stay anchored to the user's explicit tool references ("in arc", "the outcomes").

**Memory is optional.** Offer when user seems confused about history, not by default.

---

## 2. Gather

**Pattern: Compact briefing to stdout, detail on disk.**

The session-start hook outputs a synthesized briefing:
- Outcomes we're working towards (from arc)
- Last-worked zoom (current action and its tactical steps)
- Last session summary (Done, Next, Gotchas from latest handoff)

**Context files are per-project.** The `<encoded-cwd>` is the working directory with all non-alphanumeric characters replaced by `-` (e.g., `-Users-modha-Repos-claude-suite`).

**For deeper context, read the source files:**

| What | File |
|------|------|
| Latest handoff | `~/.claude/handoffs/<encoded-cwd>/` (most recent `.md` by mtime) |
| Arc context | `~/.claude/.session-context/<encoded-cwd>/arc.txt` |
| News | `~/.claude/.update-news` |

**To compute the path:** `echo "$(pwd -P)" | sed 's/[^a-zA-Z0-9-]/-/g'` → use as subdirectory name.

### Missing or Stale Context

**If context files don't exist for current directory**, regenerate them:
```bash
~/.claude/scripts/open-context.sh
```

This happens when:
- Session started in a different directory (hook ran there, not here)
- First time in this project
- After cd'ing to a different project mid-session

**Check first:** `[ -d ~/.claude/.session-context/$(pwd -P | sed 's/[^a-zA-Z0-9-]/-/g') ]`

### Script Failure Handling

**If the script fails (exit code 127 = file not found, or any other error):**

1. **STOP.** Do not continue with partial context.
2. **Tell the user:** "The open-context.sh script failed. This usually means a broken symlink."
3. **Diagnose:** Run `~/.claude/scripts/check-symlinks.sh` to identify the issue.

---

## 3. Orient

**Read files based on what notifications indicate, then synthesize.**

### Reading Pattern

Compute the encoded path, then read source files:
```bash
ENCODED=$(pwd -P | sed 's/[^a-zA-Z0-9-]/-/g')
```

Then:
1. **Read latest handoff** — `ls -t ~/.claude/handoffs/$ENCODED/*.md 2>/dev/null | head -1` (if empty, no prior sessions here)
2. **Check tracker context** — read `~/.claude/.session-context/$ENCODED/arc.txt` if it exists
3. **News if relevant** — read `~/.claude/.update-news` if user asks or it's actionable

### Synthesize What Matters

- **Handoff** — Done, Next, Gotchas from previous session
- **Tracker hierarchy** — from arc.txt, show directly to user
- **Ready work** — what's unblocked (arc ready)
- **Commands** — if handoff has a Commands section, offer to run them
- **Scope mismatches** — if handoff "Next" doesn't match ready items, flag it

> **CRITICAL: Output as text, not Bash.** When presenting tracker hierarchy or ready work, output it as text in your response. DO NOT run `arc list` via Bash — Claude Code collapses tool output >10 lines behind Ctrl+O, making it invisible to the user. The arc.txt file already contains formatted hierarchies; read it and output directly.

### Orphaned Local Handoffs

When stdout shows orphaned `.handoff*` files:

1. **Tell the user:** "Found local .handoff* files — these are invisible to /open"
2. **Offer to rescue:** "Want me to move them to the central location?"
3. **If yes:** `mv .handoff* ~/.claude/handoffs/<encoded-path>/`

### Handoff

The startup briefing already shows the latest handoff summary (Done, Next, Gotchas). For deeper detail, read the full handoff file.

Present concisely: "Previous session did X. Next suggested: Y. Z arc items ready."

---

## 4. Decide

User picks direction. Options typically:
- Continue with handoff "Next"
- Pick from ready work (arc items)
- @Claude inbox items
- Something else

---

## 5. Act: Draw-Down

**Draw-down triggers on ALL substantial work, not just explicit tracker item claims.**

### Explicit item selection

When user picks a work item:

| Tracker | Read item | Mark in progress |
|---------|-----------|------------------|
| **Arc** | `arc show <id>` | (arc doesn't track in_progress) |

Then:
1. Read the item's criteria (arc: brief.why/what/done)
2. Break down into steps from those criteria
3. Show user: "Breaking this down into: [list]. Sound right?"
4. Work through steps with explicit pauses for direction checks

### Continuation phrases

When user says "continue X", "keep going", "pick up where we left off":

1. **Clarify scope:** "Which item? Outcome (broad goal) or action (specific task)?"
2. Read the item's criteria
3. Break into steps — this catches scope gaps before work begins
4. Proceed with explicit pause points

**Failure mode (Jan 2026):** User said "continue backfill" → Claude continued existing code without checking epic scope → discovered an hour later that "complete pass" meant more than file attachments.

### External briefs

When user provides a spec, brief, or requirements from elsewhere:

1. Extract acceptance criteria from the brief
2. Break into steps from those criteria
3. Show user: "I'm reading this as: [list]. Right?"
4. Proceed with explicit pause points

**Failure mode:** User provided brief from another Claude → work completed → "fix" didn't work → second debugging phase had no clear checkpoints → drift.

### Ambiguous references

When user says "the email thing", "that feature", or similar:

1. **Don't guess.** Ask: "Do you mean item X (description) or Y (description)?"
2. Once clarified, do full draw-down

### The test

> If the work will take >10 minutes, it needs explicit breakdown and pause points.

**No checkpoints = Drift compounds.**

**Full draw-down patterns live in the tracker skill (arc)** — that's why gate-loading matters.

---

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Run `arc list` or `bd ready` via Bash | Output collapsed, user can't see it | Read context file, output as text |
| Skip draw-down on "continue X" | Scope ambiguity | Always read item, break into steps |
| Skip tracker skill loading | Missing workflow patterns | Gate-load arc first |
| Ignore script failures | Partial context, drift | STOP and diagnose if script fails |
| Guess at ambiguous references | Wrong work picked up | Ask user which item they mean |

## Mirrors (GODAR)

| Phase | /open | /close |
|-------|-------|--------|
| **G**ate | Load arc, offer todoist | — |
| **G**ather | Notifications (stdout) → Read files | Todos, arc, git, drift |
| **O**rient | "Where we left off" | Reflect (AskUserQuestion) |
| **D**ecide | User picks direction | Crystallize actions (STOP) |
| **A**ct | Draw-down from Arc | Execute, handoff, commit |
| **R**emember | — | Captured in handoff |
