#!/usr/bin/env bash
#
# add_useful_tmux_commands_to_zshrc.sh
#
# Adds useful tmux session management commands and agent aliases to ~/.zshrc
# Safe to run multiple times - checks for existing definitions before adding
#
# Compatible with both Linux and macOS
#

set -euo pipefail

ZSHRC="${HOME}/.zshrc"
MARKER_START="# === NAMED-TMUX-COMMANDS-START ==="
MARKER_END="# === NAMED-TMUX-COMMANDS-END ==="

# Check if the command block is already installed
is_installed() {
  grep -q "$MARKER_START" "$ZSHRC" 2>/dev/null && \
  grep -q "$MARKER_END" "$ZSHRC" 2>/dev/null
}

# Remove existing installation (for upgrades)
remove_existing() {
  if is_installed; then
    # Use sed to remove everything between markers (inclusive)
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "/$MARKER_START/,/$MARKER_END/d" "$ZSHRC"
    else
      sed -i "/$MARKER_START/,/$MARKER_END/d" "$ZSHRC"
    fi
    echo "Removed existing installation"
  fi
}

# Backup zshrc before modifying
backup_zshrc() {
  local backup
  backup="${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$ZSHRC" "$backup"
  echo "Created backup: $backup"
}

OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"

# Install Powerlevel10k theme for Oh My Zsh
install_powerlevel10k_theme() {
  local zshrc="$ZSHRC"
  local omz_dir="$OH_MY_ZSH_DIR"

  if [[ ! -d "$omz_dir" ]]; then
    echo "Oh My Zsh directory not found at $omz_dir; cannot install Powerlevel10k." >&2
    return 1
  fi

  if ! command -v git &>/dev/null; then
    echo "git is required to install Powerlevel10k. Please install git and rerun." >&2
    return 1
  fi

  local zsh_custom="${ZSH_CUSTOM:-$omz_dir/custom}"
  local p10k_dir="$zsh_custom/themes/powerlevel10k"

  mkdir -p "$zsh_custom/themes"

  if [[ ! -d "$p10k_dir" ]]; then
    echo "Cloning Powerlevel10k theme into $p10k_dir..."
    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"; then
      echo "Failed to clone Powerlevel10k." >&2
      return 1
    fi
  else
    echo "Powerlevel10k already present at $p10k_dir"
  fi

  # Set theme to powerlevel10k/powerlevel10k
  if grep -q '^ZSH_THEME=' "$zshrc" 2>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
    else
      sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
    fi
  else
    printf '\nZSH_THEME="powerlevel10k/powerlevel10k"\n' >> "$zshrc"
  fi

  # Disable the Powerlevel10k wizard so it doesn't prompt on first run
  if ! grep -q 'POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD' "$zshrc" 2>/dev/null; then
    printf '\nexport POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD=true\n' >> "$zshrc"
  fi

  # Optional: source ~/.p10k.zsh if present (for future custom configs)
  if ! grep -q '\[\[ ! -f ~/.p10k.zsh \]\]' "$zshrc" 2>/dev/null; then
    printf '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh\n' >> "$zshrc"
  fi

  echo "Configured Powerlevel10k as the default theme (wizard disabled)."
  return 0
}

# Install Oh My Zsh (and automatically Powerlevel10k)
install_oh_my_zsh() {
  # Already installed?
  if [[ -d "$OH_MY_ZSH_DIR" ]]; then
    echo "Oh My Zsh already appears installed at $OH_MY_ZSH_DIR"
    return 0
  fi

  if ! command -v zsh &>/dev/null; then
    echo "zsh is not installed; please install zsh first (e.g. via brew/apt) and rerun." >&2
    return 1
  fi

  if [[ ! -t 0 ]]; then
    echo "Cannot interactively install Oh My Zsh (non-interactive shell)." >&2
    return 1
  fi

  echo ""
  echo "~/.zshrc not found."
  printf "Install Oh My Zsh (with Powerlevel10k theme) now? [y/N]: "
  local answer
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      echo "Installing Oh My Zsh..."

      # Do not automatically start zsh or change the login shell
      export RUNZSH=no
      export CHSH=no

      if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh; then
        echo "Oh My Zsh installation failed." >&2
        return 1
      fi

      echo "Oh My Zsh installed."

      # Ensure we have a zshrc after installation
      if [[ ! -f "$ZSHRC" ]]; then
        echo "# Created by add_useful_tmux_commands_to_zshrc.sh after Oh My Zsh install" > "$ZSHRC"
      fi

      # Automatically install Powerlevel10k (user already opted in by choosing OMZ)
      echo "Installing Powerlevel10k theme..."
      if ! install_powerlevel10k_theme; then
        echo "Powerlevel10k installation/configuration failed; you can install it manually later." >&2
      fi

      return 0
      ;;
    *)
      echo "Skipping Oh My Zsh installation."
      return 1
      ;;
  esac
}

