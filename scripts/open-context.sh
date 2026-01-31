#!/bin/bash
# Session context gathering
# Pattern: notifications to stdout, content to disk
# Claude reads files on demand (via /open or naturally)

set -euo pipefail

# === PATHS ===
BASE_CONTEXT_DIR="$HOME/.claude/.session-context"
CWD=$(pwd -P)
ENCODED_PATH=$(echo "$CWD" | tr '/.' '-')
CONTEXT_DIR="$BASE_CONTEXT_DIR/$ENCODED_PATH"
mkdir -p "$CONTEXT_DIR"

# === SELF-VALIDATION ===
validate_dependencies() {
    local missing=""
    if ! command -v jq &>/dev/null; then
        missing="$missing jq(brew install jq)"
    fi
    if ! command -v stat &>/dev/null; then
        missing="$missing stat"
    fi
    if [ -n "$missing" ]; then
        echo "ERROR: missing dependencies:$missing"
        exit 1
    fi
}
validate_dependencies

# === HELPERS ===
time_ago() {
    local seconds=$1
    local timestamp=$2
    local absolute=$(date -r "$timestamp" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$timestamp" '+%Y-%m-%d %H:%M' 2>/dev/null)
    local relative
    if [ "$seconds" -lt 3600 ]; then
        local mins=$((seconds / 60))
        [ "$mins" -le 1 ] && relative="just now" || relative="${mins}m ago"
    elif [ "$seconds" -lt 86400 ]; then
        local hours=$((seconds / 3600))
        relative="${hours}h ago"
    elif [ "$seconds" -lt 172800 ]; then
        relative="yesterday"
    else
        local days=$((seconds / 86400))
        relative="${days}d ago"
    fi
    echo "$relative ($absolute)"
}

# === BEGIN OUTPUT ===
echo "=== SESSION ==="

# --- TIME ---
CURRENT_HOUR=$(date +%H)
if [ "$CURRENT_HOUR" -lt 12 ]; then
    TIME_OF_DAY="morning"
elif [ "$CURRENT_HOUR" -lt 17 ]; then
    TIME_OF_DAY="afternoon"
elif [ "$CURRENT_HOUR" -lt 21 ]; then
    TIME_OF_DAY="evening"
else
    TIME_OF_DAY="night"
fi
echo "NOW=$(date '+%Y-%m-%d %H:%M') ($TIME_OF_DAY)"
echo "YEAR=$(date +%Y)"

# --- LOCAL HANDOFF WARNING ---
# find returns 0 even with no matches (unlike ls with glob), safe with pipefail
LOCAL_HANDOFFS=$(find . -maxdepth 1 -name '.handoff*' 2>/dev/null | wc -l)
if [ "$LOCAL_HANDOFFS" -gt 0 ]; then
    echo "⚠️  Orphaned: $LOCAL_HANDOFFS local .handoff* files (should move to ~/.claude/handoffs/)"
fi

# --- HANDOFFS ---
ARCHIVE_DIR="$HOME/.claude/handoffs"
NOW=$(date +%s)
PROJECT_FOLDER="$ARCHIVE_DIR/$ENCODED_PATH"
HANDOFF_INDEX="$CONTEXT_DIR/handoffs.txt"

if [ -d "$PROJECT_FOLDER" ]; then
    HANDOFF_FILES=$(ls -t "$PROJECT_FOLDER"/*.md 2>/dev/null || true)
    HANDOFF_COUNT=$(echo "$HANDOFF_FILES" | grep -c . 2>/dev/null || echo 0)

    if [ "$HANDOFF_COUNT" -gt 0 ]; then
        # Write index file with metadata
        echo "# Generated for: $CWD" > "$HANDOFF_INDEX"
        echo "" >> "$HANDOFF_INDEX"
        echo "$HANDOFF_FILES" | while IFS= read -r f; do
            [ -z "$f" ] && continue
            FILE_TIME=$(stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f" 2>/dev/null)
            SECONDS_AGO=$((NOW - FILE_TIME))
            TIME_STR=$(time_ago $SECONDS_AGO $FILE_TIME)
            FILENAME=$(basename "$f" .md)
            PURPOSE=$(grep "^purpose:" "$f" 2>/dev/null | head -1 | cut -d: -f2- | xargs || true)
            if [ -z "$PURPOSE" ]; then
                PURPOSE=$(grep -A1 "^## Done" "$f" 2>/dev/null | tail -1 | sed 's/^- //' | cut -c1-50 || true)
            fi
            [ -z "$PURPOSE" ] && PURPOSE="(no summary)"
            echo "$FILENAME | $TIME_STR | $PURPOSE" >> "$HANDOFF_INDEX"
            echo "PATH:$f" >> "$HANDOFF_INDEX"
        done

        # Get most recent for notification
        LATEST_FILE=$(echo "$HANDOFF_FILES" | head -1)
        LATEST_TIME=$(stat -f '%m' "$LATEST_FILE" 2>/dev/null || stat -c '%Y' "$LATEST_FILE" 2>/dev/null)
        LATEST_AGO=$((NOW - LATEST_TIME))
        LATEST_STR=$(time_ago $LATEST_AGO $LATEST_TIME)

        echo "📋 Handoffs: $HANDOFF_COUNT available, latest $LATEST_STR"
        echo "   Index: $HANDOFF_INDEX"
        echo "   Dir: $PROJECT_FOLDER"
    else
        echo "📋 Handoffs: none"
        rm -f "$HANDOFF_INDEX"
    fi
else
    echo "📋 Handoffs: none"
    rm -f "$HANDOFF_INDEX"
fi

# --- GIT ---
if [ -d ".git" ]; then
    DIRTY=$(git status --porcelain 2>/dev/null | grep -v -E '\.beads/|settings\.local\.json|\.update-news|\.session-context' || true)
    DIRTY_COUNT=$(echo "$DIRTY" | grep -c . 2>/dev/null) || DIRTY_COUNT=0
    UNPUSHED=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")

    if [ "$DIRTY_COUNT" -gt 0 ] || [ "$UNPUSHED" -gt 0 ]; then
        MSG="⚠️  Git:"
        [ "$DIRTY_COUNT" -gt 0 ] && MSG="$MSG $DIRTY_COUNT uncommitted"
        [ "$UNPUSHED" -gt 0 ] && MSG="$MSG, $UNPUSHED unpushed"
        echo "$MSG"
    fi
fi

# --- ARC (default tracker) ---
ARC_FILE="$CONTEXT_DIR/arc.txt"
if [ -d ".arc" ]; then
    # Find arc CLI - check PATH first, then known location
    ARC_CMD=$(command -v arc 2>/dev/null || echo "$HOME/Repos/arc/.venv/bin/arc")

    if [ -x "$ARC_CMD" ]; then
        # Get ready items
        READY_OUTPUT=$("$ARC_CMD" list --ready 2>/dev/null || true)
        READY_COUNT=$(echo "$READY_OUTPUT" | grep -c "^" 2>/dev/null) || READY_COUNT=0
        # Subtract header/empty lines if present
        [ "$READY_COUNT" -gt 0 ] && READY_COUNT=$((READY_COUNT - 1))
        [ "$READY_COUNT" -lt 0 ] && READY_COUNT=0

        # Write arc context to file
        {
            echo "# Arc Context (generated $(date '+%Y-%m-%d %H:%M'))"
            echo "# Generated for: $CWD"
            echo ""
            echo "## Ready Work"
            echo "$READY_OUTPUT"
            echo ""
            echo "## Full Hierarchy"
            "$ARC_CMD" list 2>/dev/null || true
        } > "$ARC_FILE"

        echo "🎯 Arc (default): $READY_COUNT ready"
        echo "   Context: $ARC_FILE"
    else
        echo "🎯 Arc: .arc/ exists but arc CLI not found"
        rm -f "$ARC_FILE"
    fi
else
    rm -f "$ARC_FILE"
fi

# --- BEADS (legacy tracker) ---
BEADS_FILE="$CONTEXT_DIR/beads.txt"
if [ -d ".beads" ]; then
    # Get ready output and extract count from "N issues with no blockers"
    READY_OUTPUT=$(bd ready --no-daemon 2>/dev/null || true)
    READY_COUNT=$(echo "$READY_OUTPUT" | grep -oE "[0-9]+ issues" | head -1 | grep -oE "[0-9]+" || echo 0)

    # Write beads context to file
    {
        echo "# Beads Context (generated $(date '+%Y-%m-%d %H:%M'))"
        echo "# Generated for: $CWD"
        echo ""
        echo "## Ready Work"
        echo "$READY_OUTPUT"
        echo ""

        # Recently closed
        RECENTLY_CLOSED=$(bd list --no-daemon --status closed 2>/dev/null | head -5)
        if [ -n "$RECENTLY_CLOSED" ]; then
            echo "## Recently Closed"
            echo "$RECENTLY_CLOSED"
            echo ""
        fi

        # Hierarchy
        EPICS=$(bd list --no-daemon --type epic --json 2>/dev/null | jq -r '.[].id' 2>/dev/null || true)
        if [ -n "$EPICS" ]; then
            echo "## Hierarchy"

            # Collect all children to detect nested epics
            ALL_CHILDREN=""
            for epic_id in $EPICS; do
                children=$(bd list --no-daemon --parent "$epic_id" --json 2>/dev/null | jq -r '.[].id' 2>/dev/null || true)
                ALL_CHILDREN="$ALL_CHILDREN $children"
            done

            # Show top-level epics only
            for epic_id in $EPICS; do
                if echo "$ALL_CHILDREN" | grep -q "$epic_id"; then
                    continue
                fi
                epic_title=$(bd show --no-daemon "$epic_id" --json 2>/dev/null | jq -r '.[0].title' 2>/dev/null || echo "untitled")
                echo "📦 $epic_id: $epic_title"
                bd list --no-daemon --parent "$epic_id" --json 2>/dev/null | jq -r '.[] | if .issue_type == "epic" then "   ├── ⚠️ \(.id): \(.title) [NESTED]" else "   ├── \(.id): \(.title)" end' 2>/dev/null || true
            done

            # Standalone tasks
            ORPHANS=$(bd list --no-daemon --json 2>/dev/null | jq -r '.[] | select(.issue_type != "epic") | select(.dependency_count == 0) | "\(.id): \(.title)"' 2>/dev/null || true)
            if [ -n "$ORPHANS" ]; then
                echo ""
                echo "Standalone (no epic):"
                echo "$ORPHANS" | sed 's/^/• /'
            fi
        fi
    } > "$BEADS_FILE"

    echo "📦 Beads (legacy): $READY_COUNT ready"
    echo "   Context: $BEADS_FILE"
else
    # Don't advertise beads when not present — arc is the default now
    rm -f "$BEADS_FILE"
fi

# --- NEWS ---
NEWS_FILE="$HOME/.claude/.update-news"
if [ -f "$NEWS_FILE" ]; then
    echo "📰 News: available"
    echo "   File: $NEWS_FILE"
fi

# --- TODOIST ---
echo "📝 Todoist: load todoist-gtd skill to check @Claude inbox"

echo ""
echo "Run /open to read context, or read files directly."
