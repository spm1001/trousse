#!/bin/bash
# Consolidated context gathering for /close
# Outputs structured sections for Claude to parse

set -euo pipefail

# === SELF-VALIDATION ===
# Check critical dependencies before running. Fail fast with clear messages.
validate_dependencies() {
    local missing=""

    # jq: required for JSON parsing of beads output
    if ! command -v jq &>/dev/null; then
        missing="$missing jq(brew install jq)"
    fi

    if [ -n "$missing" ]; then
        echo "=== SCRIPT_ERROR ==="
        echo "ERROR: close-context.sh missing dependencies:$missing"
        echo "Install missing tools and retry."
        echo "SCRIPT_FAILED=true"
        exit 1
    fi
}

validate_dependencies

# === TIME ===
echo "=== TIME ==="
CURRENT_HOUR=$(date +%H)
CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_TIME=$(date '+%H:%M')

if [ "$CURRENT_HOUR" -lt 12 ]; then
    TIME_OF_DAY="morning"
elif [ "$CURRENT_HOUR" -lt 17 ]; then
    TIME_OF_DAY="afternoon"
elif [ "$CURRENT_HOUR" -lt 21 ]; then
    TIME_OF_DAY="evening"
else
    TIME_OF_DAY="night"
fi

echo "NOW=$CURRENT_DATE $CURRENT_TIME"
echo "TIME_OF_DAY=$TIME_OF_DAY"
echo "YEAR=$(date +%Y)"
echo ""

# === GIT STATUS ===
echo "=== GIT ==="
if [ -d ".git" ]; then
    DIRTY=$(git status --porcelain 2>/dev/null || true)
    UNPUSHED=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    LAST_MSG=$(git log -1 --format='%s' 2>/dev/null || echo "")

    if [ -n "$DIRTY" ]; then
        FILE_COUNT=$(echo "$DIRTY" | wc -l | tr -d ' ')
        echo "UNCOMMITTED=$FILE_COUNT"
        echo "FILES:"
        echo "$DIRTY" | head -10
    else
        echo "UNCOMMITTED=0"
    fi

    echo "UNPUSHED=$UNPUSHED"
    [ -n "$LAST_MSG" ] && echo "LAST_COMMIT=$LAST_MSG"
    echo "GIT_EXISTS=true"
else
    echo "GIT_EXISTS=false"
fi

# === ARC STATUS (default tracker) ===
echo ""
echo "=== ARC ==="
if [ -d ".arc" ]; then
    # Find arc CLI - check PATH first, then known location
    ARC_CMD=$(command -v arc 2>/dev/null || echo "$HOME/Repos/arc/.venv/bin/arc")

    if [ -x "$ARC_CMD" ]; then
        # Arc doesn't track in_progress, but we can show open and waiting items
        OPEN_OUTPUT=$("$ARC_CMD" list 2>/dev/null || true)
        OPEN_COUNT=$(echo "$OPEN_OUTPUT" | grep -c "^○" 2>/dev/null) || OPEN_COUNT=0
        WAITING_COUNT=$(echo "$OPEN_OUTPUT" | grep -c "^⏳" 2>/dev/null) || WAITING_COUNT=0

        echo "OPEN_COUNT=$OPEN_COUNT"
        echo "WAITING_COUNT=$WAITING_COUNT"
        if [ -n "$OPEN_OUTPUT" ]; then
            echo "ITEMS:"
            echo "$OPEN_OUTPUT" | head -15
        fi
        echo "ARC_EXISTS=true"
    else
        echo "ARC_EXISTS=false"
        echo "ARC_ERROR=cli_not_found"
    fi
else
    echo "ARC_EXISTS=false"
fi

# === BEADS STATUS (legacy tracker) ===
echo ""
echo "=== BEADS ==="
if [ -d ".beads" ] && command -v bd >/dev/null 2>&1; then
    IN_PROGRESS=$(bd list --status in_progress --json 2>/dev/null | jq -r '.[] | "\(.id): \(.title)"' 2>/dev/null || true)
    OPEN_COUNT=$(bd list --status open --json 2>/dev/null | jq -r 'length' 2>/dev/null || echo "0")

    if [ -n "$IN_PROGRESS" ]; then
        echo "IN_PROGRESS:"
        echo "$IN_PROGRESS"
    else
        echo "IN_PROGRESS=0"
    fi
    echo "OPEN_COUNT=$OPEN_COUNT"
    echo "BEADS_EXISTS=true"
else
    echo "BEADS_EXISTS=false"
fi

# === WORK LOCATION DETECTION ===
echo ""
echo "=== LOCATION ==="
CWD=$(pwd -P)  # -P resolves symlinks for consistent encoding

# Check if cwd is a container directory
# Uses [[ ]] for glob pattern matching (case doesn't expand globs)
is_container() {
    [[ "$1" == "$HOME/Repos" ]] && return 0
    [[ "$1" == "$HOME/.claude" ]] && return 0
    [[ "$1" == "$HOME/Library/CloudStorage/GoogleDrive-"*"/My Drive/Work" ]] && return 0
    return 1
}

ENCODED_PATH=$(echo "$CWD" | tr '/.' '-')
HANDOFF_DIR="$HOME/.claude/handoffs/$ENCODED_PATH"

# Always output HANDOFF_DIR - even containers need handoffs
echo "HANDOFF_DIR=$HANDOFF_DIR"

if is_container "$CWD"; then
    echo "IS_CONTAINER=true"
    echo "CWD=$CWD"

    # Find repos with today's commits
    echo "RECENT_WORK:"
    for dir in "$HOME/Repos"/* "$HOME/.claude"; do
        if [ -d "$dir/.git" ]; then
            if git -C "$dir" log --since="midnight" --oneline 2>/dev/null | head -1 | grep -q .; then
                echo "  $dir"
            fi
        fi
    done
else
    echo "IS_CONTAINER=false"
    echo "CWD=$CWD"
    echo "HANDOFF_TARGET=$CWD"
fi

# === DATE ===
echo ""
echo "=== META ==="
echo "TODAY=$(date +%Y-%m-%d)"
