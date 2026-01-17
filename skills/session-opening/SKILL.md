---
name: session-opening
description: >
  Re-orient to session context on demand. Loads companion skills (beads, todoist-gtd)
  based on what's present. Use when you missed the startup context, want a fresh look
  at what's available, or after cd'ing to a different project.
  Triggers on /open, 'what were we working on', 'where did we leave off'.
  Pairs with /ground and /close. (user)
user-invocable: false
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

**Pattern: Notifications to stdout, content on disk.**

Hook output at session start shows what exists:
```
📋 Handoffs: 9 available, latest 23h ago
   Index: ~/.claude/.session-context/<encoded-cwd>/handoffs.txt
📦 Beads: 8 ready
   Context: ~/.claude/.session-context/<encoded-cwd>/beads.txt
📰 News: available
   File: ~/.claude/.update-news
```

**Context files are per-project.** The `<encoded-cwd>` is the working directory with `/` and `.` replaced by `-` (e.g., `-Users-modha-Repos-claude-suite`).

**To get actual content, read the files:**

| What | File |
|------|------|
| Handoff index | `~/.claude/.session-context/<encoded-cwd>/handoffs.txt` |
| Specific handoff | Path from index (e.g., `~/.claude/handoffs/.../9ac230b1.md`) |
| Beads context | `~/.claude/.session-context/<encoded-cwd>/beads.txt` |
| News | `~/.claude/.update-news` |

**To compute the path:** `echo "$(pwd -P)" | tr '/.' '-'` → use as subdirectory name.

### Missing or Stale Context

**If context files don't exist for current directory**, regenerate them:
```bash
~/.claude/scripts/open-context.sh
```

This happens when:
- Session started in a different directory (hook ran there, not here)
- First time in this project
- After cd'ing to a different project mid-session

**Check first:** `[ -d ~/.claude/.session-context/$(pwd -P | tr '/.' '-') ]`

### Script Failure Handling

**If the script fails (exit code 127 = file not found, or any other error):**

1. **STOP.** Do not continue with partial context.
2. **Tell the user:** "The open-context.sh script failed. This usually means a broken symlink."
3. **Diagnose:** Run `~/.claude/scripts/check-symlinks.sh` to identify the issue.

---

## 3. Orient

**Read files based on what notifications indicate, then synthesize.**

### Reading Pattern

First, compute the context directory:
```bash
CONTEXT_DIR=~/.claude/.session-context/$(pwd -P | tr '/.' '-')
```

Then read:
1. **Check handoff index** — read `$CONTEXT_DIR/handoffs.txt` (if missing, run `~/.claude/scripts/open-context.sh` first)
2. **Read most recent handoff** — path is in the index, read the actual `.md` file
3. **Check beads context** — read `$CONTEXT_DIR/beads.txt` for hierarchy + ready
4. **News if relevant** — read `~/.claude/.update-news` if user asks or it's actionable

### Synthesize What Matters

- **Handoff** — Done, Next, Gotchas from previous session
- **Beads hierarchy** — from beads.txt, show directly to user
- **Beads ready** — what's unblocked
- **Commands** — if handoff has a Commands section, offer to run them
- **Scope mismatches** — if handoff "Next" doesn't match ready beads, flag it

### Orphaned Local Handoffs

When stdout shows orphaned `.handoff*` files:

1. **Tell the user:** "Found local .handoff* files — these are invisible to /open"
2. **Offer to rescue:** "Want me to move them to the central location?"
3. **If yes:** `mv .handoff* ~/.claude/handoffs/<encoded-path>/`

### Multiple Handoffs

When handoff index shows multiple entries, present choices to user:

```
AskUserQuestion([{
  header: "Handoff",
  question: "Multiple handoffs found. Which workstream to continue?",
  options: [
    { label: "9ac230b1", description: "23h ago — Removed --local bypass..." },
    { label: "a6317919", description: "yesterday — Added raw_text to FTS..." },
    { label: "Start fresh", description: "Ignore existing handoffs" }
  ],
  multiSelect: false
}])
```

Then read the selected handoff file.

### Single Handoff (default)

Read the handoff, present concisely: "Previous session did X. Next suggested: Y. Z beads ready."

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

| Phase | /open | /close |
|-------|-------|--------|
| **G**ate | Load beads, offer todoist | — |
| **G**ather | Notifications (stdout) → Read files | Todos, beads, git, drift |
| **O**rient | "Where we left off" | Reflect (AskUserQuestion) |
| **D**ecide | User picks direction | Crystallize actions (STOP) |
| **A**ct | Draw-down → TodoWrite | Execute, handoff, commit |
| **R**emember | — | Captured in handoff |
