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
EXPECTED_DIR="$HOME/Repos/trousse"

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

    info "Removing hook symlinks..."
    for link in ~/.claude/hooks/*.sh; do
        [[ -L "$link" ]] || continue
        target=$(readlink "$link")
        if [[ "$target" == *"trousse"* ]]; then
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

    # Check hooks (glob to match install mode)
    info "Checking hooks..."
    for hook in "$SCRIPT_DIR/hooks/"*.sh; do
        [[ -f "$hook" ]] || continue
        hook_name=$(basename "$hook")
        if [[ -L "$HOME/.claude/hooks/$hook_name" ]]; then
            echo "  ✓ $hook_name"
        else
            echo "  ✗ $hook_name (missing)"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Check update-all.sh
    info "Checking update-all.sh..."
    if [[ -f "$HOME/.claude/scripts/update-all.sh" ]]; then
        if [[ -x "$HOME/.claude/scripts/update-all.sh" ]]; then
            echo "  ✓ update-all.sh (present and executable)"
        else
            echo "  ~ update-all.sh (present but not executable)"
            warn "Run: chmod +x ~/.claude/scripts/update-all.sh"
        fi
    else
        echo "  ~ update-all.sh (missing — run install.sh to scaffold from template)"
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
echo "trousse installer"
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

# Scaffold update-all.sh (copy template if not present — it's theirs to customize)
UPDATE_TARGET="$HOME/.claude/scripts/update-all.sh"
UPDATE_TEMPLATE="$SCRIPT_DIR/scripts/update-all.template.sh"
if [[ ! -f "$UPDATE_TARGET" ]] && [[ -f "$UPDATE_TEMPLATE" ]]; then
    if [[ "$DRY_RUN" != true ]]; then
        cp "$UPDATE_TEMPLATE" "$UPDATE_TARGET"
        chmod +x "$UPDATE_TARGET"
    fi
    ok "Scaffolded update-all.sh (customize at ~/.claude/scripts/update-all.sh)"
elif [[ -f "$UPDATE_TARGET" ]]; then
    ok "update-all.sh already exists (not overwritten)"
fi

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
        # Register all hook events (idempotent — checks before adding)
        register_hook() {
            local event="$1" matcher="$2" hook_cmd="$3"
            if jq -e ".hooks.${event}[]?.hooks[]? | select(.command == \"$hook_cmd\")" "$SETTINGS_FILE" >/dev/null 2>&1; then
                echo "  ✓ $event ($hook_cmd) already registered"
            else
                trap 'rm -f "$SETTINGS_FILE.tmp"' ERR
                jq --arg event "$event" --arg matcher "$matcher" --arg cmd "$hook_cmd" '
                    .hooks[$event] = ((.hooks[$event] // []) + [{
                        matcher: $matcher,
                        hooks: [{type: "command", command: $cmd}]
                    }])
                ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
                mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
                trap - ERR
                echo "  + $event ($hook_cmd) registered"
            fi
        }

        register_hook "SessionStart" "" "$HOME/.claude/hooks/session-start.sh"
        register_hook "SessionEnd" "" "$HOME/.claude/hooks/session-end.sh"
        register_hook "UserPromptSubmit" "" "$HOME/.claude/hooks/bon-tactical.sh"

        # PostToolUse inline hooks (no script files)
        if ! jq -e '.hooks.PostToolUse[]? | select(.matcher == "WebFetch")' "$SETTINGS_FILE" >/dev/null 2>&1; then
            trap 'rm -f "$SETTINGS_FILE.tmp"' ERR
            jq '.hooks.PostToolUse = ((.hooks.PostToolUse // []) + [
                {matcher: "WebFetch", hooks: [{type: "command", command: "echo \u0027{\"hookSpecificOutput\": {\"hookEventName\": \"PostToolUse\", \"additionalContext\": \"STOP: WebFetch returns AI summaries, not raw content. For documentation you need to understand, you MUST use curl to fetch the actual page. Do not proceed with summarized documentation.\"}}\u0027"}]},
                {matcher: "Bash", hooks: [{type: "command", command: "if git rev-parse --is-inside-work-tree &>/dev/null && ! git symbolic-ref HEAD &>/dev/null 2>&1; then echo \u0027{\"hookSpecificOutput\": {\"hookEventName\": \"PostToolUse\", \"additionalContext\": \"⚠️ WARNING: HEAD is detached! Run git checkout main (or appropriate branch) immediately to avoid losing commits.\"}}\u0027; fi"}]}
            ])' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
            mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            trap - ERR
            echo "  + PostToolUse (WebFetch, Bash) registered"
        else
            echo "  ✓ PostToolUse already registered"
        fi

        ok "All hooks registered"
    else
        warn "jq not available — manual hook registration needed"
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

# Optional tools (platform-aware)
echo "Optional tools (not installed):"
echo ""
echo "  • bon (tactical outcome tracking)"
echo "    uv tool install ~/Repos/arc"
echo ""
echo "  • todoist-gtd (GTD task management)"
echo "    git clone https://github.com/spm1001/todoist-gtd ~/Repos/todoist-gtd"
echo ""
echo "  • garde-manger (searchable session memory)"
echo "    git clone https://github.com/spm1001/garde-manger ~/Repos/garde-manger"
echo ""
