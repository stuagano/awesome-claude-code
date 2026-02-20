#!/usr/bin/env bash
# install.sh - Set up awesome-claude-code resources
#
# Two modes:
#   --lite    Just install global ~/.claude/ config (land, preferences, safety rules).
#             No deck, no tmux, no Agent Teams. Works with plain `claude` anywhere.
#
#   (default) Full install: global config + deck/tmux orchestrator + Agent Teams.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/stuagano/awesome-claude-code/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/stuagano/awesome-claude-code/main/install.sh | bash -s -- --lite
#   bash install.sh --lite

set -euo pipefail

REPO_URL="https://github.com/stuagano/awesome-claude-code.git"
REPO_BRANCH="main"
DECK_HOME="${AGENT_DECK_HOME:-$HOME/.agent-deck}"

# Colors
if [ -t 1 ]; then
    BOLD='\033[1m' DIM='\033[2m'
    GREEN='\033[0;32m' YELLOW='\033[0;33m' CYAN='\033[0;36m'
    RED='\033[0;31m' RESET='\033[0m'
else
    BOLD='' DIM='' GREEN='' YELLOW='' CYAN='' RED='' RESET=''
fi

info()  { echo -e "${CYAN}${BOLD}>>>${RESET} $*"; }
ok()    { echo -e "${GREEN}${BOLD} +${RESET} $*"; }
warn()  { echo -e "${YELLOW}${BOLD} !${RESET} $*"; }
err()   { echo -e "${RED}${BOLD} x${RESET} $*" >&2; }

check_dependencies() {
    local missing=""

    if ! command -v git &>/dev/null; then
        missing="${missing}git "
    fi

    if [ -n "$missing" ]; then
        err "Missing required dependencies: $missing"
        echo ""
        echo "Install instructions:"
        echo -e "  ${CYAN}macOS:${RESET}   brew install $missing"
        echo -e "  ${CYAN}Ubuntu:${RESET}  sudo apt install $missing"
        echo -e "  ${CYAN}Fedora:${RESET}  sudo dnf install $missing"
        echo ""
        exit 1
    fi
}

# ── Fetch/update the resource cache ──────────────────────────────────
fetch_cache() {
    local cache_dir="$1"

    mkdir -p "$(dirname "$cache_dir")"

    if [ -d "$cache_dir/resources" ]; then
        info "Updating resource cache..."
        if ! git -C "$cache_dir" pull --quiet 2>/dev/null; then
            warn "Failed to update cache. Continuing with existing version..."
        fi
    else
        info "Fetching awesome-claude-code resources..."
        if ! git clone --depth 1 --branch "$REPO_BRANCH" --single-branch \
             "$REPO_URL" "$cache_dir" 2>/dev/null; then
            err "Failed to clone. Check your network connection."
            exit 1
        fi
        if [ ! -d "$cache_dir/resources" ]; then
            err "Clone incomplete - resources directory missing."
            rm -rf "$cache_dir"
            exit 1
        fi
    fi
    date +%s > "$cache_dir/.fetch_time"
    ok "Resources cached."
}

