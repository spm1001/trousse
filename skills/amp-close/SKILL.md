---
name: amp-close
description: Amp end-of-session ritual. Invoke FIRST when session is ending — 4-phase GODAR loop (gather context, orient via reflection, decide now-vs-next, act and index to garde) that prevents silent work-dropping and persists searchable memory. MANDATORY before closing any substantial Amp thread. Triggers on 'wrap up', 'let's finish', 'close out', 'end of session'. (user)
---

# amp-close

Capture learnings while context is rich, then persist to memory and exit.

Amp equivalent of the CC `/close` skill. Adapted for Amp's tool names, thread model, and lack of lifecycle hooks — the skill IS the lifecycle event.

## When to Use

- Session ending naturally (work complete)
- Context window nearly full
- User says "wrap up", "let's finish", "one more thing then done"
- Before using the `handoff` tool (close first, then handoff if continuing)

## When NOT to Use

- Mid-session checkpoint (just summarise and continue)
- Quick question that doesn't need closure
- Exploratory work with no conclusions yet

## Structure

```
Gather  → git, bon, drift
Orient  → Agent observes → User reflects → Agent answers
Decide  → crystallise Now vs Next (STOP before executing)
Act     → execute, write extraction, index in garde
```

---

## Gather

### Thread ID

Extract from the system prompt. The `Amp Thread URL` line contains it:

```
Amp Thread URL: https://ampcode.com/threads/T-019c6312-ed70-71bb-ad56-ea2887bb55e4
```

The thread ID is `T-019c6312-ed70-71bb-ad56-ea2887bb55e4`. Use this for the extraction filename.

### Context

Gather by running commands via Bash:

```bash
# Git status (if in a repo)
git status --porcelain 2>/dev/null
git rev-list --count @{u}..HEAD 2>/dev/null || echo "0"

# Bon status (if .bon/ exists)
[ -d .bon ] && cat .bon/items.jsonl | python3 -c "
import sys, json
for line in sys.stdin:
    item = json.loads(line)
    if item.get('status') in ('open', 'waiting'):
        print(f\"{item['status']}: {item.get('title', '?')}\")
" 2>/dev/null
```

### Drift

Compare what the session set out to do (first user message or handoff context) with what actually happened. Note divergences.

---

## Orient

Three beats. All three must complete before Decide.

### Agent shares observations

Share directly — don't compress into multiple-choice:

> "Before we wrap up, here's what stood out to me this session:
> - [specific observation about the work]
> - [pattern or connection noticed]
> - [something that felt unfinished or risky]
>
> What resonates? What am I missing?"

### User reflects

Ask the user which reflections to explore:

**Looking Back:** What did we forget? What did we miss? What could we have done better?

**Looking Ahead:** What could go wrong? What won't make sense later? What will we wish we'd done?

### Agent answers selected questions

Respond genuinely to whatever the user selected. Don't rush this — the reflection is where value compounds.

---

## Decide

**STOP.** Do not proceed to Act without user approval.

From Gather + Orient, crystallise actions into two buckets:

### Now vs Next

**Now** = actions that execute immediately, benefiting from current context:
- Incomplete work that can be finished quickly
- Close a bon item with resolution notes
- Quick fixes (< 2 minutes)

**Next** = deferrals that create work for a future session:
- Incomplete work that needs dedicated time
- Create a bon item (by definition, deferring)
- Anything needing fresh thinking

Present both lists to the user. Every piece of incomplete work from the session must appear in one bucket — nothing silently drops.

---

## Act

Execute in this order:

### 1. Execute "Now" items

Do the selected immediate actions.

### 2. Create "Next" items

For each selected deferral, create a bon item:

```bash
bon new "title" --why "..." --what "..." --done "..."
```

### 3. Write extraction and index in garde

This is the Remember phase — done inline because Amp has no session-end hook.

**Generate extraction JSON** matching garde's schema:

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

**Guidelines for extraction:**
- `summary` captures the "so what" — why this session mattered
- `builds` = concrete artifacts: code, config, docs, skills modified
- `learnings` = insights that transfer to other contexts
- `friction` = things harder than expected
- `patterns` = meta-observations about how we worked
- `open_threads` = deferred work, not abandoned

**Write and index:**

```bash
# Write extraction to temp file
cat > /tmp/amp-extraction.json << 'EXTRACTION'
{the generated JSON}
EXTRACTION

# Ensure thread is indexed
cd ~/Repos/garde-manger && uv run garde scan --source amp --quiet

# Store extraction against this thread
cd ~/Repos/garde-manger && uv run garde store-extraction "amp:THREAD_ID" --model amp-context < /tmp/amp-extraction.json

# Clean up
rm /tmp/amp-extraction.json
```

Replace `THREAD_ID` with the thread ID from Gather (e.g., `T-019c6312-ed70-71bb-ad56-ea2887bb55e4`).

### 4. Commit (if applicable)

If git dirty in the working directory:
- Stage relevant files
- Commit with standard message
- Push if user approves

Only commit the working directory — never "helpfully" tidy other repos.

### 5. Tell user session is complete

Say: "All done — safe to close this thread."

---

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Skip Orient reflection | Loses the highest-value part | Complete all three beats |
| Silently drop incomplete work | Work disappears | Surface in Decide — finish, defer, or explicit drop |
| Rush to extraction | Shallow summary | Reflect first, extract from reflection |
| Commit other repos | Unwanted tidying | Only commit working directory |
| Use `handoff` instead of closing | Context pipes forward but nothing persists to memory | Close first, handoff second if needed |
| Forget `garde scan` before `store-extraction` | Thread not yet indexed, extraction orphaned | Always scan first |

## Integration

**Depends on:**
- `garde` CLI (`uv run garde` from `~/Repos/garde-manger`)
- `bon` CLI (if `.bon/` exists in working directory)

**Complements:**
- Amp's `handoff` tool — close captures memory, handoff continues work
- `garde` skill — searching past sessions that amp-close indexed
- CC `close` skill — same ritual, different platform

## GODAR Reference

| Phase | CC /close | amp-close |
|-------|-----------|-----------|
| **G**ather | `close-context.sh` script | Bash commands inline |
| **O**rient | Claude observes → AskUserQuestion → Claude answers | Agent observes → plain text prompt → agent answers |
| **D**ecide | AskUserQuestion multi-select | Plain text Now/Next lists |
| **A**ct | Execute, handoff file, `.pending-extractions/`, commit | Execute, garde extraction inline, commit |
| **R**emember | Session-end hook → `garde process` | Done in Act (no hook available) |
