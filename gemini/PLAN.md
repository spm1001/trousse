# Plan: Gemini-Native /close Ritual

**Status:** Revised 2026-02-16 after discovering `skills/amp-close/SKILL.md` — a battle-tested non-CC close skill already in trousse.

**Context:** Three close skills now exist or are planned across the harness family:

| Skill | Harness | Status | Orient mechanism |
|-------|---------|--------|------------------|
| `skills/close/` | Claude Code | Production | AskUserQuestion (interactive menu) |
| `skills/amp-close/` | Amp | Production | Oracle (GPT-5.2 — external model dispatch) |
| `gemini/skills/close/` | Gemini CLI | **Planned** | Self-reflect + `ask_user` (see below) |

**Goal:** Create `gemini/skills/close/SKILL.md` by adapting amp-close, not building from scratch.

## Why amp-close is the template

The original plan proposed three new artifacts (`gather_context.py`, `perform_closure.py`, `SKILL.md`). amp-close proves only the SKILL.md is needed:

- **Gather** — amp-close uses inline Bash (git status, jq on `.bon/items.jsonl`). No Python wrapper needed. Gemini has strong shell execution — same pattern works.
- **Act** — amp-close writes handoffs with `cat >` and calls garde directly. No `perform_closure.py` needed.
- **Remember** — amp-close runs `garde scan` + `garde store-extraction` synchronously in the Act phase. No hook dependency. Gemini's hooks are unreliable — this is exactly what we want.

~~`gather_context.py`~~ — Won't build. Inline Bash is sufficient.
~~`perform_closure.py`~~ — Won't build. SKILL.md orchestrates directly.

## What changes from amp-close

### The Orient gap: no Oracle equivalent

This is the only substantial difference. amp-close dispatches to Oracle (GPT-5.2) for Beat 2 — a genuinely external second opinion that breaks the self-reflection closed loop. Gemini CLI has no equivalent external model dispatch.

**Options considered:**

| Approach | Pros | Cons |
|----------|------|------|
| Self-reflect (accept the closed loop) | Simple, no dependencies | Same model that missed something answers "what did you miss?" |
| Shell out to `claude -p` as Oracle | Genuine cognitive diversity | Heavy (subprocess), slow, requires CC installed |
| Shell out to `amp --execute` as Oracle | Same diversity as amp-close | Requires Amp installed, network dependency |
| Self-reflect + `ask_user` as circuit breaker | Lightweight, honest about limitations | Weaker than external Oracle |

**Decision: Self-reflect + `ask_user` as circuit breaker.** Gemini self-assesses the six questions, presents findings, then asks the user "What am I missing?" via `ask_user`. The user is the external perspective that breaks the loop. This is weaker than Oracle but:
- Zero extra dependencies
- Works offline
- The user is always a better circuit breaker than another model for domain-specific blindspots
- amp-close already has this pattern as its trivial-session fallback — we're promoting the fallback to primary

### Metadata differences

| Field | amp-close | gemini-close |
|-------|-----------|--------------|
| Session ID source | `Amp Thread URL` in system prompt | TBD — Gemini's session identifier format |
| Handoff filename | `amp-{8hex}.md` | `gemini-{8hex}.md` |
| Handoff metadata | `source: amp`, `thread_url: https://ampcode.com/threads/...` | `source: gemini` |
| garde source prefix | `amp:T-...` | `gemini:{session-id}` |

### Harness-specific notes

- Gemini CLI may or may not persist cwd between tool calls (amp doesn't — hence the "use `cwd` parameter" anti-pattern). Test and document.
- Gemini's `ask_user` is text input, not multi-select. Orient and Decide flows should be phrased as proposals to confirm/amend, not menus to select from.
- Gemini's hook system (SessionStart, BeforeModel, SessionEnd) is already wired to trousse scripts in `~/.claude/gemini/settings.json`. The close skill should NOT depend on SessionEnd — do everything inline, same as amp-close.

## What ports verbatim from amp-close

Almost everything:

- Six questions framework (Looking Back / Looking Ahead)
- Now vs Next decision structure
- Handoff template (same contract, same directory, same encoding)
- Extraction JSON schema (same garde format)
- `garde scan` → `garde store-extraction` sequence
- Graceful degradation when garde-manger not installed
- Anti-patterns table (most entries apply directly)
- "Reporter not defendant" framing for presenting findings
- CWD validation before writing handoff

## Single artifact to build

`gemini/skills/close/SKILL.md` — adapted from `skills/amp-close/SKILL.md` with:
1. Orient Beat 2 rewritten for self-reflect + `ask_user` (replacing Oracle dispatch)
2. Session ID extraction updated for Gemini's format
3. Filename prefix and metadata fields updated
4. Anti-patterns table trimmed of Oracle-specific entries, Gemini-specific ones added

## Bon items

- **`trousse-luriwo`** (Build gather_context.py) → **close as won't-do** — inline Bash sufficient
- **`trousse-getozo`** (Write SKILL.md) → **this is the work** — focused adaptation of amp-close

## Open questions

1. **What is Gemini CLI's session identifier format?** Need to test — affects handoff filename and garde source ID.
2. **Does Gemini persist cwd between shell calls?** Affects whether we need the `cwd` anti-pattern note.
3. **Could a future Gemini feature provide external model dispatch?** If so, the Oracle pattern could be retrofitted. Design the Orient section to make this easy.