# Main
main() {
  local force_reinstall=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force)
        force_reinstall=true
        shift
        ;;
      -u|--uninstall)
        if [[ -f "$ZSHRC" ]] && is_installed; then
          backup_zshrc
          remove_existing
          echo "Uninstalled tmux commands from ~/.zshrc"
          echo "Run 'source ~/.zshrc' to apply changes."
        else
          echo "Nothing to uninstall."
        fi
        return 0
        ;;
      -h|--help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -f, --force      Force reinstall (remove existing and add fresh)"
        echo "  -u, --uninstall  Remove the commands from ~/.zshrc"
        echo "  -h, --help       Show this help message"
        return 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Use --help for usage information." >&2
        return 1
        ;;
    esac
  done

  local created_zshrc=false

  if [[ ! -f "$ZSHRC" ]]; then
    # Offer Oh My Zsh + Powerlevel10k if interactive
    if ! install_oh_my_zsh; then
      # Either user declined or install failed; ensure we still have a zshrc
      if [[ ! -f "$ZSHRC" ]]; then
        echo "Creating minimal ~/.zshrc"
        echo "# ~/.zshrc created by add_useful_tmux_commands_to_zshrc.sh" > "$ZSHRC"
        created_zshrc=true
      fi
    fi
  fi

  if is_installed; then
    if [[ "$force_reinstall" == true ]]; then
      echo "Force reinstall requested..."
      backup_zshrc
      remove_existing
    else
      echo "Tmux commands are already installed in ~/.zshrc"
      echo "Use --force to reinstall or --uninstall to remove."
      return 0
    fi
  elif [[ "$created_zshrc" == false ]]; then
    # Only backup if we didn't just create an empty file
    backup_zshrc
  fi

  echo "Adding tmux commands to ~/.zshrc..."

  cat >> "$ZSHRC" << 'TMUX_COMMANDS'

# === NAMED-TMUX-COMMANDS-START ===
# ============================================================================
# Named Tmux Session Management Commands
# Added by add_useful_tmux_commands_to_zshrc.sh
# Type 'ntm' for a help table with examples
# ============================================================================

# Platform detection and base directory setup
if [[ "$(uname)" == "Darwin" ]]; then
  export PROJECTS_BASE="${PROJECTS_BASE:-$HOME/Developer}"
else
  export PROJECTS_BASE="${PROJECTS_BASE:-/data/projects}"
fi

# Ensure proper locale (prevents encoding issues on some systems)
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ============================================================================
# Agent Aliases
# ============================================================================

alias cc='NODE_OPTIONS="--max-old-space-size=32768" ENABLE_BACKGROUND_TASKS=1 claude --dangerously-skip-permissions'
alias cod='codex --dangerously-bypass-approvals-and-sandbox -m gpt-5.1-codex-max -c model_reasoning_effort="high" -c model_reasoning_summary_format=experimental --enable web_search_request'
alias gmi='gemini --yolo'

# ============================================================================
# Helper Functions
# ============================================================================

# Try to auto-install tmux using brew or a Linux package manager
_ntm_auto_install_tmux() {
  local os

  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
      echo "Running: brew install tmux"
      if brew install tmux; then
        if command -v tmux &>/dev/null; then
          return 0
        fi
      fi
      echo "brew install tmux failed." >&2
      return 1
    else
      echo "Homebrew not found; install it from https://brew.sh then run 'brew install tmux'." >&2
      return 1
    fi
  else
    # Generic Linux: detect a reasonable package manager
    if command -v apt-get &>/dev/null; then
      echo "Running: sudo apt-get update && sudo apt-get install -y tmux"
      if sudo apt-get update && sudo apt-get install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v apt &>/dev/null; then
      echo "Running: sudo apt update && sudo apt install -y tmux"
      if sudo apt update && sudo apt install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v dnf &>/dev/null; then
      pkg="dnf"
      echo "Running: sudo dnf install -y tmux"
      if sudo dnf install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v yum &>/dev/null; then
      pkg="yum"
      echo "Running: sudo yum install -y tmux"
      if sudo yum install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v pacman &>/dev/null; then
      pkg="pacman"
      echo "Running: sudo pacman -Sy --noconfirm tmux"
      if sudo pacman -Sy --noconfirm tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v zypper &>/dev/null; then
      pkg="zypper"
      echo "Running: sudo zypper install -y tmux"
      if sudo zypper install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v apk &>/dev/null; then
      pkg="apk"
      echo "Running: sudo apk add tmux"
      if sudo apk add tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    else
      echo "Could not detect a supported package manager (apt, dnf, pacman, zypper, apk, etc.)." >&2
      echo "Install tmux manually with your distro's package manager." >&2
      return 1
    fi

    echo "tmux installation command completed, but tmux is still not on PATH." >&2
    return 1
  fi
}

# Check if tmux is available, optionally offer to install it
_ntm_check_tmux() {
  if command -v tmux &>/dev/null; then
    return 0
  fi

  echo "error: tmux not found." >&2

  # Non-interactive shells: just bail out
  if [[ ! -t 0 ]]; then
    echo "       (non-interactive shell, not attempting auto-install)" >&2
    echo "       Install tmux manually (brew/apt/dnf/pacman/etc.) and retry." >&2
    return 1
  fi

  printf "Attempt to install tmux now? [y/N]: "
  local answer
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      if _ntm_auto_install_tmux; then
        echo "tmux installed successfully."
        return 0
      else
        echo "error: automatic tmux installation failed." >&2
        return 1
      fi
      ;;
    *)
      echo "Please install tmux manually and retry." >&2
      return 1
      ;;
  esac
}

# Validate session name (no special characters that break tmux)
_ntm_validate_session_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "error: session name cannot be empty" >&2
    return 1
  fi
  if [[ "$name" =~ [.:] ]]; then
    echo "error: session name cannot contain ':' or '.'" >&2
    return 1
  fi
  return 0
}

# Get the first window index (respects base-index setting)
_ntm_first_window() {
  local session="$1"
  local first
  first=$(tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null | head -1) || return 1
  [[ -n "$first" ]] || return 1
  echo "$first"
}

