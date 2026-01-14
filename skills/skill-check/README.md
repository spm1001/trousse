# Skill Checker

Quality checklist for validating Claude Code skills before deployment.

## What This Skill Does

Provides a structured validation checklist for skill development:
- Description quality (triggers, specificity)
- SKILL.md structure and size
- Reference file organization
- Example completeness
- Terminology consistency

## Installation

```bash
ln -s /path/to/skill-checker ~/.claude/skills/skill-checker
```

## When Claude Uses This Skill

Activates on:
- "check this skill", "validate skill", "skill review"
- After completing skill-creator workflow
- Before deploying a new or updated skill

## Usage

After writing or updating a skill:

```
check this skill
validate skill-name
```

Claude will run through the quality checklist and report issues.

## License

MIT
