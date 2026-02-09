#!/usr/bin/env bash
# agent-deck - Home base for Claude Code agent teams
#
# A session is scoped to a project folder. Each session launches a Claude
# Code team lead (orchestrator) that can spawn Agent Teams teammates for
# parallel work. The deck is where you manage all your sessions.
#
# Usage:
#   agent-deck                        Home base (interactive)
#   agent-deck setup [dir]            Create + configure a session for a project
#   agent-deck open <session>         Open a session (attach or create)
#   agent-deck spawn <session>        Add another agent window to a session
#   agent-deck list                   List all sessions
#   agent-deck kill <session>         Kill a session
#   agent-deck help                   Show help

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────
DECK_HOME="${AGENT_DECK_HOME:-$HOME/.agent-deck}"
SESSIONS_DIR="$DECK_HOME/sessions"
GLOBAL_CONFIG="$DECK_HOME/config.conf"
ACC_REPO_URL="https://github.com/stuagano/awesome-claude-code.git"
ACC_CACHE="$DECK_HOME/cache/awesome-claude-code"
SESSION_PREFIX="deck"

# ── Global config defaults ──────────────────────────────────────────
CONF_AGENT_TEAMS="1"
CONF_SESSION_PREFIX="deck"
CONF_AUTO_UPDATE="true"
CONF_DEFAULT_DOMAIN="general"
CONF_EDITOR="${EDITOR:-vi}"

# ── Colors ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD='\033[1m' DIM='\033[2m'
    GREEN='\033[0;32m' YELLOW='\033[0;33m' CYAN='\033[0;36m'
    RED='\033[0;31m' BLUE='\033[0;34m' MAGENTA='\033[0;35m' RESET='\033[0m'
else
    BOLD='' DIM='' GREEN='' YELLOW='' CYAN='' RED='' BLUE='' MAGENTA='' RESET=''
fi

info()  { echo -e "${CYAN}${BOLD}>>>${RESET} $*"; }
ok()    { echo -e "${GREEN}${BOLD} +${RESET} $*"; }
warn()  { echo -e "${YELLOW}${BOLD} !${RESET} $*"; }
err()   { echo -e "${RED}${BOLD} x${RESET} $*" >&2; }

# ── Init ──────────────────────────────────────────────────────────────
init_deck() {
    mkdir -p "$SESSIONS_DIR" "$DECK_HOME/cache"
    load_global_config
}

# ── Global config ────────────────────────────────────────────────────
load_global_config() {
    if [ -f "$GLOBAL_CONFIG" ]; then
        # shellcheck disable=SC1090
        source "$GLOBAL_CONFIG"
    fi
    SESSION_PREFIX="${CONF_SESSION_PREFIX:-deck}"
}

save_global_config() {
    cat > "$GLOBAL_CONFIG" << EOF
# Agent Deck — Global Configuration
# Edit directly or use: deck config set <key> <value>

# Enable Agent Teams for all sessions (1 = enabled)
CONF_AGENT_TEAMS=${CONF_AGENT_TEAMS}

# Prefix for tmux session names
CONF_SESSION_PREFIX=${CONF_SESSION_PREFIX}

# Auto-update resource cache (true/false)
CONF_AUTO_UPDATE=${CONF_AUTO_UPDATE}

# Default domain for new sessions
CONF_DEFAULT_DOMAIN=${CONF_DEFAULT_DOMAIN}

# Editor for config files
CONF_EDITOR=${CONF_EDITOR}
EOF
}

