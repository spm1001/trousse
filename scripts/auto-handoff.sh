#!/bin/bash
# Auto-handoff: mechanical safety net for sessions that end without /close
#
# Called by session-end.sh when no handoff was written by /close.
# Generates a minimal handoff from git + arc state so the next session
# gets *something* rather than a cold start.
#
# The (auto) marker in the header tells /open this was mechanical,
# not reflective — gotchas/risks sections are absent.
#
# Usage: auto-handoff.sh <cwd> <session_id>

set -euo pipefail

CWD="${1:-$(pwd -P)}"
SESSION_ID="${2:-}"

[ -z "$SESSION_ID" ] && exit 0

# Encoded path always starts with '-' — never use as bare arg; always prefix with absolute path
ENCODED=$(echo "$CWD" | sed 's/[^a-zA-Z0-9-]/-/g')
HANDOFF_DIR="$HOME/.claude/handoffs/$ENCODED"

# If /close already wrote a handoff for this session, skip
if ls "$HANDOFF_DIR"/*.md 2>/dev/null | xargs grep -l "session_id: $SESSION_ID" >/dev/null 2>&1; then
    exit 0
fi

# Also check by filename (first 8 chars of session ID)
SHORT_ID="${SESSION_ID:0:8}"
if [ -f "$HANDOFF_DIR/${SHORT_ID}.md" ]; then
    exit 0
fi

mkdir -p "$HANDOFF_DIR"

# --- Gather context ---

DATE=$(date '+%Y-%m-%d')

# Recent git commits (approximate session work)
GIT_DONE=""
if [ -e "$CWD/.git" ]; then
    GIT_DONE=$(git -C "$CWD" log --oneline --since="8 hours ago" 2>/dev/null | head -10 || true)
fi

# Arc open/ready items
ARC_NEXT=""
ARC_READ="$HOME/.claude/scripts/arc-read.sh"
if [ -f "$CWD/.arc/items.jsonl" ]; then
    if [ -x "$ARC_READ" ]; then
        ARC_NEXT=$(cd "$CWD" && "$ARC_READ" ready 2>/dev/null || true)
    elif command -v jq &>/dev/null; then
        ARC_NEXT=$(jq -r 'select(.status == "open" and (.waiting_for == null or .waiting_for == "")) | "- \(.title) (\(.id))"' "$CWD/.arc/items.jsonl" 2>/dev/null | head -10 || true)
    fi
fi

# Purpose line: last commit subject or generic
PURPOSE=""
if [ -n "$GIT_DONE" ]; then
    PURPOSE=$(echo "$GIT_DONE" | head -1 | cut -d' ' -f2-)
else
    PURPOSE="Session ended without /close"
fi

# --- Write handoff ---

HANDOFF_FILE="$HANDOFF_DIR/${SHORT_ID}.md"

{
    echo "# Handoff — $DATE (auto)"
    echo ""
    echo "session_id: $SESSION_ID"
    echo "purpose: $PURPOSE"
    echo ""
    echo "## Done"
    if [ -n "$GIT_DONE" ]; then
        echo "$GIT_DONE" | while IFS= read -r line; do
            echo "- $line"
        done
    else
        echo "- (no commits detected in session)"
    fi
    echo ""
    echo "## Next"
    if [ -n "$ARC_NEXT" ]; then
        echo "$ARC_NEXT" | while IFS= read -r line; do
            [ -n "$line" ] && echo "- $line"
        done
    else
        echo "- (check arc or project state)"
    fi
    echo ""
    echo "## Gotchas"
    echo "- Auto-generated handoff — no reflective close was performed"
} > "$HANDOFF_FILE"
