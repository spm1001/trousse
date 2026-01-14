# Beads Skill — Project Context

Learnings from developing and maintaining the beads skill.

## Design Principles

### Move Work to Bash, Not to Claude

When Claude struggles with a multi-step CLI task, the fix isn't always "better documentation." Consider whether the startup hook (`open-context.sh`) should precompute the result instead.

**Example:** Hierarchy display required N+1 bd calls (list epics, then --parent for each). Rather than teaching Claude the incantation, we moved it to bash. Claude just displays what the hook provides.

### Anti-Patterns Before Commands

Claude reads skill files sequentially. If you show the command first and warnings second, Claude tries the wrong thing, then corrects. Put warnings FIRST:

```markdown
**⚠️ STOP — don't do these:**
- `bd list --json | jq .parent` — field doesn't exist

**Do this instead:**
```bash
bd list --parent <epic-id>
```
```

### Maximum 2 Levels of Hierarchy

Beads structure is flat by design:
- Level 1: Desired Outcome (epic)
- Level 2: Next Actions (tasks/bugs)

No nested epics. When detected, flag with `[NESTED EPIC - flatten]` rather than inventing terminology like "sub-epic".

## Field Reports Are Diagnostic Gold

When another Claude files a field report documenting their struggle, treat it as a bug report against the skill. The 6-attempt journey in a field report maps directly to documentation gaps.

## Key Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill documentation |
| `~/.claude/scripts/open-context.sh` | Precomputes `=== BEADS_HIERARCHY ===` at startup |
| `references/DEPENDENCIES.md` | Dependency semantics including parent-child |
