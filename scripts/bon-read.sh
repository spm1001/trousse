#!/bin/bash
#
# bon-read.sh — fast jq-based reads from .bon/items.jsonl
# Replaces bon CLI for read-only operations in hooks and scripts.
# Bon CLI (~30ms Python startup) vs jq (~3ms).
#
# Usage:
#   bon-read.sh list          # Full hierarchy (outcomes + actions)
#   bon-read.sh ready         # Ready items only (open, not waiting)
#   bon-read.sh current       # Active tactical steps
#
# Reads from .bon/items.jsonl in current directory.
# Exits silently (exit 0) if no .bon/ or .arc/ directory — graceful no-op.

set -euo pipefail

# Check .bon/ first, fall back to .arc/ (transition)
if [ -f ".bon/items.jsonl" ]; then
    ITEMS=".bon/items.jsonl"
elif [ -f ".arc/items.jsonl" ]; then
    ITEMS=".arc/items.jsonl"
else
    exit 0
fi

case "${1:-}" in
    list)
        # Full hierarchy: open outcomes with all their actions (including done)
        # Capture output — command substitution strips trailing newlines,
        # which removes the blank-line separator after the last group.
        output=$(jq -r -s '
            # Group actions by parent
            (map(select(.parent)) | group_by(.parent) | map({key: .[0].parent, value: (. | sort_by(.order))}) | from_entries) as $children |
            # Show open outcomes in order
            map(select(.type == "outcome" and .status == "open" and (.parent == null or .parent == ""))) | sort_by(.order)[] |
            . as $outcome |
            (if .status == "done" then "\u2713" else "\u25cb" end) + " " + .title + " (" + .id + ")",
            (($children[.id] // []) | to_entries[] |
                "  " + ((.value.order // (.key + 1)) | tostring) + ". " +
                (if .value.status == "done" then "\u2713" else "\u25cb" end) + " " +
                .value.title + " (" + .value.id + ")"),
            ""
        ' "$ITEMS" 2>/dev/null) || true
        if [ -n "$output" ]; then printf '%s\n' "$output"; fi
        ;;

    ready)
        # Ready items: open outcomes with only open+non-waiting actions
        output=$(jq -r -s '
            (map(select(.parent and .status == "open" and (.waiting_for == null or .waiting_for == ""))) | group_by(.parent) | map({key: .[0].parent, value: (. | sort_by(.order))}) | from_entries) as $ready_children |
            map(select(.type == "outcome" and .status == "open" and (.parent == null or .parent == ""))) | sort_by(.order)[] |
            . as $outcome |
            "\u25cb " + .title + " (" + .id + ")",
            (($ready_children[.id] // []) | to_entries[] |
                "  " + ((.key + 1) | tostring) + ". \u25cb " +
                .value.title + " (" + .value.id + ")"),
            ""
        ' "$ITEMS" 2>/dev/null) || true
        if [ -n "$output" ]; then printf '%s\n' "$output"; fi
        ;;

    current)
        # Active tactical: find item with .tactical field and status=open
        jq -r '
            select(.tactical and .status == "open") |
            . as $item |
            "Working: \(.title) (\(.id))",
            (.tactical.steps | to_entries[] |
                (if .key < $item.tactical.current then "\u2713"
                 elif .key == $item.tactical.current then "\u2192"
                 else " " end) +
                " " + (.key + 1 | tostring) + ". " + .value +
                (if .key == $item.tactical.current then " [current]" else "" end))
        ' "$ITEMS" 2>/dev/null || true
        ;;

    *)
        echo "Usage: bon-read.sh {list|ready|current}" >&2
        exit 1
        ;;
esac
