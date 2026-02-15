#!/bin/bash
# Claude Code infrastructure health check
# Like `bd doctor` but for the whole Claude setup
#
# Run: ~/.claude/scripts/claude-doctor.sh
# Or:  claude-doctor (if scripts dir is in PATH)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

section() {
    echo ""
    echo "━━━ $1 ━━━"
}

# ═══════════════════════════════════════════════════════════════
section "Manifest"
# ═══════════════════════════════════════════════════════════════

MANIFEST="$HOME/.claude/manifest.json"
SCRIPTS_DIR="$HOME/.claude/scripts"

if [ -f "$MANIFEST" ]; then
    pass "manifest.json found"
else
    fail "manifest.json not found — run setup-from-manifest.sh"
fi

# ═══════════════════════════════════════════════════════════════
section "Repos"
# ═══════════════════════════════════════════════════════════════

if [ -f "$MANIFEST" ]; then
    for repo in $(jq -r '.repos | keys[]' "$MANIFEST"); do
        required=$(jq -r ".repos[\"$repo\"].required" "$MANIFEST")
        if [ -d "$HOME/Repos/$repo" ]; then
            pass "$repo"
        elif [ "$required" = "true" ]; then
            fail "$repo (required, missing)"
        else
            warn "$repo (optional, missing)"
        fi
    done
fi

# ═══════════════════════════════════════════════════════════════
section "Script Symlinks"
# ═══════════════════════════════════════════════════════════════

if [ -f "$MANIFEST" ]; then
    for script in $(jq -r '.scripts | keys[]' "$MANIFEST"); do
        LINK="$SCRIPTS_DIR/$script"
        if [ -L "$LINK" ]; then
            TARGET=$(readlink "$LINK")
            if [ ! -e "$TARGET" ]; then
                fail "$script → $TARGET (BROKEN)"
            else
                pass "$script"
            fi
        elif [ -f "$LINK" ]; then
            pass "$script (regular file)"
        else
            fail "$script not found"
        fi
    done
else
    # Fallback to hardcoded list if no manifest
    for script in open-context.sh close-context.sh check-home.sh; do
        LINK="$SCRIPTS_DIR/$script"
        if [ -L "$LINK" ] && [ -e "$(readlink "$LINK")" ]; then
            pass "$script"
        else
            fail "$script not found or broken"
        fi
    done
fi

# ═══════════════════════════════════════════════════════════════
section "Required Tools"
# ═══════════════════════════════════════════════════════════════

check_tool() {
    local tool=$1
    local install_hint=$2
    if command -v "$tool" &>/dev/null; then
        local version=$($tool --version 2>/dev/null | head -1 || echo "installed")
        pass "$tool ($version)"
    else
        fail "$tool not found - install with: $install_hint"
    fi
}

check_tool "jq" "brew install jq"
check_tool "uv" "curl -LsSf https://astral.sh/uv/install.sh | sh"
check_tool "gh" "brew install gh"

# bd is optional but important
if command -v bd &>/dev/null; then
    BD_VERSION=$(bd --version 2>/dev/null | head -1 || echo "installed")
    pass "bd ($BD_VERSION)"
else
    info "bd not found (beads deprecated — use bon instead)"
fi

# ═══════════════════════════════════════════════════════════════
section "Claude CLI"
# ═══════════════════════════════════════════════════════════════

if command -v claude &>/dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "installed")
    pass "claude CLI ($CLAUDE_VERSION)"
else
    fail "claude CLI not found"
fi

# ═══════════════════════════════════════════════════════════════
section "Configuration Files"
# ═══════════════════════════════════════════════════════════════

check_file() {
    local file=$1
    local description=$2
    if [ -f "$file" ]; then
        pass "$description ($file)"
    elif [ -d "$file" ]; then
        pass "$description ($file/)"
    else
        fail "$description not found at $file"
    fi
}

check_file "$HOME/.claude/CLAUDE.md" "Global CLAUDE.md"
check_file "$HOME/.claude/settings.json" "Settings"
check_file "$HOME/.claude.json" "MCP config"
check_file "$HOME/.claude/skills" "Skills directory"
check_file "$HOME/.claude/handoffs" "Handoffs directory"

# ═══════════════════════════════════════════════════════════════
section "Skills"
# ═══════════════════════════════════════════════════════════════

SKILLS_DIR="$HOME/.claude/skills"