cmd_config() {
    local subcmd="${1:-}"
    shift 2>/dev/null || true

    case "$subcmd" in
        ""|show)
            echo ""
            echo -e "${BOLD}${BLUE}  Global Config${RESET}"
            echo -e "${DIM}  $GLOBAL_CONFIG${RESET}"
            echo -e "${DIM}  ─────────────────────────────────────────${RESET}"
            echo -e "  agent_teams      ${BOLD}${CONF_AGENT_TEAMS}${RESET}"
            echo -e "  session_prefix   ${BOLD}${CONF_SESSION_PREFIX}${RESET}"
            echo -e "  auto_update      ${BOLD}${CONF_AUTO_UPDATE}${RESET}"
            echo -e "  default_domain   ${BOLD}${CONF_DEFAULT_DOMAIN}${RESET}"
            echo -e "  editor           ${BOLD}${CONF_EDITOR}${RESET}"
            echo ""
            echo -e "${DIM}  Claude settings: ~/.claude/settings.json${RESET}"
            if [ -f "$HOME/.claude/settings.json" ]; then
                if grep -q 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$HOME/.claude/settings.json" 2>/dev/null; then
                    echo -e "  Agent Teams:     ${GREEN}enabled${RESET}"
                else
                    echo -e "  Agent Teams:     ${YELLOW}not in settings${RESET}"
                fi
            else
                echo -e "  Agent Teams:     ${RED}settings.json missing${RESET}"
            fi
            echo ""
            ;;
        set)
            local key="${1:-}" value="${2:-}"
            if [ -z "$key" ] || [ -z "$value" ]; then
                err "Usage: deck config set <key> <value>"
                echo "  Keys: agent_teams, session_prefix, auto_update, default_domain, editor"
                return 1
            fi
            case "$key" in
                agent_teams)     CONF_AGENT_TEAMS="$value" ;;
                session_prefix)  CONF_SESSION_PREFIX="$value" ;;
                auto_update)     CONF_AUTO_UPDATE="$value" ;;
                default_domain)  CONF_DEFAULT_DOMAIN="$value" ;;
                editor)          CONF_EDITOR="$value" ;;
                *)               err "Unknown key: $key"; return 1 ;;
            esac
            save_global_config
            ok "Set $key = $value"
            ;;
        edit)
            "${CONF_EDITOR}" "$GLOBAL_CONFIG"
            ;;
        path)
            echo "$GLOBAL_CONFIG"
            ;;
        init)
            save_global_config
            ok "Config initialized: $GLOBAL_CONFIG"
            ;;
        *)
            err "Usage: deck config [show|set|edit|path|init]"
            ;;
    esac
}

# ── Resource cache ────────────────────────────────────────────────────
ensure_cache() {
    require_git

    local lockfile="$ACC_CACHE/.fetch_lock"

    if [ -d "$ACC_CACHE/resources" ]; then
        local age=0
        if [ -f "$ACC_CACHE/.fetch_time" ]; then
            local fetch_time
            fetch_time=$(cat "$ACC_CACHE/.fetch_time")
            age=$(( $(date +%s) - fetch_time ))
        fi
        if [ "$age" -gt 86400 ]; then
            # Acquire lock with timeout
            local lock_acquired=false
            for i in {1..10}; do
                if mkdir "$lockfile" 2>/dev/null; then
                    lock_acquired=true
                    break
                fi
                sleep 1
            done

            if [ "$lock_acquired" = true ]; then
                info "Updating resources..."
                if git -C "$ACC_CACHE" pull --quiet 2>/dev/null; then
                    date +%s > "$ACC_CACHE/.fetch_time"
                fi
                rmdir "$lockfile"
            fi
        fi
        return 0
    fi

    # Initial clone with locking
    info "Fetching awesome-claude-code resources (one-time)..."

    local lock_acquired=false
    for i in {1..10}; do
        if mkdir "$lockfile" 2>/dev/null; then
            lock_acquired=true
            break
        fi
        sleep 1
    done

    if [ "$lock_acquired" = true ]; then
        if ! git clone --depth 1 "$ACC_REPO_URL" "$ACC_CACHE" 2>/dev/null; then
            rmdir "$lockfile"
            err "Failed to clone. Check network."
            return 1
        fi
        if [ ! -d "$ACC_CACHE/resources" ]; then
            rmdir "$lockfile"
            err "Clone incomplete - resources missing"
            rm -rf "$ACC_CACHE"
            return 1
        fi
        date +%s > "$ACC_CACHE/.fetch_time"
        ok "Resources cached."
        rmdir "$lockfile"
    else
        err "Failed to acquire lock for cache initialization"
        return 1
    fi
}

# ── Resource mappings ─────────────────────────────────────────────────
commands_for_domain() {
    case "$1" in
        ml)          echo "mlflow-log-model uc-register-model feature-table databricks-deploy" ;;
        databricks)  echo "databricks-job databricks-deploy feature-table mlflow-log-model uc-register-model" ;;
        devops)      echo "act create-hook husky" ;;
        *)           echo "" ;;
    esac
}

templates_for_domain() {
    case "$1" in
        ml)          echo "DSPy MLflow-Databricks Feature-Engineering Vector-Search Mosaic-AI-Agents Databricks-AI-Dev-Kit" ;;
        databricks)  echo "Databricks-Full-Stack Delta-Live-Tables Databricks-Jobs Unity-Catalog" ;;
        backend)     echo "SG-Cars-Trends-Backend LangGraphJS AWS-MCP-Server Giselle" ;;
        frontend)    echo "APX-Databricks-Apps Course-Builder JSBeeb" ;;
        devops)      echo "Databricks-MCP-Server claude-code-mcp-enhanced" ;;
        cli)         echo "TPL Cursor-Tools" ;;
        general)     echo "Basic-Memory" ;;
        *)           echo "" ;;
    esac
}

