#!/bin/bash
# Health check for Claude Code script symlinks
# Run from update-all.sh or manually to detect broken symlinks

SCRIPTS_DIR="$HOME/.claude/scripts"
HOOKS_DIR="$HOME/.claude/hooks"

CRITICAL_SCRIPTS=(
    "open-context.sh"
    "close-context.sh"
    "check-home.sh"
)

CRITICAL_HOOKS=(
    "session-start.sh"
)

BROKEN=0

echo "Checking critical script symlinks in $SCRIPTS_DIR..."
for script in "${CRITICAL_SCRIPTS[@]}"; do
    LINK="$SCRIPTS_DIR/$script"
    if [ -L "$LINK" ]; then
        TARGET=$(readlink "$LINK")
        if [ ! -e "$TARGET" ]; then
            echo "❌ BROKEN: $script -> $TARGET (target does not exist)"
            BROKEN=$((BROKEN + 1))
        else
            echo "✓ OK: $script -> $TARGET"
        fi
    elif [ -f "$LINK" ]; then
        echo "✓ OK: $script (regular file)"
    else
        echo "⚠ MISSING: $script not found"
        BROKEN=$((BROKEN + 1))
    fi
done

echo ""
echo "Checking critical hook symlinks in $HOOKS_DIR..."
for hook in "${CRITICAL_HOOKS[@]}"; do
    LINK="$HOOKS_DIR/$hook"
    if [ -L "$LINK" ]; then
        TARGET=$(readlink "$LINK")
        if [ ! -e "$TARGET" ]; then
            echo "❌ BROKEN: $hook -> $TARGET (target does not exist)"
            BROKEN=$((BROKEN + 1))
        else
            echo "✓ OK: $hook -> $TARGET"
        fi
    elif [ -f "$LINK" ]; then
        echo "✓ OK: $hook (regular file)"
    else
        echo "⚠ MISSING: $hook not found"
        BROKEN=$((BROKEN + 1))
    fi
done

if [ $BROKEN -gt 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "⚠️  $BROKEN BROKEN SYMLINKS DETECTED"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "This will cause /open and /close to fail silently!"
    echo ""
    echo "Fix: Update symlinks to point to existing script locations."
    echo "Expected location: ~/Repos/trousse/scripts/"
    echo ""
    exit 1
fi

echo ""
echo "All script symlinks healthy."