if [ -f "$MANIFEST" ]; then
    skill_ok=0
    skill_broken=0
    skill_missing=0

    for skill in $(jq -r '.skills | keys[]' "$MANIFEST"); do
        SKILL_PATH="$SKILLS_DIR/$skill"
        if [ -L "$SKILL_PATH" ]; then
            TARGET=$(readlink "$SKILL_PATH")
            # For relative symlinks, resolve from skills dir
            if [[ "$TARGET" != /* ]]; then
                RESOLVED="$SKILLS_DIR/$TARGET"
            else
                RESOLVED="$TARGET"
            fi
            if [ ! -e "$RESOLVED" ]; then
                fail "Skill $skill → $TARGET (BROKEN)"
                skill_broken=$((skill_broken + 1))
            else
                skill_ok=$((skill_ok + 1))
            fi
        elif [ -d "$SKILL_PATH" ]; then
            skill_ok=$((skill_ok + 1))
        else
            warn "Skill $skill not linked"
            skill_missing=$((skill_missing + 1))
        fi
    done

    # Inline skills
    for skill in $(jq -r '.inline_skills[]? // empty' "$MANIFEST"); do
        SKILL_PATH="$SKILLS_DIR/$skill"
        if [ -d "$SKILL_PATH" ] && [ -f "$SKILL_PATH/SKILL.md" ]; then
            skill_ok=$((skill_ok + 1))
        else
            warn "Inline skill $skill missing or no SKILL.md"
            skill_missing=$((skill_missing + 1))
        fi
    done

    total=$((skill_ok + skill_broken + skill_missing))
    if [ $skill_broken -eq 0 ] && [ $skill_missing -eq 0 ]; then
        pass "All $total skills linked"
    else
        echo "  $skill_ok ok, $skill_broken broken, $skill_missing missing (of $total)"
    fi

    # Check permissions match manifest
    if [ -f "$HOME/.claude/settings.json" ]; then
        missing_perms=()
        for skill in $(jq -r '.skills | keys[]' "$MANIFEST"); do
            if ! jq -e --arg s "Skill($skill)" '.permissions.allow[] | select(. == $s)' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
                missing_perms+=("$skill")
            fi
        done
        for skill in $(jq -r '.inline_skills[]? // empty' "$MANIFEST"); do
            if ! jq -e --arg s "Skill($skill)" '.permissions.allow[] | select(. == $s)' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
                missing_perms+=("$skill")
            fi
        done
        if [ ${#missing_perms[@]} -gt 0 ]; then
            warn "Missing Skill() permissions: ${missing_perms[*]}"
            echo "  Run setup-from-manifest.sh to fix"
        else
            pass "All skills have Skill() permissions"
        fi
    fi
else
    # No manifest — basic check
    for skill in open close bon; do
        SKILL_PATH="$SKILLS_DIR/$skill"
        if [ -L "$SKILL_PATH" ] && [ -e "$SKILL_PATH" ]; then
            pass "Skill $skill"
        else
            warn "Skill $skill not found"
        fi
    done
fi

# ═══════════════════════════════════════════════════════════════
section "Hooks"
# ═══════════════════════════════════════════════════════════════

HOOKS_DIR="$HOME/.claude/hooks"

if [ -f "$MANIFEST" ]; then
    for hook in $(jq -r '.hooks | keys[]' "$MANIFEST"); do
        LINK="$HOOKS_DIR/$hook"
        if [ -L "$LINK" ] && [ -e "$LINK" ]; then
            pass "$hook"
        elif [ -L "$LINK" ]; then
            fail "$hook (BROKEN symlink)"
        else
            warn "$hook not linked"
        fi
    done
else
    for hook in session-start.sh session-end.sh bon-tactical.sh; do
        if [ -L "$HOOKS_DIR/$hook" ] && [ -e "$HOOKS_DIR/$hook" ]; then
            pass "$hook"
        else
            warn "$hook not found"
        fi
    done
fi

# ═══════════════════════════════════════════════════════════════
section "Memory System"
# ═══════════════════════════════════════════════════════════════

if [ -d "$HOME/Repos/garde-manger" ]; then
    pass "garde-manger repo exists"

    if [ -f "$HOME/.claude/memory/memory.db" ]; then
        DB_SIZE=$(du -h "$HOME/.claude/memory/memory.db" 2>/dev/null | cut -f1)
        SOURCE_COUNT=$(sqlite3 "$HOME/.claude/memory/memory.db" "SELECT COUNT(*) FROM sources" 2>/dev/null || echo "?")
        pass "Memory database ($DB_SIZE, $SOURCE_COUNT sources)"
    else
        warn "Memory database not found at ~/.claude/memory/memory.db"
    fi
else
    warn "garde-manger repo not found - memory search unavailable"
fi

# ═══════════════════════════════════════════════════════════════
section "MCP Servers"
# ═══════════════════════════════════════════════════════════════

if [ -f "$HOME/.claude.json" ]; then
    MCP_COUNT=$(jq '.mcpServers | length' "$HOME/.claude.json" 2>/dev/null || echo "0")
    if [ "$MCP_COUNT" -gt 0 ]; then
        pass "$MCP_COUNT MCP server(s) configured globally"
        # List them
        jq -r '.mcpServers | keys[]' "$HOME/.claude.json" 2>/dev/null | while read -r server; do
            echo "    · $server"
        done
    else
        warn "No global MCP servers configured"
    fi
else
    warn "No ~/.claude.json found"
fi

# ═══════════════════════════════════════════════════════════════
section "Git Integration"
# ═══════════════════════════════════════════════════════════════

# Check if claude-config is a git repo and in sync
if [ -d "$HOME/.claude/.git" ] || [ -d "$HOME/Repos/claude-config/.git" ]; then
    pass "claude-config is git-tracked"

    cd "$HOME/.claude" 2>/dev/null || cd "$HOME/Repos/claude-config"

    DIRTY=$(git status --porcelain 2>/dev/null | head -5)
    if [ -n "$DIRTY" ]; then
        warn "claude-config has uncommitted changes"
    else
        pass "claude-config is clean"
    fi

    UNPUSHED=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    if [ "$UNPUSHED" -gt 0 ]; then
        warn "claude-config has $UNPUSHED unpushed commit(s)"
    fi
else
    warn "claude-config not git-tracked"
fi

# ═══════════════════════════════════════════════════════════════
section "Summary"
# ═══════════════════════════════════════════════════════════════

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}$WARNINGS warning(s), no errors${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo ""
    echo "Fix errors before running /open or /close - they may fail silently."
    exit 1
fi
