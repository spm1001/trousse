#!/bin/bash
#
# Session Start Hook
# Outputs session context to stdout (Claude sees this automatically)
# Runs heavy updates in background (no stdout)
#
# Design: fast and graceful. If this fires in a subagent by accident,
# the cost should be negligible — no guards needed.
#
# Lives in: claude-suite/hooks/
# Symlinked from: ~/.claude/hooks/session-start.sh

set -euo pipefail

SCRIPTS_DIR="$HOME/.claude/scripts"

# === CONTEXT OUTPUT (stdout → Claude) ===

CONTEXT_SCRIPT="$SCRIPTS_DIR/open-context.sh"
if [ -x "$CONTEXT_SCRIPT" ]; then
    "$CONTEXT_SCRIPT" 2>/dev/null || true
fi

# Check for incomplete /close from previous session
CHECKPOINT_FILE="$HOME/.claude/.close-checkpoint"
if [ -f "$CHECKPOINT_FILE" ]; then
    echo ""
    echo "=== INCOMPLETE CLOSE ==="
    echo "WARNING: Last session's /close was interrupted."
    echo ""
    cat "$CHECKPOINT_FILE"
    echo ""
    echo "Run '/close --resume' to complete, or delete checkpoint to ignore."
fi

# === BACKGROUND UPDATES (no stdout) ===
UPDATE_SCRIPT="$HOME/.claude/scripts/update-all.sh"
if [ -x "$UPDATE_SCRIPT" ]; then
    nohup "$UPDATE_SCRIPT" > /dev/null 2>&1 &
fi

exit 0
