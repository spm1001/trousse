# Error Pattern Library

A reference for Claude to diagnose common errors quickly. When you see an error, check this library before investigating from scratch.

---

## Exit Codes

| Exit Code | Meaning | Common Cause | Diagnosis |
|-----------|---------|--------------|-----------|
| **127** | Command not found | Broken symlink, missing binary, PATH issue | Check if file exists: `ls -la <path>`. If symlink, check target: `readlink <path>` then `ls -la <target>` |
| **126** | Permission denied / not executable | Missing +x permission, directory instead of file | Run `chmod +x <file>` or check if it's actually a directory |
| **1** | General error | Script-specific failure | Read the error message; check script's stderr |
| **2** | Misuse of shell builtin | Syntax error, wrong arguments | Check command syntax |
| **128+N** | Fatal signal N | Process killed (e.g., 137 = SIGKILL/OOM) | Check system resources, memory |
| **130** | Script terminated by Ctrl+C | User interrupt | Normal, not an error |
| **255** | Exit status out of range | Usually SSH connection failure | Check network, SSH config |

---

## Symlink Failures

### Pattern: "no such file or directory" but file exists

**Symptom:**
```
(eval):1: no such file or directory: /path/to/script.sh
```

**Cause:** The path is a symlink pointing to a non-existent target.

**Diagnosis:**
```bash
ls -la /path/to/script.sh          # Shows symlink -> target
ls -la <target>                     # This will fail
```

**Fix:** Update symlink to point to correct location:
```bash
rm /path/to/script.sh
ln -s /correct/target.sh /path/to/script.sh
```

**Prevention:** Run `~/.claude/scripts/check-symlinks.sh` regularly.

### Pattern: Symlinks break after repo rename

**Symptom:** Multiple scripts fail after a repo was renamed on GitHub or locally.

**Cause:** Symlinks encode the old repo name in their target path.

**Diagnosis:**
```bash
# Find all symlinks pointing to old name
find ~/.claude -type l -exec sh -c 'readlink "$1" | grep -q "old-name" && echo "$1"' _ {} \;
```

**Fix:** Update each symlink to new path.

**Lesson (Jan 2026):** When renaming repos, immediately audit symlinks. The claude-modus → claude-suite rename caused 7 days of silent failures.

---

## Script Failures

### Pattern: Script runs but outputs nothing

**Symptom:** Script exits 0 but expected output is missing.

**Cause:** Often `set -e` combined with a failing command that's being silenced.

**Diagnosis:**
```bash
bash -x /path/to/script.sh    # Trace execution
```

### Pattern: Script fails with "jq: command not found"

**Symptom:**
```
/path/to/script.sh: line 42: jq: command not found
```

**Cause:** Missing dependency.

**Fix:**
```bash
brew install jq    # macOS
apt install jq     # Linux
```

**Prevention:** Scripts should self-validate dependencies at startup.

### Pattern: "bd: command not found" but bd is installed

**Symptom:** bd works in terminal but not in scripts/hooks.

**Cause:** PATH differs between interactive shell and script execution.

**Diagnosis:**
```bash
which bd                    # Interactive
/bin/bash -c 'which bd'    # Non-interactive
```

**Fix:** Use full path in scripts: `/opt/homebrew/bin/bd` or ensure PATH is set.

---

## MCP Failures

### Pattern: "MCP X needs authentication"

**Symptom:** Tool call fails with authentication error.

**Cause:** MCP servers don't inherit shell environment variables (they're spawned directly, not through login shell).

**Diagnosis:** Check if the MCP uses env vars for auth.

**Fix:** Use a wrapper script that loads secrets at runtime. See `~/.claude/scripts/todoist-mcp.sh` for the pattern.

### Pattern: MCP works in one project but not another

**Symptom:** Same MCP behaves differently per project.

**Cause:** Project-local `.mcp.json` overriding global config.

**Diagnosis:**
```bash
cat .mcp.json                    # Project config
cat ~/.claude.json | jq '.mcpServers'  # Global config
```

---

## Beads/bd Failures

### Pattern: "bd: database locked"

**Symptom:** bd commands hang or fail with lock error.

**Cause:** Another bd process or daemon holding the lock.

**Fix:**
```bash
bd daemon --stop
bd <your-command>
```

### Pattern: bd in Google Drive = corruption

**Symptom:** Beads database errors, missing issues, weird state.

**Cause:** SQLite + cloud sync = race conditions and corruption.

**Prevention:** Never use bd in cloud-synced folders (Google Drive, Dropbox, iCloud Drive).

---

## Git Hook Failures

### Pattern: Hook runs but output not visible

