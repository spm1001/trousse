#!/usr/bin/env bash
#
# claude-suite installer
# Run from the repo root: ./install.sh
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}==>${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# Where are we?
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_DIR="$HOME/Repos/claude-suite"

echo ""
echo "claude-suite installer"
echo "======================"
echo ""

# Validate location
if [[ "$SCRIPT_DIR" != "$EXPECTED_DIR" ]]; then
    warn "Running from $SCRIPT_DIR"
    warn "Expected location: $EXPECTED_DIR"
    echo ""
    echo "Symlinks will point to current location, which may cause issues"
    echo "if you move or delete this directory."
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. To fix, run:"
        echo "  mv $SCRIPT_DIR $EXPECTED_DIR"
        echo "  cd $EXPECTED_DIR && ./install.sh"
        exit 1
    fi
fi

# Create directories
info "Creating ~/.claude directories..."
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/scripts
mkdir -p ~/.claude/hooks
ok "Directories ready"

# Symlink skills
info "Symlinking skills..."
SKILL_COUNT=0
SKILL_SKIPPED=0

for skill_dir in "$SCRIPT_DIR/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    target="$HOME/.claude/skills/$skill_name"

    if [[ -L "$target" ]]; then
        # Existing symlink — remove and recreate
        rm "$target"
        ln -s "$skill_dir" "$target"
        SKILL_COUNT=$((SKILL_COUNT + 1))
    elif [[ -d "$target" ]]; then
        # Existing real directory — skip with warning
        warn "Skipping $skill_name (existing directory, not symlink)"
        SKILL_SKIPPED=$((SKILL_SKIPPED + 1))
    else
        # New symlink
        ln -s "$skill_dir" "$target"
        SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
done

ok "Symlinked $SKILL_COUNT skills"
[[ $SKILL_SKIPPED -gt 0 ]] && warn "Skipped $SKILL_SKIPPED (existing directories)" || true

# Symlink scripts
info "Symlinking scripts..."
SCRIPT_COUNT=0

if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    for script in "$SCRIPT_DIR/scripts/"*.sh; do
        [[ -f "$script" ]] || continue
        script_name=$(basename "$script")
        target="$HOME/.claude/scripts/$script_name"

        # Always overwrite symlinks for scripts
        ln -sf "$script" "$target"
        SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    done
fi

ok "Symlinked $SCRIPT_COUNT scripts"

# Symlink hooks
info "Symlinking hooks..."
HOOK_COUNT=0

if [[ -d "$SCRIPT_DIR/hooks" ]]; then
    for hook in "$SCRIPT_DIR/hooks/"*.sh; do
        [[ -f "$hook" ]] || continue
        hook_name=$(basename "$hook")
        target="$HOME/.claude/hooks/$hook_name"

        # Always overwrite symlinks for hooks
        ln -sf "$hook" "$target"
        HOOK_COUNT=$((HOOK_COUNT + 1))
    done
fi

ok "Symlinked $HOOK_COUNT hooks"

# Summary
echo ""
echo "================================"
echo -e "${GREEN}Installation complete!${NC}"
echo "================================"
echo ""
echo "Installed:"
echo "  • $SKILL_COUNT skills  → ~/.claude/skills/"
echo "  • $SCRIPT_COUNT scripts → ~/.claude/scripts/"
echo "  • $HOOK_COUNT hooks    → ~/.claude/hooks/"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC} Restart Claude Code for skills to load."
echo "  Run: /exit then start claude again"
echo ""

# Optional tools
echo "Optional tools (not installed):"
echo "  • bd CLI (for beads issue tracking)"
echo "    brew install beads-dev/tap/bd"
echo ""
echo "  • todoist-gtd (GTD task management)"
echo "    git clone https://github.com/spm1001/todoist-gtd ~/Repos/todoist-gtd"
echo ""
echo "  • claude-mem (searchable session memory)"
echo "    git clone https://github.com/spm1001/claude-mem ~/Repos/claude-mem"
echo ""
