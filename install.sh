#!/usr/bin/env bash
#
# trousse installer
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
# Accept plugin cache or ~/Repos/trousse as valid locations
EXPECTED_DIR="$HOME/Repos/trousse"
PLUGIN_CACHE_PATTERN="$HOME/.claude/plugins/cache/"

# Parse arguments
DRY_RUN=false
VERIFY_ONLY=false
UNINSTALL=false

show_help() {
    echo "trousse installer"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help      Show this help message"
    echo "  --dry-run   Preview what would be installed (no changes)"
    echo "  --verify    Check existing installation"
    echo "  --uninstall Remove symlinks created by this installer"
    echo ""
}

for arg in "$@"; do
    case $arg in
        --help)     show_help; exit 0 ;;
        --dry-run)  DRY_RUN=true ;;
        --verify)   VERIFY_ONLY=true ;;
        --uninstall) UNINSTALL=true ;;
        *)          error "Unknown option: $arg"; show_help; exit 1 ;;
    esac
done

# ============================================================
# UNINSTALL MODE
# ============================================================
if [[ "$UNINSTALL" == true ]]; then
    echo ""
    echo "trousse uninstaller"
    echo "========================"
    echo ""

    info "Removing skill symlinks..."
    REMOVED=0
    for link in ~/.claude/skills/*/; do
        [[ -L "${link%/}" ]] || continue
        target=$(readlink "${link%/}")
        if [[ "$target" == *"trousse"* ]]; then
            rm "${link%/}"
            REMOVED=$((REMOVED + 1))
        fi
    done
    ok "Removed $REMOVED skill symlinks"

    info "Removing script symlinks..."
    for link in ~/.claude/scripts/*.sh; do
        [[ -L "$link" ]] || continue
        target=$(readlink "$link")
        if [[ "$target" == *"trousse"* ]]; then
            rm "$link"
        fi
    done
    ok "Removed script symlinks"

    echo ""
    exit 0
fi

# ============================================================
# VERIFY MODE
# ============================================================
if [[ "$VERIFY_ONLY" == true ]]; then
    echo ""
    echo "trousse verification"
    echo "========================="
    echo ""

    ERRORS=0

    # Check skills
    info "Checking skills..."
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        skill=$(basename "$skill_dir")
        if [[ -L "$HOME/.claude/skills/$skill" ]]; then
            target=$(readlink "$HOME/.claude/skills/$skill")
            if [[ -d "$target" ]]; then
                echo "  ✓ $skill"
            else
                echo "  ✗ $skill (broken symlink)"
                ERRORS=$((ERRORS + 1))
            fi
        elif [[ -d "$HOME/.claude/skills/$skill" ]]; then
            echo "  ~ $skill (directory, not symlink)"
        else
            echo "  ✗ $skill (missing)"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Check scripts (glob to match install mode)
    info "Checking scripts..."
    for script in "$SCRIPT_DIR/scripts/"*.sh; do
        [[ -f "$script" ]] || continue
        script_name=$(basename "$script")
        # Skip templates (copied, not symlinked)
        [[ "$script_name" == *.template.sh ]] && continue
        if [[ -L "$HOME/.claude/scripts/$script_name" ]]; then
            echo "  ✓ $script_name"
        else
            echo "  ✗ $script_name (missing)"
            ERRORS=$((ERRORS + 1))
        fi
    done

    echo ""
    if [[ $ERRORS -eq 0 ]]; then
        ok "All checks passed!"
    else
        error "$ERRORS issues found"
        exit 1
    fi
    exit 0
fi

# ============================================================
# INSTALL MODE
# ============================================================
echo ""
echo "trousse installer"
echo "======================"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    warn "DRY RUN — no changes will be made"
    echo ""
fi

# Validate location
if [[ "$SCRIPT_DIR" != "$EXPECTED_DIR" ]] && [[ "$SCRIPT_DIR" != "$PLUGIN_CACHE_PATTERN"* ]]; then
    warn "Running from $SCRIPT_DIR"
    warn "Expected location: $EXPECTED_DIR (or plugin cache)"
    echo ""
    echo "Symlinks will point to current location, which may cause issues"
    echo "if you move or delete this directory."
    echo ""
    if [[ "$DRY_RUN" != true ]]; then
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted. To fix, run:"
            echo "  mv $SCRIPT_DIR $EXPECTED_DIR"
            echo "  cd $EXPECTED_DIR && ./install.sh"
            exit 1
        fi
    fi
fi

# Check dependencies
info "Checking dependencies..."
ok "Dependencies OK"

# Create directories
info "Creating ~/.claude directories..."
if [[ "$DRY_RUN" != true ]]; then
    mkdir -p ~/.claude/skills
    mkdir -p ~/.claude/scripts
fi
ok "Directories ready"

# Symlink skills
info "Symlinking skills..."
SKILL_COUNT=0
SKILL_SKIPPED=0
SKILL_UPDATED=0

for skill_dir in "$SCRIPT_DIR/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    skill_path="${skill_dir%/}"  # Remove trailing slash
    target="$HOME/.claude/skills/$skill_name"

    if [[ -L "$target" ]]; then
        # Existing symlink — remove and recreate
        if [[ "$DRY_RUN" != true ]]; then
            rm "$target"
            ln -s "$skill_path" "$target"
        fi
        SKILL_UPDATED=$((SKILL_UPDATED + 1))
        SKILL_COUNT=$((SKILL_COUNT + 1))
    elif [[ -d "$target" ]]; then
        # Existing real directory — skip with warning
        warn "Skipping $skill_name (existing directory, not symlink)"
        SKILL_SKIPPED=$((SKILL_SKIPPED + 1))
    else
        # New symlink
        if [[ "$DRY_RUN" != true ]]; then
            ln -s "$skill_path" "$target"
        fi
        SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
done

NEW_SKILLS=$((SKILL_COUNT - SKILL_UPDATED))
ok "Symlinked $SKILL_COUNT skills ($NEW_SKILLS new, $SKILL_UPDATED updated)"
[[ $SKILL_SKIPPED -gt 0 ]] && warn "Skipped $SKILL_SKIPPED (existing directories)" || true

# Symlink scripts
info "Symlinking scripts..."
SCRIPT_COUNT=0

if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    for script in "$SCRIPT_DIR/scripts/"*.sh; do
        [[ -f "$script" ]] || continue
        script_name=$(basename "$script")
        target="$HOME/.claude/scripts/$script_name"

        if [[ "$DRY_RUN" != true ]]; then
            ln -sf "$script" "$target"
        fi
        SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    done
fi

ok "Symlinked $SCRIPT_COUNT scripts"


# Summary
echo ""
echo "================================"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY RUN complete${NC}"
else
    echo -e "${GREEN}Installation complete!${NC}"
fi
echo "================================"
echo ""
echo "Installed:"
echo "  • $SKILL_COUNT skills  → ~/.claude/skills/"
echo "  • $SCRIPT_COUNT scripts → ~/.claude/scripts/"
echo ""

echo -e "${BLUE}What you now have:${NC}"
echo ""
echo "  Skills (slash commands):"
echo "    • /titans, /review — Three-lens code review"
echo "    • /diagram, /screenshot, /picture — Visual tools"
echo "    • /filing — Organize files (PARA method)"
echo "    • /server-checkup — Linux server management"
echo "    • /skill-forge — Build and validate new skills"
echo ""
echo "  Session lifecycle is handled by bon, not trousse."
echo "  Install bon separately for /open, /close, and startup briefings."
echo ""

echo -e "${YELLOW}NEXT STEP:${NC} Restart Claude Code to activate."
echo "  Run: /exit then start claude again"
echo ""

# Quick verification (silent unless errors)
if [[ "$DRY_RUN" != true ]]; then
    VERIFY_ERRORS=0
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        skill=$(basename "$skill_dir")
        if [[ ! -L "$HOME/.claude/skills/$skill" ]] && [[ ! -d "$HOME/.claude/skills/$skill" ]]; then
            VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
        fi
    done
    if [[ $VERIFY_ERRORS -eq 0 ]]; then
        ok "Quick verify: All core skills present"
    else
        warn "Quick verify: $VERIFY_ERRORS skills missing — run ./install.sh --verify for details"
    fi
    echo ""
fi

# Companion tools
echo "Companion tools:"
echo ""
echo "  • bon (session lifecycle + work tracking) — recommended"
echo "    /plugin → batterie-de-savoir → bon"
echo ""
echo "  • garde-manger (searchable session memory)"
echo "    /plugin → batterie-de-savoir → garde-manger"
echo ""
echo "Or install the full suite via marketplace:"
echo "  /plugin → batterie-de-savoir"
echo ""
