# Cross-Project Beads Portfolio

View and triage beads across all projects in a single session.

## When to Use

- **Weekly review** — See what's active, ready, and stalled across all projects
- **Context switching** — Decide where to focus next
- **Audit/cleanup** — Find skeleton beads, stale projects, quality issues
- **Planning** — Understand workload distribution

## Quick Start

```bash
# Summary view (default)
bd-portfolio.sh

# Full view with details
bd-portfolio.sh --format full

# Filter to specific projects
bd-portfolio.sh --filter "infra-*"

# JSON for programmatic use
bd-portfolio.sh --format json

# Markdown export for reports
bd-portfolio.sh --format markdown > report.md

# Drill down to skeleton beads
bd-portfolio.sh skeletons
bd-portfolio.sh skeletons infra-openwrt
```

**Note:** Script is at `~/.claude/skills/beads/scripts/bd-portfolio.sh`

## Output Formats

### Summary (default)
Compact one-line-per-category view:

```
Beads Portfolio — 48 open across 10 projects

Active: infra-openwrt, mcp-google-workspace
Ready: itv-linkedin-analytics, claude-memory
Stalled: infra-signboard, infra-linux-servers

12 skeleton beads need attention
```

### Full
Detailed breakdown with counts:

```
=== Beads Portfolio ===

Totals: 48 open, 58 closed, 2 in progress
Warning: 12 skeleton beads (empty shells)

ACTIVE (work in progress):
  infra-openwrt: 1 in_progress, 10 ready
  mcp-google-workspace: 1 in_progress, 5 ready

READY (P1-P2 work available):
  itv-linkedin-analytics: P1=0 P2=5 (5 ready)

STALLED (P3 only):
  infra-signboard: 6 open (all P3)

DORMANT (all closed):
  mcp-search-myitv: 6 closed

QUALITY ISSUES (skeleton beads):
  infra-linux-servers: 12 empty shells
```

### JSON
Structured data for Claude to process:

```json
{
  "totals": {
    "open": 48,
    "closed": 58,
    "in_progress": 2,
    "skeletons": 12,
    "projects": 10
  },
  "by_category": {
    "active": [...],
    "ready": [...],
    "stalled": [...],
    "dormant": [...]
  },
  "all_projects": [...]
}
```

### Markdown
Export for reports and documentation:

```markdown
# Beads Portfolio Report

_Generated: 2025-12-30_

## Summary

| Metric | Count |
|--------|-------|
| Projects | 22 |
| Open beads | 80 |
...
```

Use `--format markdown > report.md` to save.

## Categories

| Category | Meaning | Action |
|----------|---------|--------|
| **Active** | Has `in_progress` beads | Continue current work |
| **Ready** | Has P1 or P2 open beads, nothing in_progress | Pick up when switching |
| **Stalled** | Only P3 open beads | Parked intentionally or needs triage |
| **Dormant** | All beads closed | Complete or abandoned |

## Quality Checks

### Skeleton Detection
A bead is flagged as a "skeleton" if:
- Status is `open`
- Description is empty or null
- Design is empty, null, or only contains the DRAW-DOWN workflow template

Skeletons look organized but aren't workable — they need investigation before execution.

### Interpreting Quality Warnings

```
QUALITY ISSUES (skeleton beads):
  infra-linux-servers: 12 empty shells
```

This means 12 beads in that project are titles-only. Options:
1. **Flesh out** — Add descriptions, acceptance criteria
2. **Close** — If work moved elsewhere or abandoned
3. **Delete** — If truly obsolete

## Workflow: Weekly Review

1. Run portfolio summary:
   ```bash
   ~/.claude/skills/beads/scripts/bd-portfolio.sh ~/Repos full
   ```

2. Review categories:
   - **Active** — Is this still the right focus?
   - **Ready** — Anything that should be active?
   - **Stalled** — Intentional or neglected?
   - **Quality** — Address skeleton beads

3. For each project needing attention:
   ```bash
   cd ~/Repos/<project>
   bd ready
   bd list --status open --json | jq '.[] | "\(.id): \(.title)"'
   ```

4. Take action:
   - Reprioritize (`bd update <id> --priority N`)
   - Close stale beads (`bd close <id> --resolution "..."`)
   - Flesh out skeletons (`bd update <id> --description "..." --design "..."`)

## Workflow: Context Switch Decision

When deciding what to work on next:

```bash
# See the landscape
~/.claude/skills/beads/scripts/bd-portfolio.sh ~/Repos json | jq '.by_category.ready'

# Pick a project, drill in
cd ~/Repos/<chosen-project>
bd ready
```

## Integration with Session Management

**At /open:** Portfolio can inform where to focus
**At /close:** Portfolio shows impact of session's work
**At /ground:** Portfolio helps reset if drifted into wrong project

## Filtering

Filter to specific projects with glob patterns:

```bash
# Only infrastructure projects
bd-portfolio.sh --filter "infra-*"

# Only skills
bd-portfolio.sh --filter "skill-*"

# Only ITV projects
bd-portfolio.sh --filter "itv-*"
```

## Skeleton Drill-Down

The `skeletons` command lists actual skeleton beads (not just counts):

```bash
# All skeletons across all projects
bd-portfolio.sh skeletons

# Skeletons in specific project
bd-portfolio.sh skeletons infra-openwrt
```

Output:
```
Skeleton beads in infra-openwrt:
  [2] infra-openwrt-mnx: Implement nginx reverse proxy
  [2] infra-openwrt-vvy: Re-enable 802.11r after guests leave
  [3] infra-openwrt-57w: OpenWRT Firmware Upgrade Strategy
```

The `[N]` prefix shows priority. Use this to decide which skeletons to flesh out or close.

## Customizing

The script accepts options:

```bash
# Scan different location
bd-portfolio.sh --dir ~/Work --format full

# Combine options
bd-portfolio.sh --dir ~/Repos --filter "mcp-*" --format json
```

## Troubleshooting

**"No .beads directories found"**
- Check the path exists and contains git repos with bd initialized
- Ensure you have read permissions

**Slow performance**
- Script runs `bd list` and `bd ready` per project
- Many projects = proportional time
- JSON output is fastest (no color processing)

**Missing projects**
- Script excludes `.git/` subdirectories and `beads-worktrees`
- Only finds directories named exactly `.beads`