# ============================================================================
# Core Commands
# ============================================================================

# Check agent CLI dependencies
check-agent-deps() {
  local missing=()
  local found=()

  command -v claude &>/dev/null && found+=(claude) || missing+=(claude)
  command -v codex &>/dev/null && found+=(codex) || missing+=(codex)
  command -v gemini &>/dev/null && found+=(gemini) || missing+=(gemini)

  if [[ ${#found[@]} -gt 0 ]]; then
    echo "✓ Available: ${found[*]}"
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "✗ Missing: ${missing[*]}"
    echo ""
    echo "Install with:"
    [[ " ${missing[*]} " =~ " claude " ]] && echo "  npm install -g @anthropic-ai/claude-code"
    [[ " ${missing[*]} " =~ " codex " ]] && echo "  npm install -g @openai/codex"
    [[ " ${missing[*]} " =~ " gemini " ]] && echo "  npm install -g @google/gemini-cli"
    return 1
  fi

  return 0
}

# Create a named tmux session with multiple panes
create-named-tmux() {
  _ntm_check_tmux || return 1

  local session="$1"
  local panes="${2:-10}"
  local base="${PROJECTS_BASE:-$HOME/projects}"
  local dir

  if [[ -z "$session" ]]; then
    echo "usage: create-named-tmux <session-name> [panes]" >&2
    echo "       cnt <session-name> [panes]" >&2
    return 1
  fi

  _ntm_validate_session_name "$session" || return 1

  # Zsh-native integer check
  if ! [[ "$panes" = <-> ]] || [[ "$panes" -lt 1 ]]; then
    echo "error: panes must be a positive integer, got '$panes'" >&2
    return 1
  fi

  dir="$base/$session"

  if [[ ! -d "$dir" ]]; then
    echo "Directory not found: $dir"
    printf "Create it? [y/N]: "
    local answer
    read -r answer
    case "$answer" in
      y|Y|yes|YES)
        mkdir -p "$dir"
        echo "Created $dir"
        ;;
      *)
        echo "Aborted."
        return 1
        ;;
    esac
  fi

  # Create session + panes if it doesn't exist yet
  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Creating session '$session' with $panes pane(s)..."
    tmux new-session -d -s "$session" -c "$dir"

    local first_win
    if ! first_win=$(_ntm_first_window "$session"); then
      echo "error: could not determine first window for session '$session'" >&2
      return 1
    fi

    if [[ "$panes" -gt 1 ]]; then
      for ((i=2; i<=panes; i++)); do
        tmux split-window -t "$session:$first_win" -c "$dir"
        tmux select-layout -t "$session:$first_win" tiled
      done
    fi
    echo "Created session '$session' with $panes pane(s)"
  else
    echo "Session '$session' already exists"
  fi

  # Attach or switch depending on whether we're already inside tmux
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach -t "$session"
  fi
}

# Create session and spawn AI agents in panes
spawn-agents-in-named-tmux() {
  _ntm_check_tmux || return 1

  local session="$1"
  local cc_count="${2:-0}"
  local cod_count="${3:-0}"
  local gmi_count="${4:-0}"
  local base="${PROJECTS_BASE:-$HOME/projects}"
  local dir="$base/$session"

  if [[ -z "$session" ]]; then
    echo "usage: spawn-agents-in-named-tmux <session> <cc-count> <cod-count> [gmi-count]" >&2
    echo "       sat <session> <cc-count> <cod-count> [gmi-count]" >&2
    return 1
  fi

  _ntm_validate_session_name "$session" || return 1

  for n in "$cc_count" "$cod_count" "$gmi_count"; do
    if ! [[ "$n" = <-> ]]; then
      echo "error: counts must be non-negative integers (got '$n')" >&2
      return 1
    fi
  done

  if [[ ! -d "$dir" ]]; then
    echo "Directory not found: $dir"
    printf "Create it? [y/N]: "
    local answer
    read -r answer
    case "$answer" in
      y|Y|yes|YES)
        mkdir -p "$dir"
        echo "Created $dir"
        ;;
      *)
        echo "Aborted."
        return 1
        ;;
    esac
  fi

  local total_agents=$((cc_count + cod_count + gmi_count))
  if [[ "$total_agents" -le 0 ]]; then
    echo "error: nothing to spawn (all counts are zero)" >&2
    return 1
  fi

  local required_panes=$((1 + total_agents))  # 1 user pane + all agents

  # Create session if it doesn't exist
  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Creating session '$session' in $dir..."
    tmux new-session -d -s "$session" -c "$dir"
  fi

  local first_win
  if ! first_win=$(_ntm_first_window "$session"); then
    echo "error: could not determine first window for session '$session'" >&2
    return 1
  fi
  local win_target="$session:$first_win"

  local existing_panes
  existing_panes=$(tmux list-panes -t "$win_target" | wc -l | tr -d ' ')

  # Add more panes if needed
  if [[ "$existing_panes" -lt "$required_panes" ]]; then
    local to_add=$((required_panes - existing_panes))
    echo "Creating $to_add pane(s) ($existing_panes -> $required_panes)..."
    for ((i=1; i<=to_add; i++)); do
      tmux split-window -t "$win_target" -c "$dir"
      tmux select-layout -t "$win_target" tiled
    done
  fi

  # Get the pane indices as an array
  local -a pane_ids
  pane_ids=(${(f)"$(tmux list-panes -t "$win_target" -F '#{pane_index}')"})

  # pane_ids[1] is the first pane (user pane), start assigning from pane_ids[2]
  local arr_idx=2
  local project="$session"
  local pane_id

  echo "Launching agents: ${cc_count}x cc, ${cod_count}x cod, ${gmi_count}x gmi..."

  for ((i=1; i<=cc_count; i++)); do
    pane_id=${pane_ids[$arr_idx]}
    tmux select-pane -t "$win_target.$pane_id" -T "${project}__cc_${i}"
    tmux send-keys -t "$win_target.$pane_id" "cd \"$dir\" && cc" C-m
    ((arr_idx++))
  done

  for ((i=1; i<=cod_count; i++)); do
    pane_id=${pane_ids[$arr_idx]}
    tmux select-pane -t "$win_target.$pane_id" -T "${project}__cod_${i}"
    tmux send-keys -t "$win_target.$pane_id" "cd \"$dir\" && cod" C-m
    ((arr_idx++))
  done

  for ((i=1; i<=gmi_count; i++)); do
    pane_id=${pane_ids[$arr_idx]}
    tmux select-pane -t "$win_target.$pane_id" -T "${project}__gmi_${i}"
    tmux send-keys -t "$win_target.$pane_id" "cd \"$dir\" && gmi" C-m
    ((arr_idx++))
  done

  echo "✓ Launched $total_agents agent(s)"

  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach -t "$session"
  fi
}

