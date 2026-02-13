---
name: skill-check
description: "Retired — merged into skill-forge. Invoke skill-forge instead for all skill validation, quality checks, and sharing scans. Triggers on 'check this skill', 'validate skill', 'can I share this', 'scan for sharing'. (user)"
---

# skill-check → skill-forge

This skill has been merged into **skill-forge** which now handles the full lifecycle: creation, validation, CSO scoring, and sharing scans.

**Use `skill-forge` instead.** All quality checklists, naming requirements, CSO patterns, anti-patterns, and the sharing scanner now live there.

```bash
# Validation (was skill-check)
~/.claude/skills/skill-forge/scripts/lint_skill.py <skill-path>
~/.claude/skills/skill-forge/scripts/score_description.py <skill-path>

# Sharing scan (was skill-check)
~/.claude/skills/skill-forge/scripts/scan.py <skill-path>
```
