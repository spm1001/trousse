# CLI Bootstrap & Admin Reference

This reference covers CLI-only operations that have no MCP equivalent, plus CLI equivalents for core operations when working in web environment without MCP.

## When You Need CLI

### 1. Bootstrap Operations (No MCP Equivalent)

These operations must be done via CLI:
- **Project initialization:** `bd init <prefix>`
- **Daemon management:** `bd daemon --start/--stop/--status`

### 2. Admin Operations (No MCP Equivalent)

These maintenance tasks use CLI:
- **Database compaction:** `bd compact`
- **Backup/restore:** `bd export`, `bd import`
- **Quick reference:** `bd quickstart`

### 3. Web Environment (MCP Unavailable)

When working in web Claude without MCP setup, use CLI equivalents for all operations (see translation table below).

---

## Bootstrap Commands

### bd init

Initialize bd in current directory (creates `.beads/` directory and database).

```bash
bd init                    # Auto-detect prefix (from existing issues or folder name)
bd init --prefix api       # Override auto-detection (rare - only if needed)
bd init --quiet            # Non-interactive mode (auto-installs hooks, no prompts)
```

**When to use:**
- First time setting up bd in a project
- Creating a new project-local issue database
- Re-initializing after corruption

**Auto-detection priority:**
1. Reads prefix from first issue in existing JSONL
2. Falls back to directory folder name
3. Only use `--prefix` to override

**What it creates:**
- `.beads/` directory
- `.beads/<prefix>.db` - SQLite database
- `.beads/<prefix>.jsonl` - JSONL backup file
- Git hooks (post-merge, pre-push) if user confirms

**For non-interactive setup (agents):** Use `bd init --quiet`

---

### bd info --whats-new

Show recent version changes relevant to AI agents (last 3 versions).

```bash
bd info --whats-new          # Human-readable output
bd info --whats-new --json   # Machine-readable output
```

**When to use:**
- At session start after bd version upgrade
- When you see unfamiliar command output or behavior
- To quickly understand recent changes without re-reading full documentation

**What it shows:**
- New commands and flags that improve agent workflows
- Breaking changes requiring workflow updates
- Performance improvements and bug fixes
- Integration features (MCP, git hooks, Agent Mail)

**Example output:**
```
v0.23.0 (2025-11-08):
  - Auto-invoke 3-way merge for JSONL conflicts
  - Add 'new' as alias for 'create' command
  - Add bd cleanup command for bulk deletion

v0.22.0 (2025-11-05):
  - Add bd merge command for git 3-way JSONL merging
  - Merge driver auto-config in bd init

v0.21.9 (2025-11-05):
  - Add pattern matching and date ranges to bd list
```

---

### bd hooks install

Install or update git hooks for automatic bd sync.

```bash
bd hooks install             # Install hooks in current repo
```

**When to use:**
- After `bd init` if you skipped hook installation
- After upgrading bd (hooks may have updates)
- Repairing hooks after git corruption

**What it installs:**
- **post-merge hook:** Auto-sync after `git pull`
- **pre-push hook:** Export JSONL before `git push`
- **merge driver:** Intelligent 3-way JSONL merging for conflicts

**Note:** `bd init --quiet` auto-installs these hooks without prompting.

---

### bd daemon

Manage the bd daemon (background process that handles MCP requests and JSONL syncing).

```bash
bd daemon --start          # Start daemon for current project
bd daemon --start --global # Start daemon globally (all projects)
bd daemon --stop           # Stop daemon
bd daemon --status         # Check daemon status
```

**When to use:**
- **Start:** After installing bd CLI, before using MCP tools
- **Stop:** Troubleshooting, before upgrading bd
- **Status:** Checking if daemon is running, debugging connection issues

**Note:** Daemon auto-starts when MCP tool is used, so manual start is rarely needed.

**Daemon requirements:**
- Must be inside a git repository
- Cannot run from cloud storage (Google Drive, Dropbox)

---

## Admin Commands

### bd compact

Compact closed issues older than 30 days (removes from database, keeps in JSONL).

```bash
bd compact                 # Interactive - shows what will be compacted
bd compact --yes           # Non-interactive - compact without confirmation
```

**When to use:**
- Database has grown large (many closed issues)
- Want to archive old completed work
- Preparing for database migration

**What it does:**
- Removes closed issues older than 30 days from SQLite
- Preserves all issues in JSONL (for restore if needed)
- Reduces database size for faster queries

