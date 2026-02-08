#!/bin/bash
#
# arc-read.sh — fast jq-based reads from .arc/items.jsonl
# Replaces arc CLI for read-only operations in hooks and scripts.
# Arc CLI (~30ms Python startup) vs jq (~3ms).
#
# Usage:
#   arc-read.sh list          # Full hierarchy (outcomes + actions)
#   arc-read.sh ready         # Ready items only (open, not waiting)
#   arc-read.sh current       # Active tactical steps
#
# Reads from .arc/items.jsonl in current directory.
# Exits silently (exit 0) if no .arc/ directory — graceful no-op.

set -euo pipefail

ITEMS=".arc/items.jsonl"

# Graceful exit if no arc project
[ -f "$ITEMS" ] || exit 0

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
        echo "Usage: arc-read.sh {list|ready|current}" >&2
        exit 1
        ;;
esac
