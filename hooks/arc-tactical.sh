#!/bin/bash
# Arc tactical step reminder — UserPromptSubmit hook
# Injects current tactical step into every prompt so Claude stays on track.
# Uses jq on items.jsonl directly (~3ms) instead of arc CLI (~30ms).
# Silent when: no .arc/, no active tactical, jq not available.

command -v jq &>/dev/null || exit 0

# Read hook stdin once (consumed on first read) and cd to session CWD
HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null

[ -f .arc/items.jsonl ] || exit 0

tactical=$(jq -r '
    select(.tactical and .status == "open") |
    . as $item |
    "Working: \(.title) (\(.id))",
    (.tactical.steps | to_entries[] |
        (if .key < $item.tactical.current then "\u2713"
         elif .key == $item.tactical.current then "\u2192"
         else " " end) +
        " " + (.key + 1 | tostring) + ". " + .value +
        (if .key == $item.tactical.current then " [current]" else "" end))
' .arc/items.jsonl 2>/dev/null)

[ -z "$tactical" ] && exit 0

escaped=$(echo "$tactical" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "🎯 Active arc tactical:\n${escaped}\n\nWork on the CURRENT step. Run 'arc step' when it's complete before moving on."}}
EOF
