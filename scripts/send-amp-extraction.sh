#!/usr/bin/env bash
# send-amp-extraction.sh — send Amp session extraction JSON to garde-manger
#
# Usage:
#   send-amp-extraction.sh <THREAD_ID> < extraction.json
#   cat extraction.json | send-amp-extraction.sh <THREAD_ID>
#
# THREAD_ID: the full Amp thread ID (T-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
#
# Wraps the 3 garde steps: scan (index thread), store-extraction (persist JSON),
# cleanup. Amp has no session-end hook, so this runs inline during amp-close.
#
# Degrades gracefully: if garde-manger is not installed, warns and exits 0.

set -euo pipefail

THREAD_ID="${1:-}"
if [ -z "$THREAD_ID" ]; then
    echo "send-amp-extraction: THREAD_ID required as first argument" >&2
    echo "Usage: send-amp-extraction.sh T-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" >&2
    exit 1
fi

GARDE_PROJECT="$HOME/Repos/garde-manger"

if [ ! -d "$GARDE_PROJECT" ]; then
    echo "send-amp-extraction: garde-manger not found at $GARDE_PROJECT — skipping extraction" >&2
    # Drain stdin so caller doesn't get a broken pipe
    cat > /dev/null
    exit 0
fi

# Stage to temp file (garde store-extraction needs seekable input on some versions)
TMPFILE=$(mktemp /tmp/amp-extraction-XXXXXX.json)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE"

SOURCE_ID="amp:${THREAD_ID}"

# Step 1: ensure thread is indexed
cd "$GARDE_PROJECT" && uv run garde scan --source amp >&2

# Step 2: store extraction
cd "$GARDE_PROJECT" && uv run garde store-extraction "$SOURCE_ID" --model amp-context < "$TMPFILE" >&2

echo "Extraction stored → $SOURCE_ID" >&2