# Add more agents to an existing session
add-agents-to-named-tmux() {
  _ntm_check_tmux || return 1

  local session="$1"
  local cc_count="${2:-0}"
  local cod_count="${3:-0}"
  local gmi_count="${4:-0}"
  local base="${PROJECTS_BASE:-$HOME/projects}"
  local dir="$base/$session"

  if [[ -z "$session" ]]; then
    echo "usage: add-agents-to-named-tmux <session> <cc-count> <cod-count> [gmi-count]" >&2
    echo "       ant <session> <cc-count> <cod-count> [gmi-count]" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "error: session '$session' does not exist" >&2
    echo "Use spawn-agents-in-named-tmux (sat) to create a new session with agents" >&2
    return 1
  fi

  for n in "$cc_count" "$cod_count" "$gmi_count"; do
    if ! [[ "$n" = <-> ]]; then
      echo "error: counts must be non-negative integers (got '$n')" >&2
      return 1
    fi
  done

  local total_agents=$((cc_count + cod_count + gmi_count))
  if [[ "$total_agents" -le 0 ]]; then
    echo "error: nothing to add (all counts are zero)" >&2
    return 1
  fi

  local first_win
  if ! first_win=$(_ntm_first_window "$session"); then
    echo "error: could not determine first window for session '$session'" >&2
    return 1
  fi
  local win_target="$session:$first_win"

  echo "Adding $total_agents agent(s) to session '$session'..."

  # Create new panes and launch agents
  local pane_id

  for ((i=1; i<=cc_count; i++)); do
    tmux split-window -t "$win_target" -c "$dir"
    tmux select-layout -t "$win_target" tiled
    pane_id=$(tmux list-panes -t "$win_target" -F '#{pane_index}' | tail -1)
    tmux select-pane -t "$win_target.$pane_id" -T "${session}__cc_added_${i}"
    tmux send-keys -t "$win_target.$pane_id" "cd \"$dir\" && cc" C-m
  done

  for ((i=1; i<=cod_count; i++)); do
    tmux split-window -t "$win_target" -c "$dir"
    tmux select-layout -t "$win_target" tiled
    pane_id=$(tmux list-panes -t "$win_target" -F '#{pane_index}' | tail -1)
    tmux select-pane -t "$win_target.$pane_id" -T "${session}__cod_added_${i}"
    tmux send-keys -t "$win_target.$pane_id" "cd \"$dir\" && cod" C-m
  done

  for ((i=1; i<=gmi_count; i++)); do
    tmux split-window -t "$win_target" -c "$dir"
    tmux select-layout -t "$win_target" tiled
    pane_id=$(tmux list-panes -t "$win_target" -F '#{pane_index}' | tail -1)
    tmux select-pane -t "$win_target.$pane_id" -T "${session}__gmi_added_${i}"
    tmux send-keys -t "$win_target.$pane_id" "cd \"$dir\" && gmi" C-m
  done

  echo "✓ Added ${cc_count}x cc, ${cod_count}x cod, ${gmi_count}x gmi"
}

# Reconnect to an existing named tmux session
reconnect-to-named-tmux() {
  _ntm_check_tmux || return 1

  local session="$1"

  if [[ -z "$session" ]]; then
    echo "usage: reconnect-to-named-tmux <session-name>" >&2
    echo "       rnt <session-name>" >&2
    echo ""
    echo "Available sessions:"
    list-named-tmux
    return 1
  fi

  if tmux has-session -t "$session" 2>/dev/null; then
    if [[ -n "${TMUX:-}" ]]; then
      tmux switch-client -t "$session"
    else
      tmux attach -t "$session"
    fi
    return 0
  fi

  echo "Session '$session' does not exist."
  echo ""
  echo "Available sessions:"
  list-named-tmux
  echo ""
  printf "Create '%s' with default settings? [y/N]: " "$session"

  local answer
  read -r answer

  case "$answer" in
    y|Y|yes|YES)
      create-named-tmux "$session"
      ;;
    *)
      echo "Aborted."
      return 1
      ;;
  esac
}

