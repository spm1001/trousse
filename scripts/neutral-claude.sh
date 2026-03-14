#!/usr/bin/env bash
# neutral-claude.sh — Run claude -p in full context isolation
#
# Creates a temporary HOME with only .credentials.json, scrubs env,
# runs from /tmp. The spawned Claude sees no CLAUDE.md, no skills,
# no hooks, no project context. Cross-platform (Linux + macOS).
#
# Usage:
#   neutral-claude.sh "prompt"
#   neutral-claude.sh --max-turns 5 -- "prompt"
#   neutral-claude.sh --max-turns 5 --dangerously-skip-permissions -- "prompt"
#   echo "prompt" | neutral-claude.sh --stdin
#   echo "prompt" | neutral-claude.sh --stdin --max-turns 3
#
# All flags before -- are passed through to claude -p.
# The argument after -- (or the last non-flag argument) is the prompt.

set -euo pipefail

# ── Parse args ────────────────────────────────────────────────────────

CLAUDE_ARGS=()
PROMPT=""
USE_STDIN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --)
            shift
            PROMPT="${1:-}"
            [[ -n "$PROMPT" ]] && shift
            break
            ;;
        --stdin)
            USE_STDIN=true
            shift
            ;;
        --max-turns|--output-format|--system-prompt|--tools|--model)
            if [[ $# -lt 2 ]]; then
                echo "Error: $1 requires a value" >&2
                exit 1
            fi
            CLAUDE_ARGS+=("$1" "$2")
            shift 2
            ;;
        --dangerously-skip-permissions)
            CLAUDE_ARGS+=("$1")
            shift
            ;;
        -*)
            CLAUDE_ARGS+=("$1")
            shift
            ;;
        *)
            PROMPT="$1"
            shift
            ;;
    esac
done

if [[ "$USE_STDIN" == false && -z "$PROMPT" ]]; then
    echo "Usage: neutral-claude.sh [claude-p-flags] [--] \"prompt\"" >&2
    echo "       echo \"prompt\" | neutral-claude.sh --stdin [claude-p-flags]" >&2
    exit 1
fi

# ── Find claude binary ───────────────────────────────────────────────

CLAUDE_BIN=$(command -v claude 2>/dev/null) || {
    echo "Error: claude not found in PATH" >&2
    exit 1
}

# ── Find credentials ─────────────────────────────────────────────────

CREDS="$HOME/.claude/.credentials.json"
if [[ ! -f "$CREDS" ]]; then
    echo "Error: No credentials at $CREDS" >&2
    echo "Run: claude login" >&2
    exit 1
fi

# ── Build isolated HOME ──────────────────────────────────────────────

SANDBOX_HOME=$(mktemp -d)
cleanup() { rm -rf "$SANDBOX_HOME"; }
trap cleanup EXIT

mkdir -p "$SANDBOX_HOME/.claude"
cp "$CREDS" "$SANDBOX_HOME/.claude/.credentials.json"

# ── Construct minimal PATH ───────────────────────────────────────────
# Include the directory containing claude, plus standard system paths.

CLAUDE_DIR=$(dirname "$CLAUDE_BIN")
CLEAN_PATH="${CLAUDE_DIR}:/usr/local/bin:/usr/bin:/bin"

# ── Run ───────────────────────────────────────────────────────────────
# Build the command as an array to avoid shell-in-shell escaping issues.
# We use bash -c with "$@" passthrough for clean argument handling.

CMD_PARTS=(claude -p)
if [[ ${#CLAUDE_ARGS[@]} -gt 0 ]]; then
    CMD_PARTS+=("${CLAUDE_ARGS[@]}")
fi

if [[ "$USE_STDIN" == true ]]; then
    env -i \
        HOME="$SANDBOX_HOME" \
        PATH="$CLEAN_PATH" \
        TERM="${TERM:-dumb}" \
        bash -c 'cd /tmp && exec "$@"' _ "${CMD_PARTS[@]}"
else
    env -i \
        HOME="$SANDBOX_HOME" \
        PATH="$CLEAN_PATH" \
        TERM="${TERM:-dumb}" \
        bash -c 'cd /tmp && exec "$@"' _ "${CMD_PARTS[@]}" "$PROMPT"
fi