# ── Install global ~/.claude/ config ─────────────────────────────────
install_global_config() {
    local cache_dir="$1"
    local claude_dir="$HOME/.claude"
    local cache_ccs="$cache_dir/.claude"

    mkdir -p "$claude_dir"

    if [ ! -d "$cache_ccs" ]; then
        warn ".claude not found in cache. Skipping global config."
        return 0
    fi

    # Global slash commands (e.g., /land, /save — available in every session)
    mkdir -p "$claude_dir/commands"
    local cmd_count=0
    for cmd_file in "$cache_ccs/commands/"*.md; do
        [ -f "$cmd_file" ] || continue
        cp "$cmd_file" "$claude_dir/commands/$(basename "$cmd_file")"
        cmd_count=$((cmd_count + 1))
    done
    [ "$cmd_count" -gt 0 ] && ok "Global commands: $cmd_count installed (/land, /save)"

    # Preference modes (deep-work, exploratory, writing)
    mkdir -p "$claude_dir/preferences"
    local pref_count=0
    for pref in "$cache_ccs/preferences/"*.md; do
        [ -f "$pref" ] || continue
        cp "$pref" "$claude_dir/preferences/$(basename "$pref")"
        pref_count=$((pref_count + 1))
    done
    [ "$pref_count" -gt 0 ] && ok "Preference modes: $pref_count installed"

    # Hot index directory for /land
    mkdir -p "$claude_dir/projects.d"

    # Global CLAUDE.md (safety rules, preference mode refs, time awareness)
    local global_claude="$claude_dir/CLAUDE.md"
    local marker="# --- awesome-claude-code: global-config ---"
    if [ ! -f "$global_claude" ] || ! grep -qF "$marker" "$global_claude" 2>/dev/null; then
        {
            [ -f "$global_claude" ] && echo ""
            echo "$marker"
            echo ""
            cat "$cache_ccs/CLAUDE.md"
        } >> "$global_claude"
        ok "Global CLAUDE.md: safety rules, preference modes, time awareness"
    else
        ok "Global CLAUDE.md: already configured"
    fi
}