**Recovering compacted issues:**
```bash
bd import < .beads/<prefix>.jsonl
```

---

### bd export

Export all issues to JSONL format.

```bash
bd export > backup.jsonl
bd export --json           # Same output, explicit flag
```

**Use cases:**
- Manual backup before risky operations
- Sharing issues across databases
- Version control / git tracking
- Data migration or analysis

**Note:** bd auto-exports to `.beads/<prefix>.jsonl` after each operation (5s debounce). Manual export is rarely needed.

---

### bd import

Import issues from JSONL format.

```bash
bd import < issues.jsonl
bd import --resolve-collisions < issues.jsonl
```

**Flags:**
- `--resolve-collisions` - Automatically remap conflicting issue IDs

**Use cases for --resolve-collisions:**
- Reimporting after manual JSONL edits - if you closed an issue in JSONL that's still open in DB
- Merging databases - importing issues from another database with overlapping IDs
- Restoring from backup - when database state has diverged from JSONL

**What --resolve-collisions does:**
1. Detects ID conflicts (same ID, different status/content)
2. Remaps conflicting imports to new IDs
3. Updates all references and dependencies to use new IDs
4. Reports remapping (e.g., "mit-1 → bd-4")

**Without --resolve-collisions:** Import fails on first conflict.

**Example scenario:**
```bash
# You have: mit-1 (open) in database
# Importing: mit-1 (closed) from JSONL
# Result: Import creates bd-4 with closed status, preserves existing mit-1
```

---

### bd quickstart

Show comprehensive quick start guide.

```bash
bd quickstart
```

Displays built-in reference for command syntax and workflows.

---

## Web Environment: CLI Equivalents

When MCP is unavailable (web Claude Code without MCP setup), use these CLI commands for core operations:

### Translation Table

| MCP Tool | CLI Equivalent | Purpose |
|----------|---------------|---------|
| `mcp__plugin_beads_beads__ready` | `bd ready --json` | Find unblocked work |
| `mcp__plugin_beads_beads__list` | `bd list --status <status> --json` | List issues with filters |
| `mcp__plugin_beads_beads__show` | `bd show <issue-id> --json` | Show issue details |
| `mcp__plugin_beads_beads__create` | `bd create "title" [flags]` | Create new issue |
| `mcp__plugin_beads_beads__update` | `bd update <issue-id> [flags]` | Update issue fields |
| `mcp__plugin_beads_beads__close` | `bd close <issue-id> --reason "..."` | Close completed work |
| `mcp__plugin_beads_beads__reopen` | `bd reopen <issue-id> --reason "..."` | Reopen closed issue |
| `mcp__plugin_beads_beads__dep` | `bd dep add <dependent> <prerequisite>` | Add dependency |
| `mcp__plugin_beads_beads__stats` | `bd stats --json` | Project statistics |
| `mcp__plugin_beads_beads__blocked` | `bd blocked --json` | Find blocked work |

### CLI Core Command Examples

**Check ready work:**
```bash
bd ready --json                    # All ready work
bd ready --priority 0 --json       # Only critical priority
bd ready --assignee alice --json   # Only assigned to alice
```

**Create new issue:**
```bash
bd create "Fix login bug"
bd create "Add OAuth" -p 0 -t feature
bd create "Write tests" -d "Unit tests for auth" --assignee alice
bd create "Research" --design "Evaluate Redis vs Memcached"
```

**Flags:**
- `-t, --type`: task (default), bug, feature, epic, chore
- `-p, --priority`: 0-3 (default: 2)
- `-d, --description`: Problem statement
- `--design`: HOW to build (approach, architecture)
- `--acceptance`: WHAT success looks like
- `--assignee`: Who's responsible

**Update issue:**
```bash
bd update issue-123 --status in_progress
bd update issue-123 --priority 0
bd update issue-123 --assignee bob
bd update issue-123 --design "Using JWT with RS256"
bd update issue-123 --notes "COMPLETED: ...\nIN PROGRESS: ...\nNEXT: ..."
```

**Close completed work:**
```bash
bd close issue-123 --reason "Implemented in PR #42"
bd close issue-1 issue-2 issue-3 --reason "Bulk close"
```

**Show issue details:**
```bash
bd show issue-123 --json
```

Returns full issue details including notes, dependencies, history.