# List all tmux sessions
list-named-tmux() {
  _ntm_check_tmux || return 1

  if ! tmux list-sessions 2>/dev/null; then
    echo "No tmux sessions running"
    return 0
  fi
}

# Show detailed status of a session
status-named-tmux() {
  _ntm_check_tmux || return 1

  local session="$1"

  if [[ -z "$session" ]]; then
    echo "usage: status-named-tmux <session-name>" >&2
    echo "       snt <session-name>" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  local base="${PROJECTS_BASE:-$HOME/projects}"

  echo ""
  echo "Session: $session"
  echo "Directory: $base/$session"
  echo ""
  echo "Panes:"
  echo "─────────────────────────────────────────────────────"

  # Get pane info with titles and current commands
  tmux list-panes -s -t "$session" -F '  #{pane_index}: #{pane_title} │ #{pane_current_command} │ #{pane_width}x#{pane_height}' 2>/dev/null

  echo "─────────────────────────────────────────────────────"

  # Count agents by type
  local cc_count cod_count gmi_count
  cc_count=$(tmux list-panes -s -t "$session" -F '#{pane_title}' | grep -c '__cc' || echo 0)
  cod_count=$(tmux list-panes -s -t "$session" -F '#{pane_title}' | grep -c '__cod' || echo 0)
  gmi_count=$(tmux list-panes -s -t "$session" -F '#{pane_title}' | grep -c '__gmi' || echo 0)

  echo "Agents: ${cc_count}x cc, ${cod_count}x cod, ${gmi_count}x gmi"
  echo ""
}

# View all panes in a tiled grid layout
view-named-tmux-panes() {
  _ntm_check_tmux || return 1

  local session="$1"

  if [[ -z "$session" ]]; then
    echo "usage: view-named-tmux-panes <session-name>" >&2
    echo "       vnt <session-name>" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  # Get all windows in the session
  local -a windows
  windows=(${(f)"$(tmux list-windows -t "$session" -F '#{window_index}')"})

  # For each window: unzoom if zoomed, apply tiled layout
  for win_idx in "${windows[@]}"; do
    local win_target="$session:$win_idx"

    # Unzoom if currently zoomed
    local is_zoomed
    is_zoomed=$(tmux display-message -t "$win_target" -p '#{window_zoomed_flag}' 2>/dev/null)
    if [[ "$is_zoomed" == "1" ]]; then
      tmux resize-pane -t "$win_target" -Z 2>/dev/null
    fi

    # Apply tiled layout for optimal grid
    tmux select-layout -t "$win_target" tiled 2>/dev/null
  done

  # Attach or switch to session
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach -t "$session"
  fi
}

# Send a command to all panes in a session
send-command-to-named-tmux() {
  _ntm_check_tmux || return 1

  local skip_first=false
  local agent_filter=""

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-first|-s)
        skip_first=true
        shift
        ;;
      --cc)
        agent_filter="__cc"
        shift
        ;;
      --cod)
        agent_filter="__cod"
        shift
        ;;
      --gmi)
        agent_filter="__gmi"
        shift
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  local session="$1"
  shift 2>/dev/null || true
  local cmd="$*"

  if [[ -z "$session" ]]; then
    echo "usage: send-command-to-named-tmux [-s|--skip-first] [--cc|--cod|--gmi] <session> <command...>" >&2
    echo "       sct [-s] [--cc|--cod|--gmi] <session> <command...>" >&2
    echo ""
    echo "Options:"
    echo "  -s, --skip-first  Skip the first (user) pane"
    echo "  --cc              Send only to Claude (cc) panes"
    echo "  --cod             Send only to Codex (cod) panes"
    echo "  --gmi             Send only to Gemini (gmi) panes"
    return 1
  fi

  if [[ -z "$cmd" ]]; then
    echo "error: no command specified" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  # Get pane info (ID and title)
  local -a pane_info
  pane_info=(${(f)"$(tmux list-panes -s -t "$session" -F '#{pane_id}:#{pane_title}')"})

  if [[ ${#pane_info[@]} -eq 0 ]]; then
    echo "No panes found in session '$session'" >&2
    return 1
  fi

  local count=0
  local start_idx=1
  if $skip_first; then
    start_idx=2
  fi

  # Send command to matching panes
  for ((i=start_idx; i<=${#pane_info[@]}; i++)); do
    local entry="${pane_info[$i]}"
    local pane_id="${entry%%:*}"
    local pane_title="${entry#*:}"

    # Apply agent filter if specified
    if [[ -n "$agent_filter" ]] && [[ ! "$pane_title" =~ "$agent_filter" ]]; then
      continue
    fi

    tmux send-keys -t "$pane_id" "$cmd" C-m
    ((count++))
  done

  if [[ "$count" -eq 0 ]]; then
    echo "No matching panes found"
  else
    echo "Sent command to $count pane(s) in session '$session'"
  fi
}

# Send interrupt (Ctrl+C) to agent panes
interrupt-agents-in-named-tmux() {
  _ntm_check_tmux || return 1

  local session="$1"

  if [[ -z "$session" ]]; then
    echo "usage: interrupt-agents-in-named-tmux <session-name>" >&2
    echo "       int <session-name>" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  # Get pane info
  local -a pane_info
  pane_info=(${(f)"$(tmux list-panes -s -t "$session" -F '#{pane_id}:#{pane_title}')"})

  local count=0

  for entry in "${pane_info[@]}"; do
    local pane_id="${entry%%:*}"
    local pane_title="${entry#*:}"

    # Only interrupt agent panes (those with __cc, __cod, or __gmi in title)
    if [[ "$pane_title" =~ __(cc|cod|gmi) ]]; then
      tmux send-keys -t "$pane_id" C-c
      ((count++))
    fi
  done

  echo "Sent Ctrl+C to $count agent pane(s)"
}

# Kill an entire named tmux session
kill-named-tmux() {
  _ntm_check_tmux || return 1

  local force=false session=""

  # Parse arguments - support -f in any position
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force)
        force=true
        shift
        ;;
      *)
        session="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$session" ]]; then
    echo "usage: kill-named-tmux [-f|--force] <session-name>" >&2
    echo "       knt [-f] <session-name>" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  if [[ "$force" != true ]]; then
    local pane_count
    pane_count=$(tmux list-panes -s -t "$session" | wc -l | tr -d ' ')
    printf "Kill session '%s' with %s pane(s)? [y/N]: " "$session" "$pane_count"
    local answer
    read -r answer
    case "$answer" in
      y|Y|yes|YES)
        ;;
      *)
        echo "Aborted."
        return 1
        ;;
    esac
  fi

  tmux kill-session -t "$session"
  echo "Killed session '$session'"
}