# ── Install deck/tmux orchestrator + Agent Teams ────────────────────
install_deck() {
    local cache_dir="$1"

    mkdir -p "$DECK_HOME/sessions" "$DECK_HOME/cache"

    # Install agent-deck.sh
    if [ -f "$cache_dir/agent-deck.sh" ]; then
        cp "$cache_dir/agent-deck.sh" "$DECK_HOME/agent-deck.sh"
        chmod +x "$DECK_HOME/agent-deck.sh"
        ok "Installed: ~/.agent-deck/agent-deck.sh"
    else
        err "agent-deck.sh not found in repo."
        exit 1
    fi

    # ── Initialize global config ──

    local global_config="$DECK_HOME/config.conf"
    if [ ! -f "$global_config" ]; then
        cat > "$global_config" << 'CONFIG_EOF'
# Agent Deck — Global Configuration
# Edit directly or use: deck config set <key> <value>

# Enable Agent Teams for all sessions (1 = enabled)
CONF_AGENT_TEAMS=1

# Prefix for tmux session names
CONF_SESSION_PREFIX=deck

# Auto-update resource cache (true/false)
CONF_AUTO_UPDATE=true

# Default domain for new sessions
CONF_DEFAULT_DOMAIN=general

# Editor for config files
CONF_EDITOR=vi
CONFIG_EOF
        ok "Global config: $global_config"
    else
        ok "Global config: already exists"
    fi

    # ── Enable Agent Teams ──

    local claude_settings_dir="$HOME/.claude"
    local claude_settings="$claude_settings_dir/settings.json"
    mkdir -p "$claude_settings_dir"

    if [ -f "$claude_settings" ]; then
        if ! grep -q 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$claude_settings" 2>/dev/null; then
            if grep -q '"env"' "$claude_settings" 2>/dev/null; then
                warn "Agent Teams not enabled in settings. Add manually:"
                echo -e "  ${DIM}\"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\": \"1\"${RESET}"
                echo -e "  ${DIM}to the \"env\" block in $claude_settings${RESET}"
            else
                warn "Agent Teams not enabled in settings. Add manually:"
                echo -e "  ${DIM}\"env\": { \"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\": \"1\" }${RESET}"
                echo -e "  ${DIM}to $claude_settings${RESET}"
            fi
        else
            ok "Agent Teams: already enabled"
        fi
    else
        cat > "$claude_settings" << 'SETTINGS_EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
SETTINGS_EOF
        ok "Agent Teams: enabled in $claude_settings"
    fi

    # Install `deck` command
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    # Create `deck` wrapper
    # - No args inside tmux → detach (go back to dashboard)
    # - No args outside tmux → launch dashboard
    # - With args → always pass through to agent-deck
    cat > "$bin_dir/deck" << 'DECK_EOF'
#!/usr/bin/env bash
if [ $# -eq 0 ] && [ -n "${TMUX:-}" ]; then
    tmux detach
else
    exec bash ~/.agent-deck/agent-deck.sh "$@"
fi
DECK_EOF
    chmod +x "$bin_dir/deck"
    ok "Installed: ~/.local/bin/deck"

    cat > "$bin_dir/agent-deck" << 'AD_EOF'
#!/usr/bin/env bash
exec bash ~/.agent-deck/agent-deck.sh "$@"
AD_EOF
    chmod +x "$bin_dir/agent-deck"
    ok "Installed: ~/.local/bin/agent-deck"

    # Check if ~/.local/bin is in PATH
    if ! echo "$PATH" | tr ':' '\n' | grep -q "$bin_dir"; then
        warn "$bin_dir is not in your PATH. Add to your shell profile:"
        echo -e "  ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
        echo ""
    fi
}

# ══════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════

main() {
    local mode="full"
    for arg in "$@"; do
        case "$arg" in
            --lite) mode="lite" ;;
            --help|-h)
                echo "Usage: install.sh [--lite]"
                echo ""
                echo "  --lite    Global ~/.claude/ config only (land, preferences, safety rules)"
                echo "            No deck, no tmux, no Agent Teams. Works with plain 'claude'."
                echo ""
                echo "  (default) Full install: global config + deck orchestrator + Agent Teams"
                exit 0
                ;;
        esac
    done

    local cache_dir="$DECK_HOME/cache/awesome-claude-code"

    # Cleanup on failure
    trap 'if [ $? -ne 0 ]; then
        [ -d "$cache_dir" ] && [ ! -d "$cache_dir/resources" ] && rm -rf "$cache_dir"
    fi' EXIT

    echo ""
    if [ "$mode" = "lite" ]; then
        echo -e "${BOLD}Awesome Claude Code — Lite Install${RESET}"
        echo -e "${DIM}Global config only (no deck/tmux)${RESET}"
    else
        echo -e "${BOLD}Awesome Claude Code — Full Install${RESET}"
    fi
    echo ""

    check_dependencies

    # ── Fetch resources ──
    mkdir -p "$DECK_HOME/cache"
    fetch_cache "$cache_dir"

    # ── Always install global config ──
    install_global_config "$cache_dir"

    # ── Full mode: also install deck + Agent Teams ──
    if [ "$mode" = "full" ]; then
        install_deck "$cache_dir"
    fi

    # ── Done ──
    echo ""
    if [ "$mode" = "lite" ]; then
        echo -e "${BOLD}${GREEN}Global config installed.${RESET}"
        echo ""
        echo -e "${DIM}────────────────────────────────────────${RESET}"
        echo ""
        echo "What you got:"
        echo -e "  ${BOLD}/land${RESET}                          Save conversations as versioned projects"
        echo -e "  ${BOLD}/save${RESET}                          Quick-update current project's SUMMARY.md"
        echo -e "  ${BOLD}mode: deep-work${RESET}                Maximum focus, minimal chatter"
        echo -e "  ${BOLD}mode: exploratory${RESET}              Brainstorm, surface options"
        echo -e "  ${BOLD}mode: writing${RESET}                  Prose & documentation tone"
        echo -e "  ${BOLD}~/.claude/CLAUDE.md${RESET}            Safety rules, auto-detect projects, auto-accumulate"
        echo ""
        echo "Just run ${BOLD}claude${RESET} in any project. Everything works globally."
        echo ""
        echo -e "${DIM}Want deck/tmux later? Re-run without --lite.${RESET}"
    else
        echo -e "${BOLD}${GREEN}Agent Deck installed.${RESET}"
        echo ""
        echo -e "${DIM}────────────────────────────────────────${RESET}"
        echo ""
        echo "Usage:"
        echo -e "  ${BOLD}deck${RESET}                          Dashboard (home base)"
        echo -e "  ${BOLD}deck setup ~/myproject${RESET}        Set up a project"
        echo -e "  ${BOLD}deck open mirion${RESET}              Enter a project session"
        echo -e "  ${BOLD}deck${RESET}                          ${DIM}(from inside a project) back to dashboard${RESET}"
    fi
    echo ""
}

main "$@"