commands_for_needs() {
    local cmds=""
    for need in $1; do
        case "$need" in
            git)     cmds="$cmds create-pr fix-github-issue create-worktrees update-branch-name husky" ;;
            quality) cmds="$cmds testing_plan_integration create-hook" ;;
            context) cmds="$cmds context-prime initref load-llms-txt" ;;
            docs)    cmds="$cmds update-docs add-to-changelog" ;;
            deploy)  cmds="$cmds release act" ;;
        esac
    done
    echo "$cmds"
}

# ── Project detection ─────────────────────────────────────────────────
detect_project() {
    local dir="$1"
    DETECTED_LANG="" DETECTED_FRAMEWORK="" DETECTED_DEFAULT_DOMAIN="7"

    if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/requirements.txt" ]; then
        DETECTED_LANG="python"
    elif [ -f "$dir/package.json" ]; then
        DETECTED_LANG="javascript"
    elif [ -f "$dir/Cargo.toml" ]; then
        DETECTED_LANG="rust"
    elif [ -f "$dir/go.mod" ]; then
        DETECTED_LANG="go"
    elif [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ]; then
        DETECTED_LANG="java"
    elif [ -f "$dir/Gemfile" ]; then
        DETECTED_LANG="ruby"
    fi

    if [ -f "$dir/package.json" ]; then
        grep -q '"react"\|"next"' "$dir/package.json" 2>/dev/null && DETECTED_FRAMEWORK="react" && DETECTED_DEFAULT_DOMAIN="4"
        grep -q '"express"\|"fastify"' "$dir/package.json" 2>/dev/null && DETECTED_FRAMEWORK="node-api" && DETECTED_DEFAULT_DOMAIN="3"
    fi
    if [ -f "$dir/pyproject.toml" ]; then
        grep -q 'fastapi\|django\|flask' "$dir/pyproject.toml" 2>/dev/null && DETECTED_FRAMEWORK="python-api" && DETECTED_DEFAULT_DOMAIN="3"
        grep -q 'mlflow\|databricks\|pyspark' "$dir/pyproject.toml" 2>/dev/null && DETECTED_FRAMEWORK="databricks" && DETECTED_DEFAULT_DOMAIN="2"
        grep -q 'torch\|tensorflow\|scikit' "$dir/pyproject.toml" 2>/dev/null && DETECTED_FRAMEWORK="ml" && DETECTED_DEFAULT_DOMAIN="1"
    fi
}

