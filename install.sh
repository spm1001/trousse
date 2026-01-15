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

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}
PLATFORM=$(detect_platform)

# Parse arguments
DRY_RUN=false
VERIFY_ONLY=false
UNINSTALL=false

show_help() {
    echo "claude-suite installer"
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
    echo "claude-suite uninstaller"
    echo "========================"
    echo ""

    info "Removing skill symlinks..."
    REMOVED=0
    for link in ~/.claude/skills/*/; do
        [[ -L "${link%/}" ]] || continue
        target=$(readlink "${link%/}")
        if [[ "$target" == *"claude-suite"* ]]; then
            rm "${link%/}"
            REMOVED=$((REMOVED + 1))
        fi
    done
    ok "Removed $REMOVED skill symlinks"

    info "Removing script symlinks..."
    for link in ~/.claude/scripts/*.sh; do
        [[ -L "$link" ]] || continue
        target=$(readlink "$link")
        if [[ "$target" == *"claude-suite"* ]]; then
            rm "$link"
        fi
    done
    ok "Removed script symlinks"

    info "Removing hook symlinks..."
    for link in ~/.claude/hooks/*.sh; do
        [[ -L "$link" ]] || continue
        target=$(readlink "$link")
        if [[ "$target" == *"claude-suite"* ]]; then
            rm "$link"
        fi
    done
    ok "Removed hook symlinks"

    echo ""
    warn "Note: settings.json hook configuration not removed (manual cleanup if needed)"
    echo ""
    exit 0
fi

# ============================================================
# VERIFY MODE
# ============================================================
if [[ "$VERIFY_ONLY" == true ]]; then
    echo ""
    echo "claude-suite verification"
    echo "========================="
    echo ""

    ERRORS=0

    # Check skills
    info "Checking skills..."
    for skill in beads close diagram filing github-cleanup ground open picture screenshot server-checkup session-closing session-grounding session-opening setup skill-check; do
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

    # Check scripts
    info "Checking scripts..."
    for script in open-context.sh close-context.sh claude-doctor.sh check-symlinks.sh; do
        if [[ -L "$HOME/.claude/scripts/$script" ]]; then
            echo "  ✓ $script"
        else
            echo "  ✗ $script (missing)"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Check hooks
    info "Checking hooks..."
    if [[ -L "$HOME/.claude/hooks/session-start.sh" ]]; then
        echo "  ✓ session-start.sh"
    else
        echo "  ✗ session-start.sh (missing)"
        ERRORS=$((ERRORS + 1))
    fi

    # Check dependencies
    info "Checking dependencies..."
    if command -v jq &>/dev/null; then
        echo "  ✓ jq"
    else
        echo "  ✗ jq (required for open-context.sh)"
        ERRORS=$((ERRORS + 1))
    fi

    # Check settings.json hooks
    info "Checking hook registration..."
    if [[ -f "$HOME/.claude/settings.json" ]]; then
        if grep -q "hooks" "$HOME/.claude/settings.json" 2>/dev/null; then
            echo "  ✓ hooks configured in settings.json"
        else
            echo "  ~ hooks not configured in settings.json"
            warn "Hooks may not fire without registration"
        fi
    else
        echo "  ~ settings.json not found"
    fi

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
echo "claude-suite installer"
echo "======================"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    warn "DRY RUN — no changes will be made"
    echo ""
fi

# Validate location
if [[ "$SCRIPT_DIR" != "$EXPECTED_DIR" ]]; then
    warn "Running from $SCRIPT_DIR"
    warn "Expected location: $EXPECTED_DIR"
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
DEPS_MISSING=false

if ! command -v jq &>/dev/null; then
    warn "jq not found (required for session scripts)"
    DEPS_MISSING=true
    if [[ "$PLATFORM" == "macos" ]]; then
        echo "  Install with: brew install jq"
    elif [[ "$PLATFORM" == "linux" ]]; then
        echo "  Install with: sudo apt-get install jq"
    fi
fi

if [[ "$DEPS_MISSING" == true ]] && [[ "$DRY_RUN" != true ]]; then
    read -p "Continue without dependencies? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Install dependencies and retry."
        exit 1
    fi
else
    ok "Dependencies OK"
fi

# Create directories
info "Creating ~/.claude directories..."
if [[ "$DRY_RUN" != true ]]; then
    mkdir -p ~/.claude/skills
    mkdir -p ~/.claude/scripts
    mkdir -p ~/.claude/hooks
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

# Symlink hooks
info "Symlinking hooks..."
HOOK_COUNT=0

if [[ -d "$SCRIPT_DIR/hooks" ]]; then
    for hook in "$SCRIPT_DIR/hooks/"*.sh; do
        [[ -f "$hook" ]] || continue
        hook_name=$(basename "$hook")
        target="$HOME/.claude/hooks/$hook_name"

        if [[ "$DRY_RUN" != true ]]; then
            ln -sf "$hook" "$target"
        fi
        HOOK_COUNT=$((HOOK_COUNT + 1))
    done
fi

ok "Symlinked $HOOK_COUNT hooks"

# Register hooks in settings.json
info "Configuring hooks in settings.json..."
SETTINGS_FILE="$HOME/.claude/settings.json"

if [[ "$DRY_RUN" != true ]]; then
    # Create settings.json if it doesn't exist
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo '{}' > "$SETTINGS_FILE"
    fi

    if command -v jq &>/dev/null; then
        HOOK_PATH="$HOME/.claude/hooks/session-start.sh"

        # Check if our specific hook is already registered (not just any hooks)
        if jq -e ".hooks.SessionStart[]?.hooks[]? | select(.command == \"$HOOK_PATH\")" "$SETTINGS_FILE" >/dev/null 2>&1; then
            ok "Hooks already configured"
        else
            # Merge new hook into existing structure (preserve other hooks)
            jq --arg hook "$HOOK_PATH" '
                .hooks.SessionStart = ((.hooks.SessionStart // []) + [{
                    matcher: "",
                    hooks: [{type: "command", command: $hook}]
                }])
            ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            ok "Hooks registered in settings.json"
        fi
    else
        warn "jq not available — manual hook registration needed"
        echo "  Add to ~/.claude/settings.json:"
        echo '  "hooks": {"SessionStart": [{"matcher": "", "hooks": [{"type": "command", "command": "~/.claude/hooks/session-start.sh"}]}]}'
    fi
else
    echo "  Would register hooks in settings.json"
fi

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
echo "  • $HOOK_COUNT hooks    → ~/.claude/hooks/"
echo ""

# What you got - explain the value
echo -e "${BLUE}What you now have:${NC}"
echo ""
echo "  Session lifecycle (runs automatically):"
echo "    • On startup: time, handoffs, and ready work shown"
echo "    • /open  — Resume context from previous session"
echo "    • /close — Create handoff for next session"
echo "    • /ground — Mid-session checkpoint when things drift"
echo ""
echo "  Utilities:"
echo "    • /diagram, /screenshot, /picture — Visual tools"
echo "    • /filing — Organize files (PARA method)"
echo "    • /server-checkup — Linux server management"
echo ""

echo -e "${YELLOW}NEXT STEP:${NC} Restart Claude Code to activate."
echo "  Run: /exit then start claude again"
echo ""

# Quick verification (silent unless errors)
if [[ "$DRY_RUN" != true ]]; then
    VERIFY_ERRORS=0
    for skill in beads close diagram filing github-cleanup ground open picture screenshot server-checkup session-closing session-grounding session-opening setup skill-check; do
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

# Optional tools (platform-aware)
echo "Optional tools (not installed):"
echo ""
echo "  • bd CLI (for beads issue tracking)"
if [[ "$PLATFORM" == "macos" ]]; then
    echo "    brew install beads-dev/tap/bd"
elif [[ "$PLATFORM" == "linux" ]]; then
    echo "    # Download from https://github.com/beads-dev/bd/releases"
    echo "    # Or: cargo install bd-cli"
fi
echo ""
echo "  • todoist-gtd (GTD task management)"
echo "    git clone https://github.com/spm1001/todoist-gtd ~/Repos/todoist-gtd"
echo ""
echo "  • claude-mem (searchable session memory)"
echo "    git clone https://github.com/spm1001/claude-mem ~/Repos/claude-mem"
echo ""