# Copy pane output to clipboard
copy-pane-output() {
  _ntm_check_tmux || return 1

  local session="$1"
  local pane="${2:-0}"
  local lines="${3:-500}"

  if [[ -z "$session" ]]; then
    echo "usage: copy-pane-output <session> [pane-index] [lines]" >&2
    echo "       cpo <session> [pane-index] [lines]" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  local first_win
  if ! first_win=$(_ntm_first_window "$session"); then
    echo "error: could not determine first window for session '$session'" >&2
    return 1
  fi
  local target="$session:$first_win.$pane"

  # Capture pane content
  local content
  content=$(tmux capture-pane -t "$target" -p -S "-$lines" 2>/dev/null)

  if [[ -z "$content" ]]; then
    echo "No content captured from pane $pane" >&2
    return 1
  fi

  # Copy to clipboard based on platform
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "$content" | pbcopy
  elif command -v xclip &>/dev/null; then
    echo "$content" | xclip -selection clipboard
  elif command -v xsel &>/dev/null; then
    echo "$content" | xsel --clipboard --input
  elif command -v wl-copy &>/dev/null; then
    echo "$content" | wl-copy
  else
    echo "No clipboard tool found. Install xclip, xsel, or wl-copy." >&2
    echo "Content:"
    echo "$content"
    return 1
  fi

  echo "Copied $lines lines from pane $pane to clipboard"
}

# Save all pane outputs to files
save-session-outputs() {
  _ntm_check_tmux || return 1

  local session="$1"
  local output_dir="${2:-$HOME/tmux-logs}"

  if [[ -z "$session" ]]; then
    echo "usage: save-session-outputs <session> [output-dir]" >&2
    echo "       sso <session> [output-dir]" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  # Create output directory with timestamp
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local save_dir="$output_dir/${session}_${timestamp}"
  mkdir -p "$save_dir"

  # Get all panes
  local -a pane_info
  pane_info=(${(f)"$(tmux list-panes -s -t "$session" -F '#{pane_id}:#{pane_index}:#{pane_title}')"})

  local count=0

  for entry in "${pane_info[@]}"; do
    local pane_id="${entry%%:*}"
    local rest="${entry#*:}"
    local pane_idx="${rest%%:*}"
    local pane_title="${rest#*:}"

    # Sanitize title for filename
    local safe_title
    safe_title=$(echo "$pane_title" | tr -c '[:alnum:]_-' '_')

    local filename="$save_dir/pane_${pane_idx}_${safe_title}.log"

    tmux capture-pane -t "$pane_id" -p -S -10000 > "$filename" 2>/dev/null
    ((count++))
  done

  echo "Saved $count pane(s) to $save_dir"
}

# Zoom to a specific pane by index or agent type
zoom-pane-in-named-tmux() {
  _ntm_check_tmux || return 1

  local session="$1"
  local target="$2"

  if [[ -z "$session" || -z "$target" ]]; then
    echo "usage: zoom-pane-in-named-tmux <session> <pane-index|cc|cod|gmi>" >&2
    echo "       znt <session> <pane-index|cc|cod|gmi>" >&2
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "Session '$session' not found" >&2
    return 1
  fi

  local first_win
  if ! first_win=$(_ntm_first_window "$session"); then
    echo "error: could not determine first window for session '$session'" >&2
    return 1
  fi
  local win_target="$session:$first_win"

  local pane_idx

  # Check if target is a number (pane index) or agent type
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    pane_idx="$target"
  else
    # Find first pane matching the agent type
    local filter="__${target}"
    pane_idx=$(tmux list-panes -t "$win_target" -F '#{pane_index}:#{pane_title}' | \
               grep "$filter" | head -1 | cut -d: -f1)

    if [[ -z "$pane_idx" ]]; then
      echo "No pane found matching '$target'" >&2
      return 1
    fi
  fi

  # Select and zoom the pane
  tmux select-pane -t "$win_target.$pane_idx"
  tmux resize-pane -t "$win_target.$pane_idx" -Z

  # Attach or switch
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach -t "$session"
  fi
}

