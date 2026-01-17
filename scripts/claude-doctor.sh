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
section "Critical Symlinks"
# ═══════════════════════════════════════════════════════════════

SCRIPTS_DIR="$HOME/.claude/scripts"
CRITICAL_SCRIPTS=(
    "open-context.sh"
    "close-context.sh"
    "check-home.sh"
)

for script in "${CRITICAL_SCRIPTS[@]}"; do
    LINK="$SCRIPTS_DIR/$script"
    if [ -L "$LINK" ]; then
        TARGET=$(readlink "$LINK")
        if [ ! -e "$TARGET" ]; then
            fail "$script → $TARGET (BROKEN - target missing)"
        else
            pass "$script → $TARGET"
        fi
    elif [ -f "$LINK" ]; then
        pass "$script (regular file)"
    else
        fail "$script not found"
    fi
done

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
    warn "bd not found - beads tracking unavailable (brew install bd)"
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
CORE_SKILLS=(
    "session-opening"
    "session-closing"
    "beads"
)

for skill in "${CORE_SKILLS[@]}"; do
    SKILL_PATH="$SKILLS_DIR/$skill"
    if [ -L "$SKILL_PATH" ]; then
        TARGET=$(readlink "$SKILL_PATH")
        if [ ! -e "$TARGET" ]; then
            fail "Skill $skill → $TARGET (BROKEN symlink)"
        elif [ -f "$TARGET/SKILL.md" ] || [ -f "$SKILL_PATH/SKILL.md" ]; then
            pass "Skill $skill"
        else
            warn "Skill $skill exists but no SKILL.md"
        fi
    elif [ -d "$SKILL_PATH" ]; then
        if [ -f "$SKILL_PATH/SKILL.md" ]; then
            pass "Skill $skill"
        else
            warn "Skill $skill exists but no SKILL.md"
        fi
    else
        warn "Skill $skill not found (optional but recommended)"
    fi
done

# ═══════════════════════════════════════════════════════════════
section "Memory System"
# ═══════════════════════════════════════════════════════════════

if [ -d "$HOME/Repos/claude-mem" ]; then
    pass "claude-mem repo exists"

    if [ -f "$HOME/.claude/memory/memory.db" ]; then
        DB_SIZE=$(du -h "$HOME/.claude/memory/memory.db" 2>/dev/null | cut -f1)
        SOURCE_COUNT=$(sqlite3 "$HOME/.claude/memory/memory.db" "SELECT COUNT(*) FROM sources" 2>/dev/null || echo "?")
        pass "Memory database ($DB_SIZE, $SOURCE_COUNT sources)"
    else
        warn "Memory database not found at ~/.claude/memory/memory.db"
    fi
else
    warn "claude-mem repo not found - memory search unavailable"
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
