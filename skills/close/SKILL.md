---
name: close
description: End-of-session ritual. Use when session is ending — context nearly full, work complete, or user says 'wrap up'. Triggers on /close, 'wrap up', 'let's finish'. Pairs with /open. (user)
---

# /close

Capture learnings while context is rich, then commit and exit.

## When to Use

- Session ending naturally (work complete)
- Context window nearly full
- User says "wrap up", "let's finish", "one more thing then done"
- Main task complete and about to summarize

## When NOT to Use

- Mid-session checkpoint (pause and check direction instead)
- Quick question that doesn't need handoff
- Exploratory work with no conclusions yet

## Structure

```
Prerequisites → Verify infrastructure
Pre-flight    → Return to home directory
Gather        → todos, tracker (bon), git, drift
Orient        → Claude observes → User co-reflects → Claude answers
Decide        → crystallize actions (STOP — present before executing)
Act           → execute, write handoff, commit, clear todos
Remember      → index session (background)
```

---

## Prerequisites

**Before running /close, verify infrastructure is healthy.** Broken scripts mean lost handoffs.

| Check | How | If Broken |
|-------|-----|-----------|
| close-context.sh exists | `[ -x ~/.claude/scripts/close-context.sh ]` | Run `claude-doctor.sh` |
| check-home.sh exists | `[ -x ~/.claude/scripts/check-home.sh ]` | Fix symlinks |
| Handoffs dir writable | `[ -d ~/.claude/handoffs ]` | Create: `mkdir -p ~/.claude/handoffs` |

**Quick pre-flight:**
```bash
[ -x ~/.claude/scripts/close-context.sh ] && [ -x ~/.claude/scripts/check-home.sh ] && echo "OK" || echo "BROKEN"
```

If broken: **STOP, diagnose, then write handoff manually** rather than skipping closure entirely. See `~/Repos/trousse/references/ERROR_PATTERNS.md`.

---

## Pre-flight: Return Home (MANDATORY)

You may have `cd`'d during work. Your system prompt contains `Working directory: /path/...` in the `<env>` block — this is immutable, where the session actually started.

1. Extract that exact path from your system prompt
2. Run: `~/.claude/scripts/check-home.sh "/that/path"`
3. If `CD_REQUIRED=true`, run `cd <HOME_DIR>` immediately

**Do not skip. Do not trust pwd. Do not reason about whether you moved back. The script is authoritative.**

---

## Gather

```bash
~/.claude/scripts/close-context.sh
```

Script outputs: TIME, GIT, BON, LOCATION context.

Use TIME_OF_DAY for greetings. Use YEAR to anchor the handoff date.

### Script Failure Handling

**If the script fails (exit code 127 = file not found, or any error):**

1. **STOP.** Tell the user: "close-context.sh failed. Likely a broken symlink."
2. **Diagnose:** Run `~/.claude/scripts/check-symlinks.sh`
3. **Fallback:** If you can't fix it, write handoff manually to `~/.claude/handoffs/<encoded-path>/` — don't skip closure entirely.

**Why this matters:** Broken scripts (Jan 3-10 2026) meant /close ran without proper context gathering. Never continue silently.

From script output, assess:

- **Work progress** — what's done, what's incomplete? (incomplete items surface in Decide)
- **Tracker** — Bon: open items to complete or defer
- **Git** — UNCOMMITTED files? UNPUSHED commits?
- **Drift** — what did /open say we'd do vs what we did?

Surface stale artifacts: screenshots, temp files, old sketches, superseded plans.

---

## Orient

**This is THE reflection — complete it here.** What emerges in Orient feeds into the handoff. There is no second reflection later.

Orient has three beats. All three must complete before moving to Decide.

### Claude shares observations

**Anti-pattern: Don't compress reflection into multiple-choice answers.** The point is surfacing what YOU (Claude) noticed that the user might not have. Pre-baked options defeat this.

Share your observations directly:

> "Before we wrap up, here's what stood out to me this session:
> - [specific observation about the work]
> - [pattern or connection you noticed]
> - [something that felt unfinished or risky]
>
> What resonates? What am I missing?"

### User co-reflects + selects ritual

Immediately after sharing observations, present a combined AskUserQuestion. This captures which deeper reflections you should answer:

```
AskUserQuestion([
  {
    header: "Looking Back",
    question: "Which backward reflections should I answer?",
    multiSelect: true,
    options: [
      { label: "All of these", description: "Full retrospective" },
      { label: "What did we forget?", description: "Dropped intentions" },
      { label: "What did we miss?", description: "Blind spots" },
      { label: "What could we have done better?", description: "Quality gaps" }
    ]
  },
  {
    header: "Looking Ahead",
    question: "Which forward reflections should I answer?",
    multiSelect: true,
    options: [
      { label: "All of these", description: "Full prospective" },
      { label: "What could go wrong?", description: "Risks, fragile bits" },
      { label: "What won't make sense later?", description: "Clarity gaps" },
      { label: "What will we wish we'd done?", description: "Missed opportunities" }
    ]
  }
])
```

Option 3 ("Type something") for either question provides free text input.

### Claude answers selected questions

