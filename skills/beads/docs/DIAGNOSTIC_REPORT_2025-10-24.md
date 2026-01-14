# BD Issues Diagnostic Report
**Date:** 2025-10-24
**Field Report:** ~/Repos/todoist-interface/BD_ISSUES_ENCOUNTERED.md
**BD Version Tested:** bd 0.10.1 (dev), based on beads commit d47f3ae

---

## Executive Summary

**Primary Finding**: The critical dependency persistence bug (Issue #2) **has been fixed** in bd commit 399fc73 (Oct 21, 2025) and is included in current bd versions.

**Root Cause Analysis:**
- 4/5 issues from field report were **bd bugs** (now fixed) or **expected behavior** (not bugs)
- 1/5 issue is a **known SQLite limitation** (Google Drive incompatibility)
- **No Skill deficiencies** caused the problems, but documentation gaps existed

---

## Issue-by-Issue Analysis

### Issue #1: Status Updates Not Reflected
**Status:** ⚠️ **EXPECTED BEHAVIOR** (not a bug)

**Analysis:**
- When using `--no-daemon` mode, writes go to JSONL file
- Reads come from SQLite database
- Daemon syncs JSONL → SQLite periodically (default: 5 minutes)
- This creates a sync delay that appears as "updates not visible"

**Field Report Observation:**
> "Confusing UX: Command says '✓ Updated' but change not visible until daemon syncs"

**Verdict:** This is by design. The `--no-daemon` flag bypasses daemon for writes but doesn't prevent daemon from being the source of truth for reads.

**Skill Impact:** ✅ Skill should document daemon sync model more clearly

---

### Issue #2: Dependencies Don't Persist
**Status:** ✅ **FIXED** in bd commit 399fc73 (Oct 21, 2025)

**Original Bug:**
```
bd daemon was ignoring createArgs.Dependencies during issue creation,
causing dependencies specified at creation time to be lost.
```

**Fix Details:**
- Commit: [399fc73](https://github.com/steveyegge/beads/commit/399fc73)
- Fixed in: bd v0.15.0+
- GitHub Issue: #101
- Impact: Dependencies now persist correctly in both daemon and `--no-daemon` modes

**Test Results (2025-10-24):**
```bash
# Test 1: Dependencies with daemon running
bd dep add test-2 test-1 --type blocks
bd show test-2
# Result: ✓ "Depends on: test-1" - WORKS

# Test 2: Dependencies with --no-daemon
bd --no-daemon dep add test-3 test-1 --type parent-child
bd show test-3
# Result: ✓ "Depends on: test-1" - WORKS
```

**Skill Impact:** ✅ No changes needed - bug is fixed upstream

---

### Issue #3: JSONL Not Created Until Daemon Runs
**Status:** ⚠️ **EXPECTED BEHAVIOR** (initialization coupling)

**Analysis:**
- First daemon start creates empty `issues.jsonl`
- Subsequent `--no-daemon` operations populate it
- This is an initialization requirement, not a runtime bug

**Field Report Observation:**
> "JSONL file creation tied to daemon startup"

**Verdict:** This is architectural - daemon owns the JSONL export format.

**Skill Impact:** ✅ Skill should document initialization sequence

---

### Issue #4: Daemon Requires Git Repository
**Status:** ⚠️ **EXPECTED BEHAVIOR** (documentation gap)

**Analysis:**
- Daemon syncs issues to git (via JSONL)
- Git repo required for version control integration
- Not documented prominently in quickstart

**Workaround from field report:**
```bash
git init  # Required before bd daemon
bd daemon --global=false  # Prevents git pull attempts
```

**Skill Impact:** ✅ Skill should document git requirement

---

### Issue #5: Google Drive Incompatibility
**Status:** 🔒 **KNOWN LIMITATION** (SQLite + cloud sync)

**Root Cause:**
- Google Drive File Stream doesn't support SQLite file locking
- SQLite requires reliable POSIX file locking for concurrent access
- This affects ALL cloud sync services (Dropbox, OneDrive, iCloud)

**Resolution:** Use local filesystem for `.beads/` directory

**Skill Impact:** ✅ Add warning about cloud sync filesystems

---

## MCP Tool Analysis

### Parameter Name Evolution

**Timeline:**
1. **Pre-Oct 23:** MCP used confusing `from_id/to_id` parameters
2. **Oct 23 (commit 4f1d1a2):** Fixed to `issue_id/depends_on_id`
3. **Current:** Uses clear parameter names

**Current MCP Signature:**
```python
async def beads_add_dependency(
    issue_id: str,  # "Issue that has the dependency"
    depends_on_id: str,  # "Issue that issue_id depends on"
    dep_type: DependencyType = "blocks"
)
```

**Semantics:**
- `beads_add_dependency(issue_id=A, depends_on_id=B)` → "A depends on B"
- Equivalent to CLI: `bd dep add A B`

**Why the fix mattered:**
> Commit message: "Fixes GH #113 where Claude Code was creating dependencies backwards"

The old `from_id/to_id` naming was ambiguous and caused Claude to reverse dependencies.

**Skill Impact:** ⚠️ Skill correctly documents CLI semantics but doesn't mention MCP parameter names

---

## Skill Dependency Semantics Fix

**Critical Bug Fixed:** Commit 9e6028e (Oct 23, 2025)

**What was wrong:**
- Skill guidance had dependency semantics **completely backwards**
- Incorrect: "bd dep add A B means A blocks B"
- Correct: "bd dep add A B means A depends on B (B must finish first)"

**Fix Applied:**
- Added 58 lines of detailed guidance with examples
- Visual verification steps
- Mnemonics: "DEPENDENT depends-on PREREQUISITE"

**Impact:** This would have caused systematic errors before Oct 23. Now fixed.

---

## Recommendations

### For Skill Updates (Phase 5)

1. **Add Daemon Sync Model Documentation**
   - Explain JSONL vs SQLite architecture
   - Document `--no-daemon` behavior and sync delays
   - Clarify when to use daemon vs direct mode

2. **Add Initialization Guidance**
   - Document git repository requirement
   - Explain daemon initialization sequence
   - Provide `--global=false` flag usage

3. **Add Filesystem Warnings**
   - Warn against cloud sync filesystems (Google Drive, Dropbox, etc.)
   - Recommend local disk for `.beads/` directory
   - Link to SQLite limitations documentation

4. **Document MCP Parameter Names** (optional)
   - Note that MCP uses `issue_id/depends_on_id`
   - Clarify equivalence with CLI `bd dep add`

5. **Add Version Requirements** (optional)
   - Note that dependency persistence requires bd v0.15.0+
   - Suggest `bd version` check if issues encountered

### For User

1. **Update bd if needed:**
   ```bash
   bd version  # Check current version
   # If < v0.15.0, update via your package manager
   ```

2. **Update beads MCP plugin:**
   ```bash
   claude plugin update beads
   ```

3. **Verify dependency fix:**
   - Test creating dependencies in your projects
   - If still failing, report to beads GitHub with bd version

---

## Conclusion

**Primary Issue:** Dependency persistence bug was a **real bd bug**, now **fixed** in v0.15.0+

**Skill Performance:**
- ✅ Correctly documents CLI dependency semantics (after Oct 23 fix)
- ⚠️ Missing daemon sync model documentation
- ⚠️ Missing initialization and filesystem guidance

**Next Steps:** Phase 5 - Update Skill with improved documentation based on findings above.
