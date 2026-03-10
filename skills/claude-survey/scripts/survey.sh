#!/usr/bin/env bash
# survey.sh — Run a structured Claude instinct survey
# Usage: survey.sh <scenarios_file> [runs_per_scenario]
#
# Scenarios file must define:
#   declare -A SCENARIOS  (associative array of name→prompt)
#   JSON_FIELDS           (JSON schema string for structured responses)
#
# Example scenarios file:
#   declare -A SCENARIOS
#   SCENARIOS[simple]='You have a CLI called "xt"... Write the command to...'
#   JSON_FIELDS='{
#     "invocation": "the full command",
#     "main_verb": "the primary verb used"
#   }'

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: survey.sh <scenarios_file> [runs_per_scenario]"
  echo ""
  echo "Scenarios file must define:"
  echo "  declare -A SCENARIOS  — associative array of name→prompt"
  echo "  JSON_FIELDS           — JSON schema for structured responses"
  exit 1
fi

SCENARIOS_FILE="$1"
RUNS=${2:-10}

# Source the scenarios
source "$SCENARIOS_FILE"

if [ ${#SCENARIOS[@]} -eq 0 ]; then
  echo "Error: No SCENARIOS defined in $SCENARIOS_FILE"
  exit 1
fi

if [ -z "${JSON_FIELDS:-}" ]; then
  echo "Error: No JSON_FIELDS defined in $SCENARIOS_FILE"
  exit 1
fi

OUTDIR="/tmp/claude-survey-$(date +%Y%m%dT%H%M%S)"
mkdir -p "$OUTDIR"

# Copy scenarios file for reproducibility
cp "$SCENARIOS_FILE" "$OUTDIR/scenarios.sh"

GLOBAL_MD="$HOME/.claude/CLAUDE.md"
GLOBAL_MD_BAK="$HOME/.claude/CLAUDE.md.survey-bak"

restore() {
  if [ -f "$GLOBAL_MD_BAK" ]; then
    mv "$GLOBAL_MD_BAK" "$GLOBAL_MD"
    echo "[survey] Restored ~/.claude/CLAUDE.md"
  fi
}
trap restore EXIT

if [ -f "$GLOBAL_MD" ]; then
  mv "$GLOBAL_MD" "$GLOBAL_MD_BAK"
  echo "[survey] Temporarily hidden ~/.claude/CLAUDE.md"
fi

SYSPROMPT="You are a helpful assistant. You have no tools available. Respond with text only."

JSON_INSTRUCTION="Respond with ONLY a JSON object, no markdown fencing, no explanation:
$JSON_FIELDS"

SCENARIO_NAMES=(${!SCENARIOS[@]})
TOTAL=$((RUNS * ${#SCENARIO_NAMES[@]}))
COUNT=0

echo "Survey output: $OUTDIR"
echo "Scenarios: ${SCENARIO_NAMES[*]}"
echo "Runs per scenario: $RUNS"
echo "Total invocations: $TOTAL"
echo ""

for scenario in "${SCENARIO_NAMES[@]}"; do
  echo "=== $scenario ==="
  for i in $(seq 1 "$RUNS"); do
    COUNT=$((COUNT + 1))
    outfile="$OUTDIR/${scenario}_$(printf '%02d' $i).json"
    echo -n "  [$COUNT/$TOTAL] Run $i... "

    PROMPT="${SCENARIOS[$scenario]}

${JSON_INSTRUCTION}"

    echo "$PROMPT" | claude -p \
      --max-turns 1 \
      --tools "" \
      --system-prompt "$SYSPROMPT" \
      --output-format text \
      2>/dev/null \
      > "$outfile" || true

    if python3 -c "import json; json.load(open('$outfile'))" 2>/dev/null; then
      echo "OK (valid JSON)"
    else
      echo "WARN (not valid JSON — will need manual review)"
    fi
  done
  echo ""
done

echo "=== ANALYSIS ==="
echo ""

# Run analysis
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/analyze.py" "$OUTDIR"

echo ""
echo "Raw responses: $OUTDIR"