# ── Session config ────────────────────────────────────────────────────
session_name_from_path() {
    local name
    name=$(basename "$1" | tr '.' '-' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    echo "${SESSION_PREFIX}-${name}"
}

save_session() {
    local name="$1" dir="$2" domain="$3" needs="$4" commands="$5" templates="$6"
    # Team name derived from session name (strip prefix)
    local team_name="${name#${SESSION_PREFIX}-}"
    cat > "$SESSIONS_DIR/$name.conf" << EOF
# Agent Deck Session: $name
# Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
PROJECT_DIR="$dir"
DOMAIN="$domain"
NEEDS="$needs"
COMMANDS="$commands"
TEMPLATES="$templates"
TEAM_NAME=$team_name
EOF
}

load_session() {
    local name="$1"
    # Try with and without prefix
    local file="$SESSIONS_DIR/$name.conf"
    [ ! -f "$file" ] && file="$SESSIONS_DIR/${SESSION_PREFIX}-${name}.conf"
    if [ ! -f "$file" ]; then
        err "Session not found: $name"
        return 1
    fi
    # shellcheck disable=SC1090
    source "$file"
}

tmux_session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

tmux_window_count() {
    tmux list-windows -t "$1" 2>/dev/null | wc -l | tr -d ' '
}

# ── Install resources into a directory ────────────────────────────────
install_resources() {
    local target_dir="$1" commands="$2" templates="$3"

    ensure_cache || return 1

    # Install commands
    mkdir -p "$target_dir/.claude/commands"
    local cmd_count=0
    for cmd in $commands; do
        local src="$ACC_CACHE/resources/slash-commands/$cmd"
        if [ -d "$src" ]; then
            local md_file
            md_file=$(find "$src" -maxdepth 1 -name "*.md" | head -1)
            if [ -n "$md_file" ]; then
                local dest="$target_dir/.claude/commands/$(basename "$md_file")"
                if [ ! -f "$dest" ]; then
                    cp "$md_file" "$dest"
                    ok "/$cmd"
                    cmd_count=$((cmd_count + 1))
                fi
            fi
        fi
    done

    # Install templates
    local tpl_count=0
    for tpl in $templates; do
        local src="$ACC_CACHE/resources/claude.md-files/$tpl/CLAUDE.md"
        if [ -f "$src" ]; then
            local dest="$target_dir/CLAUDE.md"
            local marker="# --- awesome-claude-code: $tpl ---"
            if [ -f "$dest" ] && grep -qF "$marker" "$dest" 2>/dev/null; then
                continue
            fi
            {
                [ -f "$dest" ] && echo ""
                echo "$marker"
                echo ""
                cat "$src"
            } >> "$dest"
            ok "$tpl"
            tpl_count=$((tpl_count + 1))
        fi
    done

    echo ""
    ok "Installed $cmd_count commands + $tpl_count templates"
}

# ══════════════════════════════════════════════════════════════════════
# COMMANDS
# ══════════════════════════════════════════════════════════════════════

# ── setup: create + configure a session for a project ─────────────────
cmd_setup() {
    local target_dir="${1:-$(pwd)}"
    target_dir="$(cd "$target_dir" && pwd)"

    local name
    name=$(session_name_from_path "$target_dir")

    echo ""
    echo -e "${BOLD}${BLUE}  Agent Deck — Session Setup${RESET}"
    echo -e "${DIM}  $target_dir${RESET}"
    echo ""

    # Detect project
    detect_project "$target_dir"
    if [ -n "$DETECTED_LANG" ]; then
        echo -e "  Detected: ${CYAN}$DETECTED_LANG${RESET}"
    fi
    if [ -n "$DETECTED_FRAMEWORK" ]; then
        echo -e "  Framework: ${CYAN}$DETECTED_FRAMEWORK${RESET}"
    fi
    [ -d "$target_dir/.claude" ] && echo -e "  Claude Code: ${GREEN}configured${RESET}"
    echo ""

    # ── Domain ──
    echo -e "  ${BOLD}What are you building?${RESET}"
    echo ""
    echo "    1) ML / Data Science"
    echo "    2) Data Engineering / Databricks"
    echo "    3) Backend / API"
    echo "    4) Frontend / Web App"
    echo "    5) DevOps / Infrastructure"
    echo "    6) CLI / Tooling"
    echo "    7) General software project"
    echo ""

    # Use detected domain, or fall back to global config default
    local default_domain="${DETECTED_DEFAULT_DOMAIN:-7}"
    if [ "$default_domain" = "7" ] && [ "$CONF_DEFAULT_DOMAIN" != "general" ]; then
        case "$CONF_DEFAULT_DOMAIN" in
            ml)          default_domain="1" ;;
            databricks)  default_domain="2" ;;
            backend)     default_domain="3" ;;
            frontend)    default_domain="4" ;;
            devops)      default_domain="5" ;;
            cli)         default_domain="6" ;;
        esac
    fi
    echo -ne "  Choice [1-7] (${default_domain}): "
    read -r domain_choice
    domain_choice="${domain_choice:-$default_domain}"

    local domain
    case "$domain_choice" in
        1) domain="ml" ;; 2) domain="databricks" ;; 3) domain="backend" ;;
        4) domain="frontend" ;; 5) domain="devops" ;; 6) domain="cli" ;;
        *) domain="general" ;;
    esac

    # ── Needs ──
    echo ""
    echo -e "  ${BOLD}What do you need?${RESET} ${DIM}(multiple: 1 3 5)${RESET}"
    echo ""
    echo "    1) Git workflow      — Commits, PRs, branches"
    echo "    2) Code quality      — Reviews, optimization, testing"
    echo "    3) Project context   — Help Claude understand your code"
    echo "    4) Documentation     — Docs, changelogs, release notes"
    echo "    5) Deployment        — CI/CD, releases"
    echo "    6) Everything"
    echo ""
    echo -n "  Choice: "
    read -r needs_choice

    local needs=""
    for n in $needs_choice; do
        case "$n" in
            1) needs="$needs git" ;; 2) needs="$needs quality" ;;
            3) needs="$needs context" ;; 4) needs="$needs docs" ;;
            5) needs="$needs deploy" ;; 6) needs="git quality context docs deploy" ;;
        esac
    done

    # ── Build resource list ──
    local base_cmds="commit pr-review optimize"
    local base_templates=""
    local domain_cmds
    domain_cmds=$(commands_for_domain "$domain")
    local needs_cmds
    needs_cmds=$(commands_for_needs "$needs")
    local all_cmds
    all_cmds=$(echo "$base_cmds $domain_cmds $needs_cmds" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    local domain_templates
    domain_templates=$(templates_for_domain "$domain")
    local templates
    templates=$(echo "$base_templates $domain_templates" | tr ' ' '\n' | sort -u | tr '\n' ' ')

    # ── Preview ──
    echo ""
    echo -e "${DIM}  ─────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Session: ${GREEN}$name${RESET}"
    echo ""
    echo -e "  ${BOLD}Commands:${RESET}"
    for cmd in $all_cmds; do
        echo -e "    ${GREEN}/$cmd${RESET}"
    done
    if [ -n "$templates" ]; then
        echo ""
        echo -e "  ${BOLD}Templates:${RESET}"
        for tpl in $templates; do
            echo -e "    ${CYAN}$tpl${RESET}"
        done
    fi

    # ── Confirm + install ──
    echo ""
    echo -ne "  Set up this session? ${DIM}[Y/n]${RESET} "
    read -r confirm
    confirm="${confirm:-y}"
    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        info "Setup cancelled."
        return 0
    fi

    echo ""
    info "Installing resources..."
    echo ""
    install_resources "$target_dir" "$all_cmds" "$templates"

    # Save session config
    save_session "$name" "$target_dir" "$domain" "$needs" "$all_cmds" "$templates"

    # ── Launch? ──
    echo ""
    if command -v tmux &>/dev/null; then
        echo -ne "  Launch session now? ${DIM}[Y/n]${RESET} "
        read -r launch_confirm
        launch_confirm="${launch_confirm:-y}"
        if [ "$launch_confirm" != "n" ] && [ "$launch_confirm" != "N" ]; then
            cmd_open "$name"
            return
        fi
    fi

    echo ""
    echo -e "${BOLD}${GREEN}  Session ready.${RESET}"
    echo ""
    echo "  Open it:"
    echo -e "    ${CYAN}agent-deck open $name${RESET}"
    echo ""
    echo "  Add more agents:"
    echo -e "    ${CYAN}agent-deck spawn $name${RESET}"
    echo ""
}

