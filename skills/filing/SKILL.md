---
name: filing
description: File organization and weekly cleanup. Use when user asks 'where should this go', 'help me tidy', 'clean up downloads', 'clean up desktop', 'triage inbox', during weekly review cleanup, or when moving files between zones. (user)
---

# Filing

Help with file organization: where things belong and keeping inboxes clear.

## When to Use

- "Where should this file go?"
- Weekly review (filing portion)
- Moving files between zones
- Deciding Projects vs Areas vs Resources

## When NOT to Use

- Pattern reflection (use todoist-gtd)
- Todoist organization (use todoist-gtd)
- Code/repo organization (different rules apply)

## Work Folder Structure

Location: `~/Library/CloudStorage/GoogleDrive-*/My Drive/Work`

To find exact path: `ls -d ~/Library/CloudStorage/GoogleDrive-*/My\ Drive/Work`

```
Work/
├── Projects/           # Active outcome folders
├── Areas/              # Ongoing responsibilities
├── Resources/          # Reference material (Larder, GTD Resources)
├── Archive/            # Completed/dormant
├── Meeting Notes/      # By year (2015-2025)
└── Claude Research/    # Session working folders
```

### Projects/
Active work with defined end states. Folders named: `{Area} - {Outcome statement}`

Examples:
- `Industry Influencing - Marketing Week Articles`
- `Product Development - Launched new dashboard...`

**When complete:** Move to Archive/

### Areas/
Ongoing responsibilities (no completion date):
- Budget and Finance
- Cross-Broadcaster Measurement
- Desired Outcomes Planning
- Industry Advisory Roles
- Industry Influencing
- Internal Stakeholders
- Managing Myself
- Processes and Systems
- Team Development