**List issues:**
```bash
bd list --json
bd list --status open --json
bd list --status in_progress --json
bd list --priority 0 --json
bd list --type bug --json
bd list --assignee alice --json
```

**Add dependencies:**
```bash
# blocks - DEPENDENT first, PREREQUISITE second
bd dep add auth-flow auth-setup  # auth-flow depends on auth-setup

# parent-child for epic structure
bd dep add epic-id subtask-id --type parent-child

# discovered-from for tracking provenance
bd dep add original-issue discovered-issue --type discovered-from
```

**Remove dependencies:**
```bash
bd dep remove issue-a issue-b
```

**Statistics:**
```bash
bd stats --json
bd blocked --json
```

---

## Global Flags

Available for all CLI commands:

```bash
--json                 # Output in JSON format (recommended for programmatic use)
--db /path/to/db       # Specify database path (default: auto-discover)
--actor "name"         # Actor name for audit trail
--no-daemon            # Bypass daemon (use direct mode - see notes)
```

**About --no-daemon:**
- Writes go to JSONL, reads from SQLite
- 3-5 second sync delay before queries reflect changes
- Use for: batch scripts, CI/CD, testing
- **Avoid for:** interactive work when immediate results needed

---

## Database Auto-Discovery

bd automatically selects the database:
- Uses `.beads/<prefix>.db` in current project if exists
- Falls back to `~/.beads/default.db` otherwise
- No configuration needed

**Explicit database selection:**
```bash
bd --db /path/to/project/.beads/api.db ready
```

---

## Notes for Web Environment

**SessionStart hook pattern:**

```bash
# Install bd CLI
npm install -g @beads/cli

# Initialize if needed
bd init project-prefix

# Start using bd commands
bd ready --json
```

**All SKILL.md examples show MCP tools.** To use in web environment, translate via table above.

---

## Molecule Commands (v0.34.0+)

bd v0.34.0 introduces molecules - reusable work templates with a chemistry metaphor.

### Proto Management

```bash
bd mol catalog                              # List available protos (templates)
bd mol catalog --json                       # Machine-readable
bd mol show <proto-id>                      # Show proto structure and variables
```

### Spawning Molecules

```bash
bd mol spawn <proto>                        # Create wisp (ephemeral, default)
bd mol spawn <proto> --pour                 # Create mol (persistent)
bd mol spawn <proto> --var key=value        # With variable substitution
bd mol spawn <proto> --dry-run              # Preview without creating

# Shortcuts
bd pour <proto>                             # Same as spawn --pour
bd wisp create <proto>                      # Explicit wisp creation
```

### Durable Execution

```bash
bd mol run <proto> --var version=1.0        # spawn + assign + pin
```

`mol run` spawns, assigns to caller, and pins for crash recovery. Use for work that should survive session restarts.

### Bonding (Combining)

```bash
bd mol bond A B                             # Sequential: B after A
bd mol bond A B --type parallel             # Parallel execution
bd mol bond A B --type conditional          # B runs if A fails
bd mol bond A B --as "Custom Name"          # Name compound proto
bd mol bond A B --pour                      # Force persistent spawn
bd mol bond A B --wisp                      # Force ephemeral spawn
```

### Distilling (Extract Template)

```bash
bd mol distill <epic-id> --as "Name"        # Extract proto from ad-hoc epic
bd mol distill <epic> --var value=variable  # Replace concrete values with placeholders
```

### Wisp Lifecycle

```bash
bd wisp list                                # List active wisps
bd wisp gc                                  # Garbage collect orphaned wisps
bd mol squash <wisp>                        # Compress to digest, delete children
bd mol squash <wisp> --summary "..."        # With agent-provided summary
bd mol burn <wisp>                          # Delete without trace
```

### Cross-Project Dependencies

```bash
# Ship capability from project A
bd ship <capability>                        # Publish (requires closed issue with export: label)
bd ship <capability> --force                # Publish even if not closed

# Depend on external capability in project B
bd dep add <issue> external:<project>:<capability>
```

**For detailed molecule patterns:** See references/MOLECULES.md

---

## For More Details

- **MCP tools documentation:** See main SKILL.md
- **Molecules and wisps:** See references/MOLECULES.md
- **Conceptual guidance:** See references/BOUNDARIES.md, references/PATTERNS.md
- **Workflows:** See references/WORKFLOWS.md
- **Dependency semantics:** See references/DEPENDENCIES.md
- **Troubleshooting:** See references/TROUBLESHOOTING.md