# ── open: attach to or create a tmux session ──────────────────────────
cmd_open() {
    require_tmux
    require_claude
    local name="$1"

    # Add prefix if needed
    [[ "$name" == ${SESSION_PREFIX}-* ]] || name="${SESSION_PREFIX}-${name}"

    # If tmux session exists, attach
    if tmux_session_exists "$name"; then
        echo -e "${GREEN}Attaching to: ${name}${RESET}"
        tmux attach -t "$name"
        return
    fi

    # Try to load session config for the project dir
    local project_dir="" team_name=""
    if [ -f "$SESSIONS_DIR/$name.conf" ]; then
        # shellcheck disable=SC1090
        source "$SESSIONS_DIR/$name.conf"
        project_dir="$PROJECT_DIR"
        team_name="${TEAM_NAME:-${name#${SESSION_PREFIX}-}}"
    fi

    if [ -z "$project_dir" ] || [ ! -d "$project_dir" ]; then
        err "No session config for '$name'. Run: agent-deck setup <project-dir>"
        return 1
    fi

    echo -e "${GREEN}Launching: ${name}${RESET}"
    echo -e "${DIM}Project: ${project_dir}${RESET}"

    # Launch with Agent Teams if enabled in global config
    tmux new-session -d -s "$name" -c "$project_dir"
    if [ "${CONF_AGENT_TEAMS:-1}" = "1" ]; then
        echo -e "${DIM}Agent Teams: enabled (team: ${team_name})${RESET}"
        tmux set-environment -t "$name" CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1
        tmux send-keys -t "$name" "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude" Enter
    else
        echo -e "${DIM}Agent Teams: disabled${RESET}"
        tmux send-keys -t "$name" "claude" Enter
    fi
    tmux attach -t "$name"
}

# ── spawn: add another agent window to a running session ──────────────
cmd_spawn() {
    require_tmux
    require_claude
    local name="$1"
    [[ "$name" == ${SESSION_PREFIX}-* ]] || name="${SESSION_PREFIX}-${name}"

    if ! tmux_session_exists "$name"; then
        # If session config exists, open it first
        if [ -f "$SESSIONS_DIR/$name.conf" ]; then
            cmd_open "$name"
            return
        fi
        err "No running session: $name"
        return 1
    fi

    local window_count
    window_count=$(tmux_window_count "$name")
    local new_window="agent-$((window_count + 1))"

    echo -e "${GREEN}Spawning agent window: ${new_window}${RESET}"

    tmux new-window -t "$name" -n "$new_window"
    tmux send-keys -t "$name:$new_window" "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude" Enter

    # If we're not attached, attach
    if [ -z "${TMUX:-}" ]; then
        tmux attach -t "$name"
    else
        tmux select-window -t "$name:$new_window"
    fi
}