# Broadcast same prompt to all agents of a specific type
broadcast-prompt() {
  _ntm_check_tmux || return 1

  local session="$1"
  local agent_type="$2"
  shift 2 2>/dev/null || true
  local prompt="$*"

  if [[ -z "$session" || -z "$agent_type" || -z "$prompt" ]]; then
    echo "usage: broadcast-prompt <session> <cc|cod|gmi|all> <prompt...>" >&2
    echo "       bp <session> <cc|cod|gmi|all> <prompt...>" >&2
    return 1
  fi

  case "$agent_type" in
    cc)
      send-command-to-named-tmux --cc "$session" "$prompt"
      ;;
    cod)
      send-command-to-named-tmux --cod "$session" "$prompt"
      ;;
    gmi)
      send-command-to-named-tmux --gmi "$session" "$prompt"
      ;;
    all)
      send-command-to-named-tmux --skip-first "$session" "$prompt"
      ;;
    *)
      echo "error: agent type must be cc, cod, gmi, or all" >&2
      return 1
      ;;
  esac
}

# Quick project setup: create directory, git init, and spawn agents
quick-project-setup() {
  _ntm_check_tmux || return 1

  local project="$1"
  local cc_count="${2:-2}"
  local cod_count="${3:-2}"
  local gmi_count="${4:-0}"
  local base="${PROJECTS_BASE:-$HOME/projects}"

  if [[ -z "$project" ]]; then
    echo "usage: quick-project-setup <project-name> [cc] [cod] [gmi]" >&2
    echo "       qps <project-name> [cc] [cod] [gmi]" >&2
    echo ""
    echo "Creates project directory, initializes git, and spawns agents"
    return 1
  fi

  _ntm_validate_session_name "$project" || return 1

  local dir="$base/$project"

  if [[ ! -d "$dir" ]]; then
    echo "Creating project directory: $dir"
    mkdir -p "$dir"

    # Initialize git if not already a repo
    if [[ ! -d "$dir/.git" ]]; then
      echo "Initializing git repository..."
      git -C "$dir" init
      echo "# $project" > "$dir/README.md"
      git -C "$dir" add README.md
      git -C "$dir" commit -m "Initial commit"
    fi
  fi

  # Spawn agents
  spawn-agents-in-named-tmux "$project" "$cc_count" "$cod_count" "$gmi_count"
}

# ============================================================================
# Short Aliases
# ============================================================================

alias cnt='create-named-tmux'
alias sat='spawn-agents-in-named-tmux'
alias ant='add-agents-to-named-tmux'
alias rnt='reconnect-to-named-tmux'
alias lnt='list-named-tmux'
alias snt='status-named-tmux'
alias vnt='view-named-tmux-panes'
alias sct='send-command-to-named-tmux'
alias int='interrupt-agents-in-named-tmux'
alias knt='kill-named-tmux'
alias cpo='copy-pane-output'
alias sso='save-session-outputs'
alias znt='zoom-pane-in-named-tmux'
alias bp='broadcast-prompt'
alias qps='quick-project-setup'
alias cad='check-agent-deps'

# ============================================================================
# Help Command
# ============================================================================