**Symptom:** Hook script executes but Claude doesn't see the output.

**Cause:** Output going to wrong stream, or hook config incorrect.

**Diagnosis:**
```bash
# Check hook config
jq '.hooks' ~/.claude/settings.json

# Test hook manually
~/.claude/hooks/session-start.sh
```

### Pattern: "hookSpecificOutput" not working

**Symptom:** Custom hook output not appearing in Claude's context.

**Cause:** JSON format incorrect for hookSpecificOutput.

**Fix:** Ensure output is valid JSON:
```bash
echo '{"hookSpecificOutput": {"key": "value"}}'
```

---

## Memory/claude-mem Failures

### Pattern: "uv: command not found" in memory operations

**Cause:** uv not installed or not in PATH.

**Fix:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Pattern: Memory search returns nothing

**Diagnosis:**
```bash
# Check database exists and has content
sqlite3 ~/.claude/memory/memory.db "SELECT COUNT(*) FROM sources"

# Check if indexing is running
ls -la ~/.claude/memory/
```

---

## Diagnosis Workflow

When you encounter an error:

1. **Read the error message** — often contains the answer
2. **Check exit code** — see table above
3. **Check this library** — pattern match against known issues
4. **Run claude-doctor** — `~/.claude/scripts/claude-doctor.sh`
5. **Trace execution** — `bash -x script.sh` for shell scripts
6. **Check symlinks** — `ls -la` to see if symlinks are broken
7. **Search memory** — "have we seen this before?" via mem skill

---

## Behavioral Failures (Jan 2026 Analysis)

These aren't infrastructure errors but Claude behavioral patterns that cause session failures. Identified by analyzing 13 sessions with working /open infrastructure.

### Pattern: Draw-down skipped on continuation phrases

**Symptom:** User says "continue X" or "keep going" → Claude continues existing work without checking scope → Frustration when work doesn't match expectations.

**Example (session 18b750f7):**
- User: "continue backfill"
- Claude interpreted: "run the existing backfill script"
- User expected: "complete the epic goal (files + Drive links + URL shortcuts)"
- Discovery: 1 hour later, "argh - it was supposed to be a complete pass"

**Cause:** Draw-down only triggered on explicit "let's work on bead X", not continuation phrases.

**Fix:** Updated /open and beads skills (Jan 2026). Draw-down now triggers on:
- Continuation phrases ("continue", "keep going", "pick up where we left off")
- External briefs (user provides spec from elsewhere)
- Ambiguous references ("the email thing")

**Prevention:** The test: "If work will take >10 minutes, it needs TodoWrite items."

### Pattern: Skill loading primes misinterpretation

**Symptom:** Loading a skill biases Claude's interpretation of subsequent requests.

**Example (session 2649c63d):**
- User: "load todoist-gtd then refactor beads into proper epics"
- Claude proposed: Move beads to Todoist (wrong)
- User corrected: "no - they stay here, just group them under an epic"

**Cause:** Loading todoist-gtd activated "where does work belong?" framing, causing Claude to interpret "proper epics" as "Todoist is proper" instead of "well-structured within bd".

**Fix:** Added warning to /open skill Gate section. When todoist-gtd is loaded, stay anchored to user's explicit tool references ("the beads", "in bd").

**Prevention:** Offer skills, don't auto-load. When skills are loaded, note that they may bias interpretation.

### Pattern: Premature victory declaration

**Symptom:** Claude marks work complete, bead closed, todos cleared → User tests → Bug still exists → Second debugging phase has no checkpoints.

**Example (session a9b66c4):**
- Claude: "Bug fix complete and deployed" → closed bead, cleared todos
- User test: Bug still exists
- Second debugging phase: No TodoWrite, no handoff written

**Cause:** Declared victory before user verification.

**Prevention:** Don't close bead until user confirms fix works. When reopening investigation, recreate TodoWrite items.

### Pattern: Session starts without /open

**Symptom:** Session starts with ad-hoc request ("look around this repo") → No systematic orientation → More vulnerable when things go wrong.

**Example (session 35d46583):**
- Started with "please look around this repo"
- No handoff review (there was one from Dec 27)
- MCP failure consumed 40 minutes
- Productive work only started after troubleshooting

**Cause:** User skipped /open, Claude didn't prompt for it.

**Prevention:** When session starts ad-hoc, offer: "Want me to run /open first to check for handoffs and context?"

---

## Adding to This Library

When you discover a new error pattern:

1. Document: symptom, cause, diagnosis, fix
2. Add prevention mechanism if possible
3. Reference the incident date for historical context

This library is institutional memory — future Claudes benefit from your debugging.