**Orient is not complete until this step finishes.** Respond to the selected Looking Back/Looking Ahead questions genuinely — the user's selection transforms them into real asks, not template following.

Don't rush this. The reflection is where value compounds.

---

## Decide

**STOP.** Do not proceed to Act without completing this phase.

From Gather + Orient, crystallize actions into two buckets.

### Surfacing incomplete work

**Before presenting options, identify incomplete work from the session.** Any unfinished task must appear in the Decide AskUserQuestion — either as a "Now" option (finish it) or "Next" option (create tracker item). Don't silently drop work.

### Now vs Next

**Now** = actions that execute immediately, benefiting from current context:
- Incomplete todos that can be finished quickly
- Close a tracker item with resolution notes (context makes notes better)
- Update CLAUDE.md — Local (./CLAUDE.md) or Global (~/.claude/CLAUDE.md)
- Quick fixes (< 2 minutes, obvious how)

**Next** = deferrals that create work for a future session:
- Incomplete todos that need dedicated time
- Create a tracker item (by definition, you're deferring it)
- Anything needing "fresh thinking"
- Anything you're uncertain how to approach

**The test:** If it creates something for later, it's Next. If it completes something now, it's Now.

```
AskUserQuestion([
  {
    header: "Now",
    question: "Execute now while context is fresh?",
    multiSelect: true,
    options: [
      // Adapt to actual session:
      // - Include incomplete work as options
      // - Include CLAUDE.md updates when insights emerged
      { label: "Finish [incomplete work]", description: "Can complete quickly" },
      { label: "Close [item-id]", description: "Add resolution notes" },
      { label: "Update Local CLAUDE.md", description: "Project-specific pattern" },
      { label: "Update Global CLAUDE.md", description: "Cross-project learning" },
      { label: "None", description: "Nothing needs immediate action" }
    ]
  },
  {
    header: "Next",
    question: "Create tracker items for future sessions?",
    multiSelect: true,
    options: [
      // Adapt to actual session:
      // - Include incomplete work that needs dedicated time
      // - Use bon new (default tracker)
      { label: "[Incomplete work]", description: "Needs dedicated time" },
      { label: "Investigate Y", description: "Needs dedicated exploration" },
      { label: "None", description: "Handoff captures everything needed" }
    ]
  }
])
```

User gets explicit choice over timing. "Next" ≠ abandoned — it's queued with context.

**After Decide completes:** All incomplete work has been addressed (user chose to finish, defer, or drop).

---

## Act

Execute in this order:

### Execute "Now" items
Do the selected actions: finish incomplete todos, close tracker items with notes, update CLAUDE.md, quick fixes.

### Create "Next" items
For each selected deferral, create a tracker item with enough context that a future Claude can pick it up.
- **Bon:** `bon new "title" --why "..." --what "..." --done "..."`

### Write handoff

**Handoff location is non-negotiable.** The script computes the path; you use it exactly.

```bash
~/.claude/scripts/close-context.sh | grep HANDOFF_DIR
```

| Rule | Why |
|------|-----|
| Write to `{HANDOFF_DIR}/{session-id}.md` | Central location, /open finds it |
| Never write locally (`.handoff.md` in project) | /open won't find it — information becomes invisible |
| Never compute path yourself | Encoding differences cause folder fragmentation |

**Why this matters (Jan 2026 incident):** A Claude wrote to `.handoff-kube-migration.md` locally instead of the central location. The next session's /open couldn't find it — loaded a stale handoff instead. The information existed but was invisible.

**Get session ID:**
```bash
ls -t ~/.claude/projects/$(pwd -P | sed 's/[^a-zA-Z0-9-]/-/g')/*.jsonl 2>/dev/null | grep -v agent | head -1 | xargs basename -s .jsonl
```
Use first 8 characters for filename.

**Fallback:** If SESSION_ID is empty (script failed), use timestamp: `2026-01-04-2215.md`

Example: session `51d17dc5-b714-481c-9dfb-6d4128800e7b` → filename `51d17dc5.md`
Full path: `{HANDOFF_DIR}/51d17dc5.md`

```markdown
# Handoff — {DATE}

session_id: {full uuid from above command}
purpose: {first Done bullet, truncated to ~60 chars}

## Done
- [Completions in verb form — include item ID if closing one, e.g., "Fixed auth bug (claude-go-xyz)" or "Completed migration (arc-gutowa)"]

## Gotchas
[What would trip up next Claude]

## Risks
[What could go wrong with what we built]

## Next
[Direction for next session]

## Artifacts
[Only if Google Drive work — see Knowledge Work section below]

## Commands
```bash
# Optional — verification or continuation that might help
```

## Reflection
**Claude observed:** [Key observations from Orient]
**User noted:** [What they added or emphasized]
```

#### Knowledge Work Context (Google Drive)

**When working in Google Drive (not ~/Repos):** Add an Artifacts section to the handoff.

You already know what you touched — you called MCP tools during the session. Recall:
- Which docs you read (`get_content`)
- Which docs you updated (`update_doc`, `append_to_doc`)
- Which folders you browsed (`list_files`)

```markdown
## Artifacts
Working folder: [Project Name](https://drive.google.com/drive/folders/xxx)

This session:
- Updated: [Contract Stewardship Doc](https://docs.google.com/.../d/yyy) — added supplier descriptions
- Created: [Q1 Review Notes](https://docs.google.com/.../d/zzz)
- Referenced: [Budget Template](https://docs.google.com/.../d/www) — read-only
```

**Why this matters:** Knowledge work doesn't have commits. This section is the equivalent — what changed, where.

**Rehydration:** Next Claude can `get_content()` on these links to pull current state. The links are stable; content is always fresh from source.

**Purpose line** is auto-generated from first Done bullet — enables `claude -r` style picker at /open.

### Stage extraction for memory

**After writing the handoff, generate a session extraction from your live context.** This replaces the expensive `claude -p` subprocess that the session-end hook would otherwise spawn. You already have the full conversation in context — use it.

**Get the full session ID** (you already computed this for the handoff filename):
```bash
SESSION_ID=$(ls -t ~/.claude/projects/$(pwd -P | sed 's/[^a-zA-Z0-9-]/-/g')/*.jsonl 2>/dev/null | grep -v agent | head -1 | xargs basename -s .jsonl)
```

**Create the staging directory:**
```bash
mkdir -p ~/.claude/.pending-extractions
```

**Generate and write the extraction JSON** to `~/.claude/.pending-extractions/${SESSION_ID}.json`.

The JSON must match this schema exactly:
```json
{
    "summary": "2-3 sentences — what happened and why it matters",
    "arc": {
        "started_with": "initial goal/problem",
        "key_turns": ["pivots, discoveries, changes in direction"],
        "ended_at": "final state"
    },
    "builds": [{"what": "thing created/modified", "details": "context"}],
    "learnings": [{"insight": "what was learned", "why_it_matters": "significance", "context": "how discovered"}],
    "friction": [{"problem": "what was hard", "resolution": "how resolved or 'unresolved'"}],
    "patterns": ["recurring themes, collaboration style, meta-observations"],
    "open_threads": ["unfinished business, deferred work"]
}
```

**Guidelines for in-context extraction:**
- Focus on OUTCOMES and STORY, not just what was mentioned
- `summary` should capture the "so what" — why this session mattered
- `builds` = concrete artifacts: code, config, docs, skills modified
- `learnings` = insights that transfer to other contexts (not just "I learned X exists")
- `friction` = things that were harder than expected and how they were resolved
- `patterns` = meta-observations about how we worked, recurring themes
- `open_threads` = work that was deferred, not abandoned — future sessions should pick these up

**Write the file using the Write tool.** This is pure JSON, no markdown.

The session-end hook will detect this file and use it instead of spawning `garde process`. If this step fails for any reason, the hook falls back to the old extraction path — so it's safe.

### Commit
If git dirty **in the working directory** (where you started):
- Stage relevant files (including handoff if in repo)
- Commit with standard message + co-authorship
- Push if user approves

**Anti-pattern: Don't commit other repos.** You may have seen dirty state in other repos during the session. That's not your concern — only commit where you're working. Being "helpful" by tidying other repos is unwanted.

### Tell user to exit
Say: "Type `/exit` to close." Don't exit programmatically.

---

## Remember

**Automatic — handled by session-end hook.** You don't invoke this; it happens when the user runs `/exit`.

The hook (`~/.claude/hooks/session-end.sh`) fires automatically and takes one of two paths:

1. **If staged extraction exists** (you wrote `~/.claude/.pending-extractions/<session_id>.json` above):
   - Indexes the session with `garde index` (fast, no LLM)
   - Stores your pre-generated extraction with `garde store-extraction`
   - Removes the staging file
   - No subprocess spawned — your in-context extraction is used directly

2. **If no staged extraction** (crash, ctrl-c, session ended without /close):
   - Falls back to `garde process` which spawns `claude -p` for extraction
   - Same quality, just slower and costs a subprocess

Either way, handoffs are scanned afterward.

**You don't need to do anything here** — just tell the user to `/exit` and the hook takes care of the rest.

---

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Compress reflection into multiple-choice | Defeats surfacing unexpected observations | Share observations first, then ask |
| Skip pre-flight cd check | Handoff written to wrong project | Always run check-home.sh |
| Write handoff locally (.handoff.md) | /open won't find it | Use HANDOFF_DIR from script |
| Silently drop incomplete work | Work disappears | Surface in Decide — finish, defer, or explicit drop |
| Commit other repos | Unwanted "helpful" tidying | Only commit working directory |
| Rush Orient to get to Act | Value compounds in reflection | Complete all three beats |

## GODAR Reference

| Phase | /open | /ground | /close |
|-------|-------|---------|--------|
| **G**ather | Handoff, tracker, script | Todos, tracker, drift | Todos, tracker, git, drift |
| **O**rient | "Where we left off" | "What's drifted" | Claude observes → User co-reflects → Claude answers |
| **D**ecide | User picks direction | Continue or adjust | Crystallize actions (STOP) |
| **A**ct | Draw-down from Bon | Update tracker | Execute, handoff, commit |
| **R**emember | — | Optional: memory skill | Index session (background) |
