# Field Report: Filing Skill - Weekly Review Session

**Date:** 2026-02-01
**Session context:** Weekly review, filing phase
**Reporter:** Claude (Opus 4.5)

## Summary

Filing skill needs significant enhancement. Current version is basically "move files around" — but proper filing requires **processing**, not just shuffling.

## What Went Wrong

### 1. Filed meeting notes without reading them

I moved 12 meeting notes from Work Inbox to `Work/Meeting Notes/2026/` without checking their contents. User rightly called this out:

> "when you say processed the work notes - did you check for any actions that I need to track (mine or Waiting Fors) - and did they need any tidying up?"

**Impact:** Actions and waiting-fors would have been lost. Filing without extraction is just moving the problem.

### 2. Missed a key meeting source

Meeting notes weren't just in Work Inbox — the BT tri-weekly lives in a Google Doc. I only found it when user pointed me there:

> "of course - it's in the https://docs.google.com/document/d/..."

**The skill should prompt:** "Are there running meeting docs I should also check?"

### 3. No systematic action extraction workflow

When I did read the notes, I had no structured approach. I improvised:
1. Read all notes
2. Extract actions manually
3. Create temp markdown file
4. Open in Sublime for user to edit
5. Process edited file into Todoist

This worked, but it's not documented anywhere.

## What Worked Well

### The "Sublime Loop" Pattern

Creating a temp file with extracted actions, opening in Sublime for user review/edit, then processing the saved result — this was effective:

```
1. Extract actions from notes → /tmp/meeting-actions.md
2. open -a "Sublime Text" /tmp/meeting-actions.md
3. User edits (fixes names, removes stale items, clarifies vague ones)
4. User saves → Claude detects modification
5. Read edited file → add to Todoist
```

**Why it works:**
- User sees all actions at once, can edit in familiar tool
- Catches errors (I had "Susie" vs "Susan" wrong)
- User can delete stale/irrelevant items before they hit Todoist
- Disambiguation happens naturally (user knows context I don't)

### Empty note cleanup

Deleting empty notes and renaming misnamed ones (the "Daily review" that was actually AI training notes) was straightforward and valuable.

## Recommendations for Skill Update

### 1. Add "Processing" as distinct from "Moving"

Filing = Processing + Organizing

**Processing checklist for meeting notes:**
- [ ] Read the note
- [ ] Extract actions (mine)
- [ ] Extract waiting-fors (NAME to TASK format)
- [ ] Note any calendar items
- [ ] Check if note is empty → delete
- [ ] Check if note is misnamed → rename
- [ ] Move to appropriate folder

### 2. Document the Sublime Loop

Add to SKILL.md:

```markdown
## Action Extraction Workflow

When processing meeting notes with actions:

1. Extract to temp file with sections:
   - ## Waiting For (NAME to TASK format)
   - ## Ping (quick actions for me)
   - ## Calendar (dates to add)

2. Open in Sublime: `open -a "Sublime Text" /tmp/actions.md`

3. Tell user: "Edit, save, let me know when ready"

4. After save notification, read file and add to Todoist
```

### 3. Add meeting source discovery

Prompt at start of filing:
- "Besides Work Inbox, are there running meeting docs I should check for actions?"
- Check for common patterns: Google Docs with "meeting" or specific contact names

### 4. Add quality checks for notes

Before filing, check:
- Is note empty? → Delete (with confirmation)
- Is title accurate? → Offer rename
- Are there unchecked action items? → Extract them

## Questions for Skill Owner

1. Should action extraction be mandatory or optional during filing?
2. Where should the Sublime loop temp files live? (`/tmp/` works but feels fragile)
3. Should we maintain a list of "running meeting docs" to check during weekly review?

## Related

- todoist-gtd skill (receives the extracted actions)
- Session closing skill (might also extract actions from session work)