# ── Task status from Agent Teams ──────────────────────────────────────
get_team_task_summary() {
    local team_name="$1"
    local tasks_dir="$HOME/.claude/tasks/$team_name"

    [ ! -d "$tasks_dir" ] && return

    local completed=0 in_progress=0 pending=0 total=0
    for task_file in "$tasks_dir"/*.json; do
        [ -f "$task_file" ] || continue
        total=$((total + 1))
        # Parse status from JSON (simple grep, no jq dependency)
        local status
        status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$task_file" 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"' || true)
        case "$status" in
            completed)   completed=$((completed + 1)) ;;
            in_progress) in_progress=$((in_progress + 1)) ;;
            *)           pending=$((pending + 1)) ;;
        esac
    done

    [ "$total" -eq 0 ] && return

    local parts=""
    [ "$completed" -gt 0 ] && parts="${GREEN}${completed}✓${RESET}"
    [ "$in_progress" -gt 0 ] && parts="${parts:+$parts }${YELLOW}${in_progress}→${RESET}"
    [ "$pending" -gt 0 ] && parts="${parts:+$parts }${DIM}${pending}○${RESET}"
    echo "$parts"
}

# ── list: show all sessions ───────────────────────────────────────────
cmd_list() {
    echo ""
    echo -e "${BOLD}${BLUE}  Sessions${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────${RESET}"

    local has_any=false

    for file in "$SESSIONS_DIR"/*.conf; do
        [ -f "$file" ] || continue
        has_any=true

        local name project_dir domain team_name
        name=$(basename "$file" .conf)
        project_dir=$(grep '^PROJECT_DIR=' "$file" | cut -d= -f2 | tr -d '"')
        domain=$(grep '^DOMAIN=' "$file" | cut -d= -f2 | tr -d '"')
        team_name=$(grep '^TEAM_NAME=' "$file" | cut -d= -f2 || echo "")
        team_name="${team_name:-${name#${SESSION_PREFIX}-}}"

        local status_icon windows_info
        if command -v tmux &>/dev/null && tmux_session_exists "$name"; then
            local wc
            wc=$(tmux_window_count "$name")
            status_icon="${GREEN}●${RESET}"
            windows_info=" ${DIM}(${wc} agent$([ "$wc" != "1" ] && echo "s" || true))${RESET}"
        else
            status_icon="${DIM}○${RESET}"
            windows_info=""
        fi

        # Get task progress from Agent Teams
        local task_summary
        task_summary=$(get_team_task_summary "$team_name" || true)
        local task_info=""
        [ -n "$task_summary" ] && task_info="  ${task_summary}" || true

        echo -e "  $status_icon ${BOLD}$name${RESET}$windows_info  ${DIM}$domain${RESET}${task_info}"
        echo -e "    ${DIM}$project_dir${RESET}"
    done

    if [ "$has_any" = false ]; then
        echo -e "  ${DIM}No sessions. Run: agent-deck setup <project-dir>${RESET}"
    fi
    echo ""
}

# ── kill: terminate a session ─────────────────────────────────────────
cmd_kill() {
    require_tmux
    local name="$1"
    [[ "$name" == ${SESSION_PREFIX}-* ]] || name="${SESSION_PREFIX}-${name}"

    if ! tmux_session_exists "$name"; then
        err "No running session: $name"
        return 1
    fi

    tmux kill-session -t "$name"
    ok "Killed: $name"
}

# ── home: interactive dashboard (homepage) ───────────────────────────
cmd_home() {
    local has_tmux=false
    command -v tmux &>/dev/null && has_tmux=true

    local session_count=0
    for f in "$SESSIONS_DIR"/*.conf; do
        [ -f "$f" ] && session_count=$((session_count + 1))
    done

    # ── Banner ──
    echo ""
    echo -e "${BOLD}${BLUE}  ┌─────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${BLUE}  │         Agent Deck              │${RESET}"
    echo -e "${BOLD}${BLUE}  │   Home base for Claude Code     │${RESET}"
    echo -e "${BOLD}${BLUE}  └─────────────────────────────────┘${RESET}"
    echo ""

    # ── Status bar ──
    local tmux_status agent_teams_status
    if [ "$has_tmux" = true ]; then
        tmux_status="${GREEN}ready${RESET}"
    else
        tmux_status="${YELLOW}not installed${RESET}"
    fi
    if [ -f "$HOME/.claude/settings.json" ] && grep -q 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$HOME/.claude/settings.json" 2>/dev/null; then
        agent_teams_status="${GREEN}enabled${RESET}"
    else
        agent_teams_status="${YELLOW}not configured${RESET}"
    fi
    echo -e "  tmux: $tmux_status    Agent Teams: $agent_teams_status    sessions: ${BOLD}$session_count${RESET}"
    echo ""

    # ── Sessions ──
    if [ "$session_count" -eq 0 ]; then
        echo -e "${DIM}  ─────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${BOLD}No sessions yet.${RESET} Set up your first project:"
        echo ""
        echo -e "    ${CYAN}deck setup ~/myproject${RESET}"
        echo ""
        echo -e "  This will detect your stack, pick relevant resources,"
        echo -e "  and configure a persistent Claude Code session."
        echo ""
        echo -e "${DIM}  ─────────────────────────────────────────${RESET}"
    else
        cmd_list
    fi

    # ── Quick reference ──
    echo -e "  ${BOLD}Commands${RESET}"
    echo ""
    echo -e "    ${CYAN}setup${RESET} <dir>         Set up a new project session"
    echo -e "    ${CYAN}open${RESET}  <name>        Open a session (launches Claude Code)"
    echo -e "    ${CYAN}spawn${RESET} <name>        Add another agent to a session"
    echo -e "    ${CYAN}kill${RESET}  <name>        Stop a session"
    echo -e "    ${CYAN}list${RESET}                List all sessions"
    echo -e "    ${CYAN}config${RESET}              Show global configuration"
    echo -e "    ${CYAN}quit${RESET}                Exit"
    echo ""

    if [ "$has_tmux" != true ]; then
        echo -e "  ${YELLOW}Note:${RESET} Install tmux to open/spawn sessions."
        echo -e "  ${DIM}  sudo apt install tmux  ${RESET}or${DIM}  brew install tmux${RESET}"
        echo ""
    fi

    # ── Interactive loop ──
    while true; do
        echo -ne "  ${BOLD}deck >${RESET} "
        read -r input || break

        # Trim whitespace
        input=$(echo "$input" | xargs 2>/dev/null || echo "$input")
        [ -z "$input" ] && continue

        case "$input" in
            q|quit|exit) break ;;
            d|dash|dashboard)
                cmd_dashboard
                break
                ;;
            s\ *|setup\ *)
                local dir="${input#* }"
                cmd_setup "$dir"
                cmd_list
                ;;
            o\ *|open\ *)
                if [ "$has_tmux" != true ]; then
                    err "tmux is required for sessions. Install it first."
                    continue
                fi
                local target="${input#* }"
                cmd_open "$target"
                # After detaching from tmux, redraw
                echo ""
                echo -e "${BOLD}${BLUE}  Agent Deck${RESET}"
                cmd_list
                ;;
            p\ *|spawn\ *)
                if [ "$has_tmux" != true ]; then
                    err "tmux is required for sessions. Install it first."
                    continue
                fi
                local target="${input#* }"
                cmd_spawn "$target"
                echo ""
                echo -e "${BOLD}${BLUE}  Agent Deck${RESET}"
                cmd_list
                ;;
            k\ *|kill\ *)
                if [ "$has_tmux" != true ]; then
                    err "tmux is required for sessions. Install it first."
                    continue
                fi
                local target="${input#* }"
                cmd_kill "$target"
                echo ""
                ;;
            l|list|ls)
                cmd_list
                ;;
            c|config)
                cmd_config
                ;;
            c\ *|config\ *)
                local args="${input#* }"
                cmd_config $args
                ;;
            h|help)
                usage
                ;;
            *)
                echo -e "  ${DIM}Unknown: $input${RESET}"
                echo -e "  ${DIM}Commands: setup  open  spawn  kill  list  config  help  quit${RESET}"
                ;;
        esac
    done
}

# ── dashboard: master tmux session with all projects as windows ──────
cmd_dashboard() {
    require_tmux
    require_claude
    local master_session="agent-deck-dashboard"

    # If dashboard already exists, attach to it
    if tmux_session_exists "$master_session"; then
        echo -e "${GREEN}Attaching to dashboard...${RESET}"
        tmux attach -t "$master_session"
        return
    fi

    # Create master dashboard session
    echo -e "${GREEN}Launching Agent Deck Dashboard...${RESET}"
    echo ""

    # Find all session configs
    local sessions=()
    for file in "$SESSIONS_DIR"/*.conf; do
        [ -f "$file" ] || continue
        sessions+=("$(basename "$file" .conf)")
    done

    if [ ${#sessions[@]} -eq 0 ]; then
        err "No sessions configured. Run: agent-deck setup <project-dir>"
        return 1
    fi

    # Create dashboard session with first project
    local first_session="${sessions[0]}"
    source "$SESSIONS_DIR/$first_session.conf"
    local first_project="$PROJECT_DIR"

    echo -e "  ${CYAN}${first_session}${RESET} ${DIM}${first_project}${RESET}"
    tmux new-session -d -s "$master_session" -n "$first_session" -c "$first_project"
    tmux send-keys -t "$master_session:$first_session" 'claude' Enter

    # Add windows for remaining projects
    for ((i=1; i<${#sessions[@]}; i++)); do
        local sess="${sessions[$i]}"
        source "$SESSIONS_DIR/$sess.conf"
        echo -e "  ${CYAN}${sess}${RESET} ${DIM}${PROJECT_DIR}${RESET}"
        tmux new-window -t "$master_session" -n "$sess" -c "$PROJECT_DIR"
        tmux send-keys -t "$master_session:$sess" 'claude' Enter
    done

    # Add a status window
    tmux new-window -t "$master_session" -n "dashboard"
    tmux send-keys -t "$master_session:dashboard" 'clear && echo "Agent Deck Dashboard" && echo "" && agent-deck list && echo "" && echo "Switch windows: Ctrl+B then number (0-9)" && echo "Create new window: Ctrl+B then C" && echo "Kill window: Ctrl+B then X" && echo "Detach: Ctrl+B then D"' Enter

    # Select first project window
    tmux select-window -t "$master_session:$first_session"

    echo ""
    echo -e "${BOLD}Dashboard ready!${RESET}"
    echo -e "${DIM}Switch windows: Ctrl+B then 0-9${RESET}"
    echo ""

    tmux attach -t "$master_session"
}

# ── help ──────────────────────────────────────────────────────────────
usage() {
    echo ""
    echo "agent-deck - Home base for Claude Code agent teams"
    echo ""
    echo "Each session is scoped to a project folder. It launches Claude Code"
    echo "as a team lead (orchestrator) that can spawn Agent Teams teammates."
    echo ""
    echo "Usage:"
    echo "  deck                              Homepage (interactive dashboard)"
    echo "  deck setup [dir]                  Create + configure a session"
    echo "  deck open <session>               Open a session"
    echo "  deck spawn <session>              Add another agent window"
    echo "  deck list                         List all sessions"
    echo "  deck kill <session>               Kill a session"
    echo "  deck config [show|set|edit|init]  Manage global config"
    echo "  deck help                         This help"
    echo ""
    echo "Inside a tmux session:"
    echo "  deck                              Detach (go back to dashboard)"
    echo "  deck list                         List sessions without leaving"
    echo ""
    echo "Paths:"
    echo "  Config:    $GLOBAL_CONFIG"
    echo "  Sessions:  $SESSIONS_DIR"
    echo "  Cache:     $ACC_CACHE"
    echo "  Claude:    ~/.claude/settings.json"
    echo ""
}

# ── Helpers ───────────────────────────────────────────────────────────
require_tmux() {
    if ! command -v tmux &>/dev/null; then
        err "tmux is required for session management."
        echo -e "Install: ${CYAN}sudo apt install tmux${RESET} or ${CYAN}brew install tmux${RESET}"
        exit 1
    fi
}

require_git() {
    if ! command -v git &>/dev/null; then
        err "git is required to fetch resources."
        echo -e "Install: ${CYAN}sudo apt install git${RESET} or ${CYAN}brew install git${RESET}"
        exit 1
    fi
}

require_claude() {
    if ! command -v claude &>/dev/null; then
        err "Claude Code is required to run sessions."
        echo -e "Install: ${CYAN}https://claude.ai/download${RESET}"
        exit 1
    fi
}

# ── Main ──────────────────────────────────────────────────────────────
main() {
    init_deck

    local cmd="${1:-}"

    case "$cmd" in
        # Works without tmux
        setup)          shift; cmd_setup "$@" ;;
        list|ls)        cmd_list ;;
        config)         shift; cmd_config "$@" ;;
        help|-h|--help) usage ;;

        # Requires tmux
        dashboard|d|dash)
            cmd_dashboard
            ;;
        open|o)
            [ -z "${2:-}" ] && err "Usage: agent-deck open <session>" && exit 1
            cmd_open "$2"
            ;;
        spawn|p)
            [ -z "${2:-}" ] && err "Usage: agent-deck spawn <session>" && exit 1
            cmd_spawn "$2"
            ;;
        kill|rm)
            [ -z "${2:-}" ] && err "Usage: agent-deck kill <session>" && exit 1
            cmd_kill "$2"
            ;;
        *)
            cmd_home
            ;;
    esac
}

main "$@"