# Show help table for named tmux commands (with colors)
ntm() {
  local C='\033[36m'    # Cyan - commands
  local G='\033[32m'    # Green - arguments
  local Y='\033[33m'    # Yellow - examples
  local M='\033[35m'    # Magenta - descriptions
  local B='\033[1m'     # Bold
  local D='\033[2m'     # Dim
  local R='\033[0m'     # Reset

  echo ""
  echo -e "${B}${C}  Named Tmux Session Management${R}"
  echo -e "${D}─────────────────────────────────────────────────────────────────────────────────${R}"

  echo ""
  echo -e "  ${B}SESSION CREATION${R}"
  echo ""
  echo -e "  ${B}${C}create-named-tmux${R} ${D}(cnt)${R} ${G}<session> [panes=10]${R}"
  echo -e "      ${Y}cnt slidechase 10${R}"
  echo -e "      ${M}Create empty session with N panes${R}"
  echo ""
  echo -e "  ${B}${C}spawn-agents-in-named-tmux${R} ${D}(sat)${R} ${G}<session> <cc> <cod> [gmi]${R}"
  echo -e "      ${Y}sat slidechase 6 6 2${R}"
  echo -e "      ${M}Create session and launch agents${R}"
  echo ""
  echo -e "  ${B}${C}quick-project-setup${R} ${D}(qps)${R} ${G}<project> [cc=2] [cod=2] [gmi=0]${R}"
  echo -e "      ${Y}qps myproject 3 3 1${R}"
  echo -e "      ${M}Create dir, git init, spawn agents - all in one${R}"
  echo ""

  echo -e "  ${B}AGENT MANAGEMENT${R}"
  echo ""
  echo -e "  ${B}${C}add-agents-to-named-tmux${R} ${D}(ant)${R} ${G}<session> <cc> <cod> [gmi]${R}"
  echo -e "      ${Y}ant slidechase 2 0 0${R}"
  echo -e "      ${M}Add more agents to existing session${R}"
  echo ""
  echo -e "  ${B}${C}broadcast-prompt${R} ${D}(bp)${R} ${G}<session> <cc|cod|gmi|all> <prompt>${R}"
  echo -e "      ${Y}bp slidechase cc \"fix the linting errors\"${R}"
  echo -e "      ${M}Send prompt to all agents of a type${R}"
  echo ""
  echo -e "  ${B}${C}interrupt-agents-in-named-tmux${R} ${D}(int)${R} ${G}<session>${R}"
  echo -e "      ${Y}int slidechase${R}"
  echo -e "      ${M}Send Ctrl+C to all agent panes${R}"
  echo ""

  echo -e "  ${B}SESSION NAVIGATION${R}"
  echo ""
  echo -e "  ${B}${C}reconnect-to-named-tmux${R} ${D}(rnt)${R} ${G}<session>${R}"
  echo -e "      ${Y}rnt slidechase${R}"
  echo -e "      ${M}Reattach (shows available sessions if missing)${R}"
  echo ""
  echo -e "  ${B}${C}list-named-tmux${R} ${D}(lnt)${R}"
  echo -e "      ${Y}lnt${R}"
  echo -e "      ${M}List all tmux sessions${R}"
  echo ""
  echo -e "  ${B}${C}status-named-tmux${R} ${D}(snt)${R} ${G}<session>${R}"
  echo -e "      ${Y}snt slidechase${R}"
  echo -e "      ${M}Show detailed pane status with agent counts${R}"
  echo ""
  echo -e "  ${B}${C}view-named-tmux-panes${R} ${D}(vnt)${R} ${G}<session>${R}"
  echo -e "      ${Y}vnt slidechase${R}"
  echo -e "      ${M}Unzoom, tile all panes, and attach${R}"
  echo ""
  echo -e "  ${B}${C}zoom-pane-in-named-tmux${R} ${D}(znt)${R} ${G}<session> <pane|cc|cod|gmi>${R}"
  echo -e "      ${Y}znt slidechase cc${R}"
  echo -e "      ${M}Zoom to a specific pane or first agent of type${R}"
  echo ""

  echo -e "  ${B}COMMANDS & OUTPUT${R}"
  echo ""
  echo -e "  ${B}${C}send-command-to-named-tmux${R} ${D}(sct)${R} ${G}[-s] [--cc|--cod|--gmi] <session> <cmd>${R}"
  echo -e "      ${Y}sct -s slidechase \"git status\"${R}"
  echo -e "      ${Y}sct --cc slidechase \"/exit\"${R}"
  echo -e "      ${M}Send command to panes (-s skips user pane, --agent filters)${R}"
  echo ""
  echo -e "  ${B}${C}copy-pane-output${R} ${D}(cpo)${R} ${G}<session> [pane=0] [lines=500]${R}"
  echo -e "      ${Y}cpo slidechase 2 1000${R}"
  echo -e "      ${M}Copy pane output to clipboard${R}"
  echo ""
  echo -e "  ${B}${C}save-session-outputs${R} ${D}(sso)${R} ${G}<session> [output-dir]${R}"
  echo -e "      ${Y}sso slidechase ~/logs${R}"
  echo -e "      ${M}Save all pane outputs to timestamped files${R}"
  echo ""

  echo -e "  ${B}CLEANUP${R}"
  echo ""
  echo -e "  ${B}${C}kill-named-tmux${R} ${D}(knt)${R} ${G}[-f] <session>${R}"
  echo -e "      ${Y}knt -f slidechase${R}"
  echo -e "      ${M}Kill session (-f skips confirmation)${R}"
  echo ""

  echo -e "  ${B}UTILITIES${R}"
  echo ""
  echo -e "  ${B}${C}check-agent-deps${R} ${D}(cad)${R}"
  echo -e "      ${Y}cad${R}"
  echo -e "      ${M}Check if claude, codex, gemini CLIs are installed${R}"
  echo ""

  echo -e "${D}─────────────────────────────────────────────────────────────────────────────────${R}"

  local os_info=""
  if [[ "$(uname)" == "Darwin" ]]; then
    os_info="macOS"
  else
    os_info="Linux"
  fi

  echo -e "  ${D}Platform:${R} $os_info  ${D}│${R}  ${D}Projects:${R} ${PROJECTS_BASE}"
  echo -e "  ${D}Aliases:${R}  cnt sat ant rnt lnt snt vnt znt sct int knt cpo sso bp qps cad"
  echo ""
}

# ============================================================================
# Tab Completion (basic)
# ============================================================================

# Complete session names for all commands
_ntm_complete_sessions() {
  # Short-circuit if tmux is not installed
  (( $+commands[tmux] )) || return 0
  local sessions
  sessions=(${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"})
  _describe 'session' sessions
}

# Register completions if compdef is available
if (( $+functions[compdef] )); then
  compdef _ntm_complete_sessions reconnect-to-named-tmux rnt
  compdef _ntm_complete_sessions view-named-tmux-panes vnt
  compdef _ntm_complete_sessions status-named-tmux snt
  compdef _ntm_complete_sessions send-command-to-named-tmux sct
  compdef _ntm_complete_sessions kill-named-tmux knt
  compdef _ntm_complete_sessions copy-pane-output cpo
  compdef _ntm_complete_sessions save-session-outputs sso
  compdef _ntm_complete_sessions zoom-pane-in-named-tmux znt
  compdef _ntm_complete_sessions add-agents-to-named-tmux ant
  compdef _ntm_complete_sessions interrupt-agents-in-named-tmux int
  compdef _ntm_complete_sessions broadcast-prompt bp
fi

# === NAMED-TMUX-COMMANDS-END ===
TMUX_COMMANDS

  echo ""
  echo "✓ Successfully added tmux commands to ~/.zshrc"
  echo ""
  echo "Run 'source ~/.zshrc' to load the new commands, then type 'ntm' for help."
}

main "$@"
