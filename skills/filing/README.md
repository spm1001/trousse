# Filing Skill

File organization and cleanup — where things belong and keeping inboxes clear.

## What This Skill Does

Helps with file organization using a PARA-influenced structure:
- **Projects** — Active work with defined end states
- **Areas** — Ongoing responsibilities
- **Resources** — Reference material
- **Archive** — Completed/dormant items

Also handles weekly cleanup of common clutter zones (Downloads, Desktop, Drive inbox).

## Installation

```bash
ln -s /path/to/skill-filing ~/.claude/skills/filing
```

## When Claude Uses This Skill

Activates on:
- "where should this go?", "help me tidy"
- "clean up downloads", "clean up desktop"
- "weekly review" (filing portion)
- Moving files between zones

## Key Features

### Zone Check
Scans all common clutter locations in one command:
- ~/Downloads
- iCloud Downloads
- Desktop
- Google Drive inbox
- Work folder root

### Per-File Process
5-step workflow: Review → Rename → Split → Capture (to Todoist) → File

### Pattern Detection
When cleanup reveals behavioral signals (100+ downloads, many stale folders), suggests invoking the collaborating skill for reflection.

## Customization

The skill uses glob patterns for Google Drive paths (`GoogleDrive-*`) so it works with any account. Adapt the folder structure to your own PARA setup.

## License

MIT