### Resources/
Reference material that supports work:
- **Larder/** - 100+ research PDFs
- **GTD Resources (Common)/** - GTD reference docs

### Archive/
Completed projects and dormant materials. Preserves history.

### Meeting Notes/
Organized by year:
```
Meeting Notes/
├── 2024/
└── 2025/
    └── 2025-12-11 Alex Maguire (Netflix) - EMEA measurement landscape.md
```

Naming: `{date} {Person/Topic} - {Brief description}.md`

### Claude Research/
Session working folders for research context:
```
Claude Research/
├── 20251214 - Claude - strategic priorities/
├── 20251214 - Claude - team priorities/
└── [various .gdoc outputs]
```

**Cleanup:** These accumulate. During weekly review, archive or delete stale ones.

## PARA Quick Reference

| Category | Definition | Completion |
|----------|------------|------------|
| **Projects** | Active work with end state | Finite - move to Archive when done |
| **Areas** | Ongoing responsibilities | Infinite - never "done" |
| **Resources** | Reference material | Supports work, isn't the work |
| **Archive** | Inactive items | Superseded or completed |

**Key distinction:** Areas ≠ Projects. "Team Development" is an Area (infinite). "Hire data scientist" is a Project (finite).

## How This Differs from Strict PARA

Strict PARA has 4 equal categories (Projects, Areas, Resources, Archive).

**This structure adds:**
- **Meeting Notes/** - Chronological organization by year (not in PARA)
- **Claude Research/** - Session working folders (transient, not in PARA)
- Areas are predefined (not emergent as in strict PARA)

**Core PARA principle remains:** Projects complete, Areas don't.

**Why the additions:** Meeting notes benefit from chronological access. Claude Research is truly transient (weekly cleanup). Areas reflect actual work responsibilities.

## Weekly Cleanup Zones

Nine locations where clutter accumulates:

### 1. Local Downloads
**Path:** `~/Downloads`

Typical contents: PDFs, screenshots, installers, random files from web.

**Action:** File to Work/ or delete.

### 2. iCloud Downloads
**Path:** `~/Library/Mobile Documents/com~apple~CloudDocs/Downloads`

Typical contents: Screenshots (iOS sync), files from iOS apps.

**Action:** File to Work/ or delete. Check for screenshots that should go to projects.

### 3. iA Writer Strays
**Path:** `~/Library/Mobile Documents/27N4MQEA55~pro~writer/Documents`

**Structure:**
```
Documents/
└── Diary/          # Structured diary entries (leave alone)
└── [stray files]   # Waifs outside Diary folder
```

**Action:** Anything outside `Diary/` is a stray. File or delete.

### 4. Desktop (iCloud-synced)
**Path:** `~/Desktop`

iCloud Desktop & Documents sync enabled. Files may be cloud-only (evicted from local storage).

Typical contents: Screenshots, drag-dropped files, temporary staging.

**Action:** File to Work/ or delete. Most Desktop items are transient.

**iCloud voodoo:** Files can appear as stubs (cloud-only, download on access). When bulk processing, may trigger downloads. The `.localized` file is system-managed - leave it.

### 5. Work Folder Root
**Path:** `~/Library/CloudStorage/GoogleDrive-*/My Drive/Work`

Should only contain CLAUDE.md (project instructions) - nothing else belongs at root level.

Typical contents: Stray files that missed proper subfolder, CLAUDE.md.

**Action:** CLAUDE.md stays. Everything else gets filed into Projects/, Areas/, Resources/, or Archive/.

### 6. My Drive Root (Inbox)
**Path:** `~/Library/CloudStorage/GoogleDrive-*/My Drive`

True inbox per PARA. Where `doc.new` creates files, where shared docs land, where quick-captured items accumulate.

Typical contents: New Google Docs, shared files, unsorted captures.

**Action:** Triage into Work/ subfolders or delete. This is the primary inbox to keep clear.

### 7. My Drive Temp (Claude Staging)
**Path:** `~/Library/CloudStorage/GoogleDrive-*/My Drive/Temp`

Nominated temp folder for Claude operations — file uploads, MCP staging, transient outputs.

Typical contents: PDFs uploaded for analysis, intermediate files, staged outputs.

**Action:** Delete everything. If something needs keeping, it should have been filed properly after the session that created it. This folder should be empty between sessions.

### 8. Work Inbox (iCloud)
**Path:** `~/Library/Mobile Documents/com~apple~CloudDocs/Work Inbox/`

Quick capture landing zone from iOS Shortcuts. Subfolders organize by type:

```
Work Inbox/
├── Voice Transcripts/   ← Whisper output from JPR recordings
├── Meeting Notes/       ← iOS Shortcut meeting captures
└── Quick Notes/         ← General quick capture
```

Naming: `YYYY-MM-DD [HH-MM] Title.md`

**Action per subfolder:**
| Subfolder | Triage |
|-----------|--------|
| Voice Transcripts/ | Review, extract actions, file to Meeting Notes/ or delete |
| Meeting Notes/ | Copy to Google Drive Meeting Notes/{year}/, keep original |
| Quick Notes/ | File to PARA, extract to Todoist, or delete |

### 9. JPR Voice Recordings
**Path:** `~/Library/Mobile Documents/iCloud~com~openplanetsoftware~just-press-record/Documents/`

Just Press Record voice memos (m4a/mp3). Organized by date: `YYYY-MM-DD/HH-MM-SS.m4a`

**Action:**
1. Transcribe with `~/.claude/scripts/transcribe-jpr.sh --new`
2. Review transcript in Work Inbox/Voice Transcripts/
3. Audio moves to `Processed/` subfolder automatically

## When Filing Signals Deeper Patterns

File organization chaos often symptoms deeper behavioral patterns. Surface these signals during weekly review:

| Signal | Pattern | Response |
|--------|---------|----------|
| Downloads >100 files OR >2 weeks neglect | **Execution-Without-Reflection** | "This backlog suggests rushing through tasks without processing. Want to check patterns?" |
| Claude Research >10 stale folders | **Overcommitment** | "You're starting many explorations but not finishing them. Check your plate?" |
| Multiple "temporary" folders >1 month old | **Scope Creep** | "These temp folders suggest projects expanding beyond original scope." |

**Coordination pattern:** Filing is Phase 1 of weekly review. After tidying, **todoist-gtd** skill handles pattern reflection (Phase 3).

Don't skip the pattern check just because you tidied the files.

## Filing Decisions

### "Where does this go?"

| If it's... | Put it in... |
|------------|--------------|
| Active project artifact | Projects/{relevant project}/ |
| Meeting notes | Meeting Notes/{year}/ |
| Reference PDF/doc | Resources/Larder/ or relevant Resources subfolder |
| Completed project | Archive/ |
| Ongoing area doc | Areas/{relevant area}/ |
| Claude session output | Claude Research/ (or file properly if valuable) |
| Screenshot for project | Projects/{project}/ or delete |
| Random download | Delete or file if valuable |

## Personal Documents Zone

**Path:** `~/Documents/Personal/`

Personal documents with PARA structure (no numbering, aligned with Work folder):

```
Personal/
├── Projects/     # Active personal projects
├── Areas/        # Ongoing personal responsibilities (e.g., Ash)
├── Archive/      # Completed/dormant
└── CLAUDE.md     # Project instructions
```

**Note:** No Resources folder - personal "resources" live in Areas as active things.

**Action:** Personal admin docs (scanned letters, etc.) go to appropriate Area.

## Team Shared Drives

**Detection:** `ls "$GDRIVE/Shared drives/"`

Team shared content lives in Shared Drives (not personal My Drive):
```
Team Shared Drive/
├── Team Reference/      # Team-specific reference material
├── Shared Reference/    # Cross-team reference material
└── External Reference/  # External/industry reference
```

**Action:** Team reference materials (shared tools, analytics) go here, not personal Drive.

## Filing Workflow

### Zone Check (Do This First)

At session start, **explicitly check ALL zones** - don't skip any:

```bash
GDRIVE=$(ls -d ~/Library/CloudStorage/GoogleDrive-* 2>/dev/null | head -1)
echo "=== 1. Downloads ===" && ls ~/Downloads | head -5
echo "=== 2. iCloud Downloads ===" && ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/Downloads 2>/dev/null | head -5
echo "=== 3. iA Writer ===" && ls ~/Library/Mobile\ Documents/27N4MQEA55~pro~writer/Documents 2>/dev/null | grep -v Diary | head -5
echo "=== 4. Desktop ===" && ls ~/Desktop 2>/dev/null | head -5
echo "=== 5. Work root ===" && ls "$GDRIVE/My Drive/Work" 2>/dev/null | grep -v "^CLAUDE.md$" | head -5
echo "=== 6. My Drive root ===" && find "$GDRIVE/My Drive" -maxdepth 1 -type f ! -name ".DS_Store" 2>/dev/null | head -5
echo "=== 7. My Drive Temp ===" && ls "$GDRIVE/My Drive/Temp" 2>/dev/null | head -5
echo "=== 8. Work Inbox ===" && find ~/Library/Mobile\ Documents/com~apple~CloudDocs/Work\ Inbox -type f ! -name ".DS_Store" 2>/dev/null | head -5
echo "=== 9. JPR Voice ===" && find ~/Library/Mobile\ Documents/iCloud~com~openplanetsoftware~just-press-record/Documents -name "*.m4a" -o -name "*.mp3" 2>/dev/null | grep -v "/Processed/" | head -5
```

Report which zones have content before starting. Don't skip zones that look empty - verify each one.

### Per-File Process (5 Steps)

When triaging files, follow this 5-step process:

1. **Review** - Read content to understand what the file actually is
   - For text files: Claude reads directly
   - For binary/GUI files: `open -a "Sublime Text" file.md` or `open file.pdf`

2. **Rename** - Adjust filename to match actual content
   - Generic names like "Untitled" or "Copy of..." need proper names
   - Use descriptive names: `Simon McCarthy - Pricing Power Proposal`

3. **Split** - If multiple topics in one file, separate them
   - Open in GUI for user review
   - Create new files for distinct topics

4. **Capture** - Outstanding actions → Todoist
   - **Before adding:** Search for existing/completed tasks to avoid duplicates
   - Use todoist-gtd CLI: `scripts/todoist.py filter "search query"`
   - Create tasks via CLI: `scripts/todoist.py add "task" --project-id <id>`
   - Link description to filed document

5. **File** - Move to correct location (or delete)
   - See "Filing Decisions" section for where things go

## Archive vs Reference

**The test:** "Will I search for this to USE it, or just to REMEMBER it?"

| Answer | Location | Examples |
|--------|----------|----------|
| **USE it** | Resources/ | Methodology docs, templates, how-to guides |
| **REMEMBER it** | Archive/ | Completed project artifacts, old meeting notes |

**Reference** = I'll need this again to do work
- Research PDFs that inform decisions
- Templates I reuse
- Product specs, methodology docs

**Archive** = This was a thing, now it's done
- Completed project artifacts
- Superseded versions
- Historical records

## Common Filing Patterns

### External doc → Google Doc → Project folder

When filing a document that needs to live in a Project:

1. Read content (use docx skill for Word docs)
2. Create Project folder if needed: `{Area} - {Outcome statement}`
3. Convert to Google Doc: `mcp__mise__create`
4. Delete original file
5. Update any Todoist task that references it with new link

### Todoist task linking

When a filed document relates to a Todoist task:

1. Search for task: `scripts/todoist.py filter "task name"`
2. Get task details: `scripts/todoist.py task <task-id>`
3. Update via Todoist app or API (CLI update coming)

**Pattern:** Canonical document location should be in Todoist task description.

## Weekly Review Integration

**Note:** Weekly review is a three-phase workflow orchestrated by **todoist-gtd** skill:
1. **Filing** (this skill) — Clear cleanup zones
2. **Outcomes Review** (todoist-gtd) — Check outcome health
3. **Pattern Reflection** (todoist-gtd) — Freedom score, pattern interrupts

During weekly review, check all 9 cleanup zones:

1. **~/Downloads** - File or delete
2. **iCloud Downloads** - File or delete
3. **iA Writer strays** - File or delete
4. **~/Desktop** - File or delete (mind iCloud stubs)
5. **Work/ root** - Only CLAUDE.md should remain
6. **My Drive root** - Triage into Work/ or delete
7. **My Drive Temp** - Delete everything (Claude staging folder)
8. **Work Inbox** - Triage subfolders (Voice Transcripts, Meeting Notes, Quick Notes)
9. **JPR Voice** - Transcribe new recordings, review transcripts

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Skip zones during weekly review | Clutter accumulates | Check ALL 9 zones explicitly |
| Keep "just in case" | Folders bloat | Delete liberally, most things don't need keeping |
| File without renaming | Untitled docs pile up | Rename to content-descriptive name first |
| Skip Todoist search before adding | Duplicate tasks | Always search for existing task first |

## Remember

**File promptly, delete liberally.** Most downloads don't need keeping. Screenshots are usually transient. When in doubt, delete.

**Projects complete, Areas don't.** If you're wondering "is this done?", it's probably a Project. If you're wondering "is this still my responsibility?", it's an Area.

## ~/Repos Naming Convention

Development tools live in `~/Repos/` with prefix conventions:

| Prefix | Contains | Example |
|--------|----------|---------|
| `claude-suite` | Core session skills | session-opening, beads, filing |
| `skill-*` | Specialized skills | `skill-itv-styling` |
| `mcp-*` | MCP servers | `mcp-workspace` |
| `infra-*` | Infrastructure | `infra-openwrt` |
| `claude-*` | Claude experiments | `claude-memory` |

**Skills:** Symlinked to `~/.claude/skills/`. Core skills in `claude-suite/skills/`, specialized skills in individual repos, skills with tooling co-located with their infrastructure.
