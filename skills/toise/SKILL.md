---
name: toise
description: Orchestrates architecture review for Claude-maintained software — 3-stage process (measure, analyse, report) that grades codebases against five principles and proposes CLAUDE.md improvements. Invoke before adding significant complexity or when inheriting an unfamiliar repo. Triggers on 'toise review', 'review this architecture', 'is this Claude-friendly', 'check maintainability', 'before we add complexity', 'measure this codebase'. Do NOT use for pure code review (use titans). (user)
allowed-tools: [Read, Glob, Grep, Bash, Agent]
---

# Toise

Architecture review for Claude-maintained software.

**Core thesis:** Claude is the primary code-touching entity in these codebases. Architecture that works for Claude encodes global decisions in discoverable artefacts so that each fresh session can do good local work without the architect in the room. Five principles capture what makes this work. This skill measures codebases against them.

**Relationship to other artefacts:**
- `understanding.md` is the soul — accumulated wisdom, grown through /close handoffs. Toise reads it for context but never writes to it.
- `CLAUDE.md` is the manual — actionable guidance for Claude. Toise proposes improvements to it.
- `principles.md` is the manifesto — the five principles and their grading rubrics.

See `references/principles.md` for the full principles with grading rubrics.
See `references/evidence.md` for empirical case studies.

## When to Use

- Inheriting an unfamiliar repo — assess before modifying
- Before adding significant complexity (new framework, new abstraction layer)
- Periodic health check on an actively-developed project
- After a major refactor, to verify improvements landed
- When CLAUDE.md feels stale or incomplete

## When NOT to Use

- Pure code review (bugs, style, idiom) — use titans
- One-off scripts that won't be maintained
- Reviewing someone else's library you consume but don't modify

## The Five Principles

| # | Principle | Core Question |
|---|-----------|--------------|
| 1 | Self-documenting files | Can Claude orient in 10 seconds? |
| 2 | One shape, everywhere | Can Claude predict sibling modules? |
| 3 | Boundaries are the architecture | Can Claude trace impact without reading implementation? |
| 4 | Small, pure, explicit | Can Claude change a function without reading other files? |
| 5 | Extend by recipe | Can Claude add features by following instructions? |

Full rubrics in `references/principles.md`.

## Running the Review

Three stages. Run them in order — no skipping measurement.

### Stage 1: Measure

Run the automated metrics script. This produces hard numbers before any opinions form.

```bash
uv run --script <path-to-skill>/references/metrics.py <repo-path>
```

The script scans git-tracked source files and reports:
- File size distribution (p50, p90, max, files over 500/1000 lines)
- First-breath score (% of files with purpose visible in first 20 lines)
- Boundary artefact checklist (CLAUDE.md, AGENTS.md, understanding.md, generated-files manifest)
- CLAUDE.md quality (section checklist: architecture, module map, dependency rules, recipes, anti-patterns)
- Pattern signals (test framework consistency, error handling patterns)
- Extension recipe presence

Also read these files if they exist — they provide context the agent needs:
- `.bon/understanding.md` — project history, design rationale, landmines
- `CLAUDE.md` / `AGENTS.md` — current guidance

Save the metrics output and any context files for Stage 2.

### Stage 2: Analyse

Spawn a single architecture reviewer agent. Pass it the metrics output, the principles, and any context from understanding.md.

The agent's job: read the codebase, assess each principle using the metrics as a starting point but applying judgement where metrics can't reach, and produce grades with evidence.

Use the Agent tool with this structure:

```
Agent({
  description: "Architecture review against five principles",
  prompt: <constructed below>
})
```

**Construct the prompt from these parts:**

1. **Role:** "You are an architecture reviewer assessing a codebase against five principles for Claude-maintained software."

2. **Principles:** Inline the content of `references/principles.md` (the full principles with grading rubrics).

3. **Suppression list:** Inline the content of `references/suppression.md` (what NOT to flag).

4. **Metrics output:** Paste the output from Stage 1.

5. **Context:** If understanding.md exists, include it with a note: "This is the project's accumulated institutional memory. Use it to understand WHY decisions were made, but assess the current codebase — not the history."

6. **Instructions:**

```
Assess this codebase against the five principles. For each principle:

1. Start from the metrics — they give you the automated signal.
2. Read key files to assess what metrics can't measure:
   - Principle 1: Are the explanations accurate and sufficient? (read a sample of files)
   - Principle 2: Is the dominant pattern good, or just consistent? (read 3-4 modules)
   - Principle 3: Are boundaries in the right places? (read CLAUDE.md, module exports)
   - Principle 4: Is state management clear, not just explicit? (read core modules)
   - Principle 5: Are the recipes complete and correct? (try following one mentally)
3. Assign a letter grade (A-F) using the rubrics in the principles document.
4. Write a one-line verdict for each principle.
5. For any principle graded C or below, write 3-5 sentences explaining the issue with specific file references.
6. Propose specific CLAUDE.md additions that would improve the weakest principles. These should be concrete paragraphs the maintainer can accept or edit, not vague suggestions.

Confidence calibration:
- Only report findings at 0.60+ confidence.
- Every finding must cite specific files or metrics as evidence.
- Do not flag items on the suppression list.
- Do not propose rewrites or major refactors — flag the issue and grade; decisions are the maintainer's.

Output format:
- Grade table (principle | grade | one-line verdict)
- Expanded analysis for C-or-below grades
- Proposed CLAUDE.md additions as markdown blocks
- Keep total output under 800 words — this is a summary, not a report.
```

### Stage 3: Report

Present the agent's output to the user. Format:

```markdown
## Toise Review: [project name]

| Principle | Grade | Verdict |
|-----------|-------|---------|
| 1. Self-documenting | B | 95% first-breath score; 2 files lack rationale for design choices |
| 2. One shape | A | Consistent pytest + exceptions pattern; justified deviations documented |
| 3. Boundaries | C | CLAUDE.md exists but thin (2/5 sections); no extension recipes |
| 4. Small/pure/explicit | B | p90 at 415 lines; one outlier at 1605 (cli.py) |
| 5. Extend by recipe | D | No extension documentation; Claude would have to reverse-engineer from code |

### Priority improvements

1. **CLAUDE.md needs extension recipes** (Principle 5, grade D)
   cli.py follows a consistent command pattern — document it as a recipe:
   "To add a new command: define `cmd_foo()` in cli.py following the
   `check_initialized → load_items → mutate → save_items` pattern, add
   the subparser in `build_parser()`, and add a test in `tests/test_foo.py`."

2. **CLAUDE.md architecture section** (Principle 3, grade C)
   [proposed paragraph...]

### Proposed CLAUDE.md additions

[Concrete markdown blocks the user can accept/edit/reject]
```

Only expand principles graded C or below. A and B grades get the one-line verdict only.

## Anti-Patterns

| Anti-pattern | Problem |
|---|---|
| Skipping measurement | Opinions without evidence. Run Stage 1 first. |
| Grade inflation | Sycophantic review helps nobody. Apply rubrics honestly. |
| Reviewing code style | Wrong scope — use titans for bugs, craft, idiom. |
| Proposing rewrites | Flag and grade; decisions are the maintainer's call. |
| Flagging generated files | Metrics script skips them. The agent should too. |
| Generic suggestions | "Consider adding documentation" — say WHAT documentation WHERE. |
| Ignoring understanding.md | It tells you why. Without it you'll misdiagnose. |
