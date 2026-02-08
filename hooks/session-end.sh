#!/bin/bash
#
# Session End Hook
# Indexes session, extracts entities, and scans handoffs/beads for memory.
#
# Lives in: claude-suite/hooks/
# Symlinked from: ~/.claude/hooks/session-end.sh
#
# Uses full daemonization to prevent terminal corruption.
#

# Skip for subagent invocations — prevents recursive fork bomb
# (mem backfill spawns claude -p → exit fires session-end → spawns more mem)
[ -n "${MEM_SUBAGENT:-}" ] && exit 0
[ -n "${CLAUDE_SUBAGENT:-}" ] && exit 0

LOG_DIR="$HOME/.claude/extraction-logs"
ENV_FILE="$HOME/.claude/memory/env"
MEM_PROJECT="$HOME/Repos/claude-mem"

mkdir -p "$LOG_DIR"

# Require jq for reliable JSON parsing (don't silently fall back to racy ls -t)
if ! command -v jq &>/dev/null; then
    echo "[session-end] ERROR: jq required but not found" >> "$LOG_DIR/hook-errors.log"
    exit 1
fi

# Read hook input from stdin (JSON with session_id, transcript_path, etc.)
HOOK_INPUT=$(cat)

# Extract transcript_path from JSON input (reliable, no race condition)
LATEST_SESSION=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty')

# Fallback to ls -t if no transcript_path (shouldn't happen, but defensive)
if [ -z "$LATEST_SESSION" ] || [ ! -f "$LATEST_SESSION" ]; then
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    PROJECT_SLUG=$(echo "$PROJECT_DIR" | sed 's|/|-|g')
    SESSIONS_DIR="$HOME/.claude/projects/$PROJECT_SLUG"
    LATEST_SESSION=$(ls -t "$SESSIONS_DIR"/*.jsonl 2>/dev/null | head -1)
fi

if [ -z "$LATEST_SESSION" ]; then
    exit 0
fi

SESSION_NAME=$(basename "$LATEST_SESSION" .jsonl)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/${TIMESTAMP}-${SESSION_NAME}.log"

# Full daemonization: nohup + stdin/stdout/stderr redirected + disown
# This prevents terminal corruption
nohup bash -c '
    LOG_FILE="$1"
    LATEST_SESSION="$2"
    ENV_FILE="$3"
    MEM_PROJECT="$4"
    ERROR_LOG="$HOME/.claude/extraction-errors.log"

    {
        echo "=== Extraction started: $(date) ==="
        echo "Session: $LATEST_SESSION"
        echo ""
    } >> "$LOG_FILE"

    # Source API key
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi

    # Run mem process (index + extract session)
    cd "$MEM_PROJECT" && uv run mem process --quiet "$LATEST_SESSION" >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?

    # Also index handoffs and beads (written during /close)
    # TODO: Add --source arc when mem supports it
    echo "" >> "$LOG_FILE"
    echo "=== Scanning handoffs and beads ===" >> "$LOG_FILE"
    cd "$MEM_PROJECT" && uv run mem scan --source handoffs --source beads >> "$LOG_FILE" 2>&1 || true

    # Nibble at unprocessed Meeting Notes (local_md source)
    # Rate: ~10 per session, ~50/day at 5 sessions/day
    echo "" >> "$LOG_FILE"
    echo "=== Nibbling local_md backlog ===" >> "$LOG_FILE"
    cd "$MEM_PROJECT" && uv run mem backfill --limit 10 --source-type local_md >> "$LOG_FILE" 2>&1 || true

    echo "" >> "$LOG_FILE"

    if [ $EXIT_CODE -ne 0 ]; then
        echo "=== FAILED (exit $EXIT_CODE): $(date) ===" >> "$LOG_FILE"
        # Rename to .FAILED.log for visibility
        mv "$LOG_FILE" "${LOG_FILE%.log}.FAILED.log"
        # Also append to central error log
        echo "[$(date)] FAILED: $LATEST_SESSION (exit $EXIT_CODE)" >> "$ERROR_LOG"
    else
        echo "=== Extraction completed: $(date) ===" >> "$LOG_FILE"
    fi
' -- "$LOG_FILE" "$LATEST_SESSION" "$ENV_FILE" "$MEM_PROJECT" </dev/null >/dev/null 2>&1 &

disown 2>/dev/null || true

exit 0
