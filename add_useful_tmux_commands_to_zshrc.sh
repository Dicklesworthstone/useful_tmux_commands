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
TMUX_CONF="${HOME}/.tmux.conf"
MARKER_START="# === NAMED-TMUX-COMMANDS-START ==="
MARKER_END="# === NAMED-TMUX-COMMANDS-END ==="
TMUX_MARKER_START="# === NTM-TMUX-TWEAKS-START ==="
TMUX_MARKER_END="# === NTM-TMUX-TWEAKS-END ==="

# Base URL for fetching bundled files (edit this if you fork the repo)
NTM_REPO_BASE="${NTM_REPO_BASE:-https://raw.githubusercontent.com/Dicklesworthstone/useful_tmux_commands/main}"

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

# Generic backup helper for other files (e.g., tmux.conf)
backup_file() {
  local file="$1"
  local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$file" "$backup"
  echo "Created backup: $backup"
}

# Check if tmux.conf tweaks are already present (installer-level)
tmux_conf_installed() {
  grep -q "$TMUX_MARKER_START" "$TMUX_CONF" 2>/dev/null && \
  grep -q "$TMUX_MARKER_END" "$TMUX_CONF" 2>/dev/null
}

# Offer to add tmux.conf tweaks safely and idempotently
offer_tmux_conf_tweaks() {
  # Non-interactive (e.g., curl | bash without tty) — skip quietly
  if [[ ! -t 0 ]]; then
    return 0
  fi

  # Ensure the tmux.conf exists so we can append
  if [[ ! -f "$TMUX_CONF" ]]; then
    echo "Creating $TMUX_CONF"
    touch "$TMUX_CONF"
  fi

  if tmux_conf_installed; then
    return 0
  fi

  echo ""
  echo "Optional: add recommended tmux.conf tweaks for better pane management."
  printf "Add them to %s now? [y/N]: " "$TMUX_CONF"
  local answer
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      backup_file "$TMUX_CONF"
      cat >> "$TMUX_CONF" <<'TMUXCONF'

# === NTM-TMUX-TWEAKS-START ===
# Added by add_useful_tmux_commands_to_zshrc.sh
# Increase scrollback buffer (default is 2000)
set-option -g history-limit 50000

# Enable mouse support for pane selection
set -g mouse on

# Show pane titles in status bar
set -g pane-border-status top
set -g pane-border-format " #{pane_title} "

# Better colors for pane borders
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour39

# Faster key repetition
set -s escape-time 0

# Start windows and panes at 1, not 0 (optional)
set -g base-index 1
setw -g pane-base-index 1
# === NTM-TMUX-TWEAKS-END ===
TMUXCONF
      echo "Added tmux.conf tweaks. Reload with: tmux source-file \"$TMUX_CONF\""
      ;;
    *)
      echo "Skipped tmux.conf tweaks."
      ;;
  esac
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
# Auto-install tmux if missing (for --easy mode)
auto_install_tmux() {
  if command -v tmux &>/dev/null; then
    echo "✓ tmux is already installed"
    return 0
  fi

  echo "Installing tmux..."
  local os
  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
      brew install tmux && echo "✓ tmux installed via Homebrew" && return 0
    fi
    echo "Please install Homebrew first: https://brew.sh" >&2
    return 1
  else
    if command -v apt-get &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y tmux && echo "✓ tmux installed via apt" && return 0
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y tmux && echo "✓ tmux installed via dnf" && return 0
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm tmux && echo "✓ tmux installed via pacman" && return 0
    fi
    echo "Could not auto-install tmux. Please install manually." >&2
    return 1
  fi
}

# Auto-install fzf if missing (for --easy mode)
auto_install_fzf() {
  if command -v fzf &>/dev/null; then
    echo "✓ fzf is already installed"
    return 0
  fi

  echo "Installing fzf..."
  local os
  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
      brew install fzf && echo "✓ fzf installed via Homebrew" && return 0
    fi
  else
    if command -v apt-get &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y fzf && echo "✓ fzf installed via apt" && return 0
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y fzf && echo "✓ fzf installed via dnf" && return 0
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm fzf && echo "✓ fzf installed via pacman" && return 0
    fi
  fi
  echo "Could not auto-install fzf. Please install manually." >&2
  return 1
}

# Auto-add tmux.conf tweaks without prompting (for --easy mode)
auto_add_tmux_conf() {
  if [[ ! -f "$TMUX_CONF" ]]; then
    touch "$TMUX_CONF"
  fi

  if tmux_conf_installed; then
    echo "✓ tmux.conf tweaks already present"
    return 0
  fi

  echo "Adding tmux.conf tweaks..."
  cat >> "$TMUX_CONF" << 'TMUX_TWEAKS'

# === NTM-TMUX-TWEAKS-START ===
# Quality-of-life settings for Named Tmux Manager

# Enable mouse support
set -g mouse on

# Better colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback buffer
set -g history-limit 50000

# Faster key repetition
set -s escape-time 0

# Status bar styling
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '#[fg=#89b4fa,bold] #S #[fg=#6c7086]│ '
set -g status-right '#[fg=#6c7086]│ #[fg=#a6e3a1]%H:%M '
set -g status-left-length 30

# Active pane border
set -g pane-active-border-style 'fg=#89b4fa'
set -g pane-border-style 'fg=#313244'

# Window status
setw -g window-status-format '#[fg=#6c7086] #I:#W '
setw -g window-status-current-format '#[fg=#f5c2e7,bold] #I:#W '
# === NTM-TMUX-TWEAKS-END ===
TMUX_TWEAKS

  echo "✓ Added tmux.conf tweaks"
}

# Setup command palette with F6 binding (for --easy mode)
auto_setup_palette() {
  local palette_config="$HOME/.config/ntm/command_palette.md"
  local palette_dir
  palette_dir=$(dirname "$palette_config")

  # Create config directory
  mkdir -p "$palette_dir"

  # Fetch default config from repo if not exists
  if [[ ! -f "$palette_config" ]]; then
    echo "Fetching default command palette config..."
    if _ntm_fetch_default_palette "$palette_config"; then
      echo "✓ Created palette config: $palette_config"
    else
      echo "⚠ Could not fetch palette config from repo; writing local sample instead."
      _ntm_write_sample_palette "$palette_config"
      echo "✓ Wrote sample palette to: $palette_config"
    fi
  else
    echo "✓ Palette config already exists"
  fi

  # Add F6 binding to tmux.conf
  local bind_line='bind-key -n F6 display-popup -E -w 90% -h 90% "source ~/.zshrc 2>/dev/null; ntm-palette-interactive"'
  if grep -q "bind-key -n F6" "$TMUX_CONF" 2>/dev/null; then
    echo "✓ F6 keybinding already configured"
  else
    echo "" >> "$TMUX_CONF"
    echo "# NTM Command Palette (F6)" >> "$TMUX_CONF"
    echo "$bind_line" >> "$TMUX_CONF"
    echo "✓ Added F6 keybinding for command palette"
  fi
}

main() {
  local force_reinstall=false
  local easy_mode=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force)
        force_reinstall=true
        shift
        ;;
      -e|--easy)
        easy_mode=true
        force_reinstall=true  # Easy mode implies force reinstall
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
        echo "  -e, --easy       Easy mode: auto-install everything (tmux, fzf, configs)"
        echo "  -f, --force      Force reinstall (remove existing and add fresh)"
        echo "  -u, --uninstall  Remove the commands from ~/.zshrc"
        echo "  -h, --help       Show this help message"
        echo ""
        echo "Easy mode one-liner:"
        echo "  curl -fsSL <url> | bash -s -- --easy"
        return 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Use --help for usage information." >&2
        return 1
        ;;
    esac
  done

  # Easy mode: auto-install all dependencies
  if [[ "$easy_mode" == true ]]; then
    echo ""
    echo "╭────────────────────────────────────────────────────────╮"
    echo "│  🚀 NTM Easy Install Mode                              │"
    echo "│  Installing everything automatically...                │"
    echo "╰────────────────────────────────────────────────────────╯"
    echo ""

    # Install dependencies
    auto_install_tmux || echo "⚠ tmux installation failed (may need manual install)"
    auto_install_fzf || echo "⚠ fzf installation failed (may need manual install)"

    # Add tmux.conf tweaks
    auto_add_tmux_conf

    # Setup command palette
    auto_setup_palette

    echo ""
  fi

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

# Default locations for logs and stored prompts
_NTM_LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ntm-logs"
_NTM_PROMPT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ntm-prompts"

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
      echo "Running: sudo dnf install -y tmux"
      if sudo dnf install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v yum &>/dev/null; then
      echo "Running: sudo yum install -y tmux"
      if sudo yum install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v pacman &>/dev/null; then
      echo "Running: sudo pacman -S --noconfirm tmux"
      if sudo pacman -S --noconfirm tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v zypper &>/dev/null; then
      echo "Running: sudo zypper install -y tmux"
      if sudo zypper install -y tmux; then
        command -v tmux &>/dev/null && return 0
      fi
    elif command -v apk &>/dev/null; then
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

# Determine if the tmux.conf tweaks have already been added
_ntm_tmux_conf_installed() {
  grep -q "$TMUX_MARKER_START" "$TMUX_CONF" 2>/dev/null && \
  grep -q "$TMUX_MARKER_END" "$TMUX_CONF" 2>/dev/null
}

# Offer to add helpful tmux.conf defaults (idempotent and optional)
_ntm_offer_tmux_conf_tweaks() {
  # Skip in non-interactive shells
  if [[ ! -t 0 ]]; then
    return 0
  fi

  # Ensure tmux.conf exists
  if [[ ! -f "$TMUX_CONF" ]]; then
    echo "Creating $TMUX_CONF"
    touch "$TMUX_CONF"
  fi

  if _ntm_tmux_conf_installed; then
    return 0
  fi

  echo ""
  echo "Optional: add recommended tmux.conf tweaks for better agent panes."
  printf "Add these tmux settings to %s? [y/N]: " "$TMUX_CONF"
  local answer
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      backup_file "$TMUX_CONF"
      cat >> "$TMUX_CONF" <<'TMUXCONF'

# === NTM-TMUX-TWEAKS-START ===
# Added by add_useful_tmux_commands_to_zshrc.sh
# Increase scrollback buffer (default is 2000)
set-option -g history-limit 50000

# Enable mouse support for pane selection
set -g mouse on

# Show pane titles in status bar
set -g pane-border-status top
set -g pane-border-format " #{pane_title} "

# Better colors for pane borders
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour39

# Faster key repetition
set -s escape-time 0

# Start windows and panes at 1, not 0 (optional)
set -g base-index 1
setw -g pane-base-index 1
# === NTM-TMUX-TWEAKS-END ===
TMUXCONF
      echo "Added tmux.conf tweaks. Reload with: tmux source-file \"$TMUX_CONF\""
      ;;
    *)
      echo "Skipped tmux.conf tweaks."
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

# Get the default pane index for a session, honoring pane-base-index
_ntm_default_pane_index() {
  local session="$1"
  local first_win
  first_win=$(_ntm_first_window "$session") || return 1
  tmux list-panes -t "$session:$first_win" -F '#{pane_index}' 2>/dev/null | head -1
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
  # Leave pane empty by default so we can honor pane-base-index
  local pane="${2:-}"
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

  # Use default pane if none provided (respects pane-base-index)
  if [[ -z "$pane" ]]; then
    if ! pane=$(_ntm_default_pane_index "$session"); then
      echo "error: could not determine default pane for session '$session'" >&2
      return 1
    fi
  fi

  # Validate pane index is numeric
  if ! [[ "$pane" = <-> ]]; then
    echo "error: pane index must be numeric (got '$pane')" >&2
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
      if command -v git &>/dev/null; then
        echo "Initializing git repository..."
        git -C "$dir" init
        echo "# $project" > "$dir/README.md"
        git -C "$dir" add README.md
        if ! git -C "$dir" commit -m "Initial commit"; then
          echo "warning: initial git commit failed (likely missing git user.name/email); repository left uncommitted" >&2
        fi
      else
        echo "warning: git not found; skipping git init for $dir" >&2
      fi
    fi
  fi

  # Spawn agents
  spawn-agents-in-named-tmux "$project" "$cc_count" "$cod_count" "$gmi_count"
}

# ============================================================================
# Command Palette
# ============================================================================

# Default locations for command palette
_NTM_PALETTE_CONFIG="${NTM_PALETTE_CONFIG:-$HOME/.config/ntm/command_palette.md}"
_NTM_LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ntm-logs"
_NTM_PROMPT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ntm-prompts"

# ============================================================================
# Visual Theme & Icons for Command Palette
# ============================================================================

# Detect if terminal supports Nerd Fonts (check for common NF environment hints)
_ntm_has_nerd_fonts() {
  # Check common indicators: NERD_FONT env, p10k config, or specific terminal
  [[ -n "${NERD_FONTS:-}" ]] && return 0
  [[ -f "$HOME/.p10k.zsh" ]] && return 0
  [[ "$TERM_PROGRAM" == "iTerm.app" ]] && return 0
  [[ "$TERM_PROGRAM" == "WezTerm" ]] && return 0
  [[ -n "${KITTY_WINDOW_ID:-}" ]] && return 0
  # Allow user to force icons
  [[ "${NTM_USE_ICONS:-}" == "1" ]] && return 0
  return 1
}

# Icon definitions (Nerd Font with Unicode fallbacks)
_ntm_init_icons() {
  if _ntm_has_nerd_fonts; then
    # Nerd Font icons
    _NTM_ICON_PALETTE=""     # nf-cod-symbol_color
    _NTM_ICON_ROBOT="󰚩"      # nf-md-robot
    _NTM_ICON_SEND=""        # nf-fa-paper_plane
    _NTM_ICON_TARGET="󰓾"     # nf-md-target
    _NTM_ICON_CHECK=""       # nf-fa-check
    _NTM_ICON_CROSS=""       # nf-fa-times
    _NTM_ICON_CLAUDE="󰗣"     # nf-md-alpha_c_circle (anthropic-ish)
    _NTM_ICON_CODEX=""       # nf-cod-hubot (openai-ish)
    _NTM_ICON_GEMINI="󰊤"     # nf-md-google (google)
    _NTM_ICON_ALL="󰕟"        # nf-md-broadcast
    _NTM_ICON_PANE=""        # nf-oct-terminal
    _NTM_ICON_ARROW="❯"       # nf-pl-right_hard_divider
    _NTM_ICON_DOT="●"
    _NTM_ICON_STAR="★"
  else
    # Unicode fallbacks (widely supported)
    _NTM_ICON_PALETTE="◆"
    _NTM_ICON_ROBOT="⚙"
    _NTM_ICON_SEND="➤"
    _NTM_ICON_TARGET="◎"
    _NTM_ICON_CHECK="✓"
    _NTM_ICON_CROSS="✗"
    _NTM_ICON_CLAUDE="C"
    _NTM_ICON_CODEX="O"
    _NTM_ICON_GEMINI="G"
    _NTM_ICON_ALL="*"
    _NTM_ICON_PANE="▢"
    _NTM_ICON_ARROW="›"
    _NTM_ICON_DOT="•"
    _NTM_ICON_STAR="★"
  fi
}

# ANSI color codes for palette UI
_ntm_init_colors() {
  # Base colors
  _C_RESET='\033[0m'
  _C_BOLD='\033[1m'
  _C_DIM='\033[2m'
  _C_ITALIC='\033[3m'
  _C_UNDERLINE='\033[4m'

  # Foreground colors
  _C_BLACK='\033[30m'
  _C_RED='\033[31m'
  _C_GREEN='\033[32m'
  _C_YELLOW='\033[33m'
  _C_BLUE='\033[34m'
  _C_MAGENTA='\033[35m'
  _C_CYAN='\033[36m'
  _C_WHITE='\033[37m'

  # Bright colors
  _C_BRED='\033[91m'
  _C_BGREEN='\033[92m'
  _C_BYELLOW='\033[93m'
  _C_BBLUE='\033[94m'
  _C_BMAGENTA='\033[95m'
  _C_BCYAN='\033[96m'
  _C_BWHITE='\033[97m'

  # 256-color palette for gradients (if supported)
  _C_PURPLE='\033[38;5;141m'
  _C_ORANGE='\033[38;5;208m'
  _C_PINK='\033[38;5;213m'
  _C_TEAL='\033[38;5;80m'
  _C_LIME='\033[38;5;154m'
  _C_GOLD='\033[38;5;220m'

  # Background colors for highlights
  _C_BG_BLUE='\033[44m'
  _C_BG_CYAN='\033[46m'
  _C_BG_GRAY='\033[48;5;236m'
}

# Initialize icons and colors
_ntm_init_icons
_ntm_init_colors

# Base URL for fetching bundled files (override with NTM_REPO_BASE env var)
_NTM_REPO_BASE="${NTM_REPO_BASE:-https://raw.githubusercontent.com/Dicklesworthstone/useful_tmux_commands/main}"

# Fetch default command palette config from repo
_ntm_fetch_default_palette() {
  local dest="$1"
  local url="${_NTM_REPO_BASE}/command_palette.md"

  # Try curl first, then wget as fallback (try both if curl fails)
  if command -v curl &>/dev/null && curl -fsSL "$url" -o "$dest" 2>/dev/null; then
    return 0
  fi
  if command -v wget &>/dev/null && wget -q "$url" -O "$dest" 2>/dev/null; then
    return 0
  fi

  echo "Could not fetch default palette (no curl/wget or network issue)" >&2
  return 1
}

# Write a minimal built-in sample palette (offline fallback)
_ntm_write_sample_palette() {
  local dest="$1"
  cat > "$dest" <<'PALETTE_FALLBACK'
## Quick Start

### fresh_review | Fresh Eyes Review
Carefully reread the latest code changes and fix any obvious bugs or confusion you spot. Be specific and pragmatic.

### fix_bug | Fix the Bug
Diagnose the root cause of the reported issue and implement a real fix, not a workaround.

### run_tests | Run Tests
Run the full test suite (or the closest equivalent) and report any failures with logs.

## Coordination

### status_update | Status Update
Summarize current progress, blockers, and next steps for the team.
PALETTE_FALLBACK
}

# Check if fzf is installed
_ntm_check_fzf() {
  command -v fzf &>/dev/null
}

# Auto-install fzf if needed
_ntm_auto_install_fzf() {
  local os
  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
      echo "Installing fzf via Homebrew..."
      if brew install fzf; then
        echo "✓ fzf installed successfully"
        return 0
      fi
      echo "brew install fzf failed." >&2
      return 1
    else
      echo "Homebrew not found. Install from https://brew.sh then run 'brew install fzf'." >&2
      return 1
    fi
  else
    # Linux
    if command -v apt-get &>/dev/null; then
      echo "Installing fzf via apt..."
      if sudo apt-get update && sudo apt-get install -y fzf; then
        echo "✓ fzf installed successfully"
        return 0
      fi
    elif command -v dnf &>/dev/null; then
      echo "Installing fzf via dnf..."
      if sudo dnf install -y fzf; then
        echo "✓ fzf installed successfully"
        return 0
      fi
    elif command -v pacman &>/dev/null; then
      echo "Installing fzf via pacman..."
      if sudo pacman -S --noconfirm fzf; then
        echo "✓ fzf installed successfully"
        return 0
      fi
    fi
    echo "Could not auto-install fzf. Please install manually:" >&2
    echo "  https://github.com/junegunn/fzf#installation" >&2
    return 1
  fi
}

# Ensure fzf is available, offering to install if not
_ntm_ensure_fzf() {
  if _ntm_check_fzf; then
    return 0
  fi

  echo "fzf is required for the command palette but is not installed."
  printf "Install fzf now? [y/N]: "
  local answer
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      _ntm_auto_install_fzf
      return $?
      ;;
    *)
      echo "Command palette requires fzf. Aborting." >&2
      return 1
      ;;
  esac
}

# Parse command_palette.md (new format with ### headers)
# Output: key\tlabel\tprompt (tab-separated)
_ntm_parse_palette_config() {
  local config_file="$1"
  local current_key=""
  local current_label=""
  local current_prompt=""
  local in_prompt=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines at start of prompt
    if [[ "$in_prompt" == false ]] && [[ -z "$line" ]]; then
      continue
    fi

    # Category header (## Category) - output previous and reset
    if [[ "$line" == \#\#[[:space:]]* ]] && [[ "$line" != \#\#\#* ]]; then
      if [[ -n "$current_key" ]] && [[ -n "$current_prompt" ]]; then
        local escaped_prompt="${current_prompt//$'\n'/\\n}"
        escaped_prompt="${escaped_prompt//$'\t'/ }"
        printf '%s\t%s\t%s\n' "$current_key" "$current_label" "$escaped_prompt"
      fi
      current_key=""
      current_label=""
      current_prompt=""
      in_prompt=false
      continue
    fi

    # Command header (### key | label) or (### key)
    if [[ "$line" == \#\#\#[[:space:]]* ]]; then
      # Output previous command if exists
      if [[ -n "$current_key" ]] && [[ -n "$current_prompt" ]]; then
        local escaped_prompt="${current_prompt//$'\n'/\\n}"
        escaped_prompt="${escaped_prompt//$'\t'/ }"
        printf '%s\t%s\t%s\n' "$current_key" "$current_label" "$escaped_prompt"
      fi

      # Parse the header line manually (more reliable than regex captures)
      local header="${line#\#\#\# }"
      header="${header#\#\#\#	}"  # Also handle tab after ###

      if [[ "$header" == *"|"* ]]; then
        # Has label: ### key | label
        current_key="${header%%|*}"
        current_label="${header#*|}"
      else
        # No label: ### key
        current_key="$header"
        current_label="$header"
      fi

      # Trim whitespace
      current_key=$(echo "$current_key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      current_label=$(echo "$current_label" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

      current_prompt=""
      in_prompt=true
      continue
    fi

    # Prompt text
    if [[ "$in_prompt" == true ]]; then
      if [[ -z "$current_prompt" ]]; then
        current_prompt="$line"
      else
        current_prompt="$current_prompt"$'\n'"$line"
      fi
    fi
  done < "$config_file"

  # Output last command
  if [[ -n "$current_key" ]] && [[ -n "$current_prompt" ]]; then
    local escaped_prompt="${current_prompt//$'\n'/\\n}"
    escaped_prompt="${escaped_prompt//$'\t'/ }"
    printf '%s\t%s\t%s\n' "$current_key" "$current_label" "$escaped_prompt"
  fi
}

# Parse legacy format (markdown table with | key | prompt |)
_ntm_parse_legacy_palette() {
  local config_file="$1"

  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Check leading character - must start with |
    local first="${line:0:1}"
    [[ "$first" != "|" ]] && continue

    # Skip header row (contains "icon")
    [[ "$line" == *"icon"* ]] && continue

    # Skip separator row (contains ---)
    [[ "$line" == *"---"* ]] && continue

    # Parse: | key | prompt |
    # Remove leading |
    local content="${line#|}"
    # Remove trailing |
    content="${content%|}"

    # Split on | - first field is key, rest is prompt
    local key="${content%%|*}"
    local prompt="${content#*|}"

    # Trim whitespace using sed
    key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    prompt=$(echo "$prompt" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Skip if key is empty
    [[ -z "$key" ]] && continue

    printf '%s\t%s\t%s\n' "$key" "$key" "$prompt"
  done < "$config_file"
}

# Detect config format and parse
_ntm_load_palette_commands() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    echo "Config file not found: $config_file" >&2
    return 1
  fi

  # Check format: legacy table has | in first lines
  if head -5 "$config_file" | grep -q '^|'; then
    _ntm_parse_legacy_palette "$config_file"
  else
    _ntm_parse_palette_config "$config_file"
  fi
}

# Beautiful target selector menu
_ntm_show_target_menu() {
  local cmd_label="$1"
  local session="$2"

  # Box-drawing characters
  local TL="╭" TR="╮" BL="╰" BR="╯" H="─" V="│"

  # Get terminal width (default 60 if unavailable)
  local width=58

  # Build the menu
  echo ""
  echo -e "${_C_BOLD}${_C_CYAN}${TL}$(printf '%*s' $width '' | tr ' ' "$H")${TR}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}  ${_C_BOLD}${_C_BWHITE}$_NTM_ICON_TARGET  SELECT TARGET${_C_RESET}$(printf '%*s' $((width - 18)) '')${_C_CYAN}${V}${_C_RESET}"

  # Truncate label to fit
  local display_label="${cmd_label:0:$((width - 4))}"
  # Calculate padding based on displayed length
  local padding=$((width - ${#display_label} - 2))
  
  echo -e "${_C_CYAN}${V}${_C_RESET}  ${_C_DIM}${display_label}${_C_RESET}$(printf '%*s' $padding '')${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}$(printf '%*s' $width '' | tr ' ' "$H")${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}                                                          ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}   ${_C_BOLD}${_C_BGREEN}1${_C_RESET}  ${_C_GREEN}$_NTM_ICON_ALL${_C_RESET}  ${_C_BWHITE}All Agents${_C_RESET}     ${_C_DIM}broadcast to all panes${_C_RESET}       ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}                                                          ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}   ${_C_BOLD}${_C_BMAGENTA}2${_C_RESET}  ${_C_MAGENTA}$_NTM_ICON_CLAUDE${_C_RESET}  ${_C_BWHITE}Claude${_C_RESET}  ${_C_DIM}(cc)${_C_RESET}   ${_C_DIM}anthropic agents only${_C_RESET}       ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}   ${_C_BOLD}${_C_BBLUE}3${_C_RESET}  ${_C_BLUE}$_NTM_ICON_CODEX${_C_RESET}  ${_C_BWHITE}Codex${_C_RESET}   ${_C_DIM}(cod)${_C_RESET}  ${_C_DIM}openai agents only${_C_RESET}          ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}   ${_C_BOLD}${_C_BYELLOW}4${_C_RESET}  ${_C_YELLOW}$_NTM_ICON_GEMINI${_C_RESET}  ${_C_BWHITE}Gemini${_C_RESET}  ${_C_DIM}(gmi)${_C_RESET}  ${_C_DIM}google agents only${_C_RESET}          ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}                                                          ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}   ${_C_BOLD}${_C_BCYAN}5${_C_RESET}  ${_C_CYAN}$_NTM_ICON_PANE${_C_RESET}  ${_C_BWHITE}Specific Pane${_C_RESET}  ${_C_DIM}choose one pane${_C_RESET}            ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}                                                          ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}   ${_C_BOLD}${_C_RED}q${_C_RESET}  ${_C_RED}$_NTM_ICON_CROSS${_C_RESET}  ${_C_DIM}Cancel${_C_RESET}                                       ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_CYAN}${V}${_C_RESET}                                                          ${_C_CYAN}${V}${_C_RESET}"
  echo -e "${_C_BOLD}${_C_CYAN}${BL}$(printf '%*s' $width '' | tr ' ' "$H")${BR}${_C_RESET}"
  echo ""
  echo -ne "  ${_C_BOLD}${_C_CYAN}$_NTM_ICON_ARROW${_C_RESET} ${_C_BWHITE}Choice${_C_RESET} ${_C_DIM}[1-5, q]:${_C_RESET} "
}

# Show pane selector with visual styling
_ntm_show_pane_selector() {
  local session="$1"
  local first_win="$2"

  echo ""
  echo -e "${_C_BOLD}${_C_CYAN}$_NTM_ICON_PANE  Available Panes:${_C_RESET}"
  echo -e "${_C_DIM}──────────────────────────────────${_C_RESET}"

  # Get panes with formatting
  while IFS= read -r pane_info; do
    local idx="${pane_info%%:*}"
    local title="${pane_info#*: }"

    # Color based on pane type
    local color="$_C_WHITE"
    local icon="$_NTM_ICON_PANE"
    if [[ "$title" == *"__cc"* ]]; then
      color="$_C_MAGENTA"
      icon="$_NTM_ICON_CLAUDE"
    elif [[ "$title" == *"__cod"* ]]; then
      color="$_C_BLUE"
      icon="$_NTM_ICON_CODEX"
    elif [[ "$title" == *"__gmi"* ]]; then
      color="$_C_YELLOW"
      icon="$_NTM_ICON_GEMINI"
    fi

    echo -e "   ${_C_BOLD}${_C_CYAN}$idx${_C_RESET}  ${color}$icon${_C_RESET}  ${title}"
  done < <(tmux list-panes -t "$session:$first_win" -F '#{pane_index}: #{pane_title}' 2>/dev/null)

  echo -e "${_C_DIM}──────────────────────────────────${_C_RESET}"
  echo ""
  echo -ne "  ${_C_BOLD}${_C_CYAN}$_NTM_ICON_ARROW${_C_RESET} ${_C_BWHITE}Pane index:${_C_RESET} "
}

# Main command palette function
ntm-palette() {
  _ntm_check_tmux || return 1
  _ntm_ensure_fzf || return 1

  local session="$1"
  local config_file="${2:-$_NTM_PALETTE_CONFIG}"

  # Auto-detect session if in tmux
  if [[ -z "$session" ]] && [[ -n "$TMUX" ]]; then
    session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
  fi

  if [[ -z "$session" ]]; then
    echo -e "${_C_RED}$_NTM_ICON_CROSS${_C_RESET} ${_C_BOLD}Usage:${_C_RESET} ntm-palette <session> [config-file]" >&2
    echo -e "       ${_C_DIM}ncp <session> [config-file]${_C_RESET}" >&2
    echo ""
    echo -e "${_C_DIM}Or run from within a tmux session to auto-detect.${_C_RESET}"
    echo -e "${_C_DIM}Config: $config_file${_C_RESET}"
    [[ -f "$config_file" ]] || echo -e "  ${_C_YELLOW}(not found - run 'ntm-palette-init' to create)${_C_RESET}"
    return 1
  fi

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo -e "${_C_RED}$_NTM_ICON_CROSS${_C_RESET} Session '${_C_BOLD}$session${_C_RESET}' not found" >&2
    return 1
  fi

  if [[ ! -f "$config_file" ]]; then
    echo -e "${_C_RED}$_NTM_ICON_CROSS${_C_RESET} Config not found: ${_C_DIM}$config_file${_C_RESET}" >&2
    echo -e "${_C_DIM}Run 'ntm-palette-init' to create a sample config.${_C_RESET}"
    return 1
  fi

  # Load commands into temp file (cleaned up at end of function)
  local tmp_commands
  tmp_commands=$(mktemp)

  _ntm_load_palette_commands "$config_file" > "$tmp_commands"

  if [[ ! -s "$tmp_commands" ]]; then
    rm -f "$tmp_commands"
    echo -e "${_C_RED}$_NTM_ICON_CROSS${_C_RESET} No commands found in config file" >&2
    return 1
  fi

  # Colorized preview script for fzf
  local preview_cmd='
    line={}
    prompt=$(printf "%s" "$line" | cut -f3)
    # Add color to preview
    echo -e "\033[1;36m━━━ PROMPT PREVIEW ━━━\033[0m"
    echo ""
    printf "%s" "$prompt" | sed "s/\\\\n/\n/g" | fold -s -w ${FZF_PREVIEW_COLUMNS:-80}
    echo ""
    echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  '

  # Build fzf header with icons
  local fzf_header="$_NTM_ICON_PALETTE Command Palette │ Session: $session │ Enter=select │ Esc=cancel │ Ctrl-P=toggle preview"

  # Beautiful fzf color scheme (Catppuccin-inspired)
  local fzf_colors="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
  fzf_colors+=",fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
  fzf_colors+=",marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
  fzf_colors+=",border:#89b4fa,gutter:#1e1e2e"

  # Run fzf with beautiful styling
  local selected
  selected=$(cat "$tmp_commands" | \
    fzf --delimiter='\t' \
        --with-nth=2 \
        --preview "$preview_cmd" \
        --preview-window=down:45%:wrap:border-top \
        --header="$fzf_header" \
        --prompt="$_NTM_ICON_ARROW Filter: " \
        --pointer="$_NTM_ICON_DOT" \
        --marker="$_NTM_ICON_STAR" \
        --height=90% \
        --border=rounded \
        --border-label=" $_NTM_ICON_ROBOT NTM Command Palette " \
        --border-label-pos=3 \
        --info=inline \
        --margin=1,2 \
        --padding=1 \
        --bind='ctrl-p:toggle-preview' \
        --bind='ctrl-u:preview-half-page-up' \
        --bind='ctrl-d:preview-half-page-down' \
        $fzf_colors \
        --ansi)

  # Clean up temp file
  rm -f "$tmp_commands"

  if [[ -z "$selected" ]]; then
    echo -e "\n${_C_DIM}No command selected${_C_RESET}"
    return 0
  fi

  local cmd_key cmd_label cmd_prompt
  cmd_key=$(echo "$selected" | cut -f1)
  cmd_label=$(echo "$selected" | cut -f2)
  cmd_prompt=$(echo "$selected" | cut -f3 | sed 's/\\n/\n/g')

  # Show beautiful target selector
  _ntm_show_target_menu "$cmd_label" "$session"

  local target_choice
  read -r target_choice

  case "$target_choice" in
    1)
      broadcast-prompt "$session" "all" "$cmd_prompt"
      echo -e "\n${_C_GREEN}$_NTM_ICON_CHECK${_C_RESET} ${_C_BOLD}Sent to all agents${_C_RESET}"
      ;;
    2)
      broadcast-prompt "$session" "cc" "$cmd_prompt"
      echo -e "\n${_C_MAGENTA}$_NTM_ICON_CHECK${_C_RESET} ${_C_BOLD}Sent to Claude agents${_C_RESET}"
      ;;
    3)
      broadcast-prompt "$session" "cod" "$cmd_prompt"
      echo -e "\n${_C_BLUE}$_NTM_ICON_CHECK${_C_RESET} ${_C_BOLD}Sent to Codex agents${_C_RESET}"
      ;;
    4)
      broadcast-prompt "$session" "gmi" "$cmd_prompt"
      echo -e "\n${_C_YELLOW}$_NTM_ICON_CHECK${_C_RESET} ${_C_BOLD}Sent to Gemini agents${_C_RESET}"
      ;;
    5)
      local first_win
      first_win=$(_ntm_first_window "$session" 2>/dev/null) || first_win="0"

      _ntm_show_pane_selector "$session" "$first_win"

      local pane_idx
      read -r pane_idx
      if [[ -n "$pane_idx" ]]; then
        local target="$session:$first_win.$pane_idx"
        if tmux display-message -t "$target" -p '#{pane_id}' &>/dev/null; then
          tmux send-keys -t "$target" "$cmd_prompt" C-m
          echo -e "\n${_C_CYAN}$_NTM_ICON_CHECK${_C_RESET} ${_C_BOLD}Sent to pane $pane_idx${_C_RESET}"
        else
          echo -e "\n${_C_RED}$_NTM_ICON_CROSS${_C_RESET} Pane $pane_idx not found" >&2
          return 1
        fi
      fi
      ;;
    q|Q|"")
      echo -e "\n${_C_DIM}Cancelled${_C_RESET}"
      return 0
      ;;
    *)
      echo -e "\n${_C_RED}$_NTM_ICON_CROSS${_C_RESET} Invalid choice" >&2
      return 1
      ;;
  esac
}

# Fully interactive palette with fzf for everything (for tmux popup)
ntm-palette-interactive() {
  _ntm_check_tmux || return 1
  _ntm_ensure_fzf || return 1

  # Initialize visual theme (colors and icons)
  _ntm_init_colors
  _ntm_init_icons

  local session="$1"
  local config_file="${2:-$_NTM_PALETTE_CONFIG}"

  # Beautiful fzf color scheme (Catppuccin-inspired)
  local fzf_colors="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
  fzf_colors+=",fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
  fzf_colors+=",marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
  fzf_colors+=",border:#89b4fa,gutter:#1e1e2e"

  # Auto-detect or select session
  if [[ -z "$session" ]]; then
    if [[ -n "$TMUX" ]]; then
      session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
    else
      local sessions
      sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
      if [[ -z "$sessions" ]]; then
        echo -e "${_C_RED}$_NTM_ICON_CROSS${_C_RESET} No tmux sessions found" >&2
        return 1
      fi
      session=$(echo "$sessions" | \
        fzf --header="$_NTM_ICON_TARGET Select Session" \
            --prompt="$_NTM_ICON_ARROW " \
            --height=50% \
            --border=rounded \
            --border-label=" $_NTM_ICON_ROBOT Sessions " \
            $fzf_colors)
      [[ -z "$session" ]] && return 0
    fi
  fi

  if [[ ! -f "$config_file" ]]; then
    echo -e "${_C_RED}$_NTM_ICON_CROSS${_C_RESET} Config not found: $config_file" >&2
    return 1
  fi

  # Load commands into temp file (cleaned up at end of function)
  local tmp_commands
  tmp_commands=$(mktemp)

  _ntm_load_palette_commands "$config_file" > "$tmp_commands"

  if [[ ! -s "$tmp_commands" ]]; then
    rm -f "$tmp_commands"
    echo -e "${_C_RED}$_NTM_ICON_CROSS${_C_RESET} No commands found in config file" >&2
    return 1
  fi

  # Colorized preview
  local preview_cmd='
    line={}
    prompt=$(printf "%s" "$line" | cut -f3)
    echo -e "\033[1;36m━━━ PROMPT PREVIEW ━━━\033[0m"
    echo ""
    printf "%s" "$prompt" | sed "s/\\\\n/\n/g" | fold -s -w ${FZF_PREVIEW_COLUMNS:-80}
    echo ""
    echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  '

  local selected
  selected=$(cat "$tmp_commands" | \
    fzf --delimiter='\t' \
        --with-nth=2 \
        --preview "$preview_cmd" \
        --preview-window=down:45%:wrap:border-top \
        --header="$_NTM_ICON_PALETTE Command Palette │ Session: $session" \
        --prompt="$_NTM_ICON_ARROW Command: " \
        --pointer="$_NTM_ICON_DOT" \
        --marker="$_NTM_ICON_STAR" \
        --height=100% \
        --border=rounded \
        --border-label=" $_NTM_ICON_ROBOT NTM Command Palette " \
        --border-label-pos=3 \
        --margin=0 \
        --padding=1 \
        --bind='ctrl-p:toggle-preview' \
        --bind='ctrl-u:preview-half-page-up' \
        --bind='ctrl-d:preview-half-page-down' \
        $fzf_colors \
        --ansi)

  # Clean up temp file
  rm -f "$tmp_commands"

  [[ -z "$selected" ]] && return 0

  local cmd_label cmd_prompt
  cmd_label=$(echo "$selected" | cut -f2)
  cmd_prompt=$(echo "$selected" | cut -f3 | sed 's/\\n/\n/g')

  # Select target with beautiful fzf menu
  local targets="${_NTM_ICON_ALL}:all:$_NTM_ICON_ALL  All Agents          │ broadcast to all panes
${_NTM_ICON_CLAUDE}:cc:$_NTM_ICON_CLAUDE  Claude (cc)        │ anthropic agents only
${_NTM_ICON_CODEX}:cod:$_NTM_ICON_CODEX  Codex (cod)        │ openai agents only
${_NTM_ICON_GEMINI}:gmi:$_NTM_ICON_GEMINI  Gemini (gmi)       │ google agents only"

  local target_selection
  target_selection=$(echo "$targets" | \
    fzf --delimiter=':' \
        --with-nth=3 \
        --header="$_NTM_ICON_SEND Send \"$cmd_label\" to:" \
        --prompt="$_NTM_ICON_ARROW Target: " \
        --pointer="$_NTM_ICON_DOT" \
        --height=50% \
        --border=rounded \
        --border-label=" $_NTM_ICON_TARGET Select Target " \
        --no-info \
        $fzf_colors \
        --ansi)

  [[ -z "$target_selection" ]] && return 0

  local target_type
  target_type=$(echo "$target_selection" | cut -d':' -f2)
  broadcast-prompt "$session" "$target_type" "$cmd_prompt"

  echo -e "\n${_C_GREEN}$_NTM_ICON_CHECK${_C_RESET} ${_C_BOLD}Sent to $target_type agents${_C_RESET}"
}

# Initialize/reset command palette config by fetching from repo
ntm-palette-init() {
  local config_file="${1:-$_NTM_PALETTE_CONFIG}"
  local config_dir
  config_dir=$(dirname "$config_file")

  if [[ -f "$config_file" ]]; then
    echo "Config exists: $config_file"
    printf "Overwrite? [y/N]: "
    local answer
    read -r answer
    case "$answer" in
      y|Y|yes|YES) ;;
      *) echo "Aborted."; return 0 ;;
    esac
  fi

  mkdir -p "$config_dir"

  echo "Fetching default command palette from repo..."
  if _ntm_fetch_default_palette "$config_file"; then
    echo "✓ Created: $config_file"
  else
    echo "⚠ Could not fetch palette from repo; writing built-in sample instead."
    _ntm_write_sample_palette "$config_file"
    echo "✓ Wrote sample palette: $config_file"
  fi

  echo ""
  echo "Edit this file to customize your commands."
  echo "Run 'ntm-palette <session>' or press F6 in tmux."
  echo ""
  echo "Tip: Fork the repo and set NTM_REPO_BASE to customize defaults."
}

# Setup tmux keybinding (default F6)
ntm-palette-bind() {
  local key="${1:-F6}"

  if [[ -z "$TMUX" ]]; then
    echo "Note: Not in tmux. Binding will work in future sessions."
  fi

  # Bind immediately for current server
  tmux bind-key -n "$key" display-popup -E -w 90% -h 90% \
    "source ~/.zshrc 2>/dev/null; ntm-palette-interactive" 2>/dev/null

  # Add to tmux.conf for persistence
  local tmux_conf="$HOME/.tmux.conf"
  local bind_line="bind-key -n $key display-popup -E -w 90% -h 90% \"source ~/.zshrc 2>/dev/null; ntm-palette-interactive\""

  if [[ -f "$tmux_conf" ]]; then
    if grep -q "bind-key -n $key" "$tmux_conf" 2>/dev/null; then
      echo "Binding for $key exists in $tmux_conf"
      printf "Update it? [y/N]: "
      local answer
      read -r answer
      case "$answer" in
        y|Y|yes|YES)
          local tmp_conf
          tmp_conf=$(mktemp)
          grep -v "bind-key -n $key" "$tmux_conf" > "$tmp_conf"
          echo "$bind_line" >> "$tmp_conf"
          mv "$tmp_conf" "$tmux_conf"
          echo "✓ Updated $key binding"
          ;;
        *) echo "Skipped" ;;
      esac
    else
      echo "$bind_line" >> "$tmux_conf"
      echo "✓ Added $key binding to $tmux_conf"
    fi
  else
    echo "$bind_line" > "$tmux_conf"
    echo "✓ Created $tmux_conf with $key binding"
  fi

  echo ""
  echo "Press $key in tmux to open the command palette."
  echo "Run 'tmux source ~/.tmux.conf' to reload if needed."
}

# Quick palette without fzf (numbered list fallback)
ntm-palette-quick() {
  _ntm_check_tmux || return 1

  local session="$1"
  local config_file="${2:-$_NTM_PALETTE_CONFIG}"

  if [[ -z "$session" ]] && [[ -n "$TMUX" ]]; then
    session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
  fi

  if [[ -z "$session" ]]; then
    echo "usage: ntm-palette-quick <session>" >&2
    return 1
  fi

  if [[ ! -f "$config_file" ]]; then
    echo "Config not found: $config_file" >&2
    return 1
  fi

  local -a labels
  local -a prompts
  local i=1

  while IFS=$'\t' read -r key label prompt; do
    labels[$i]="$label"
    prompts[$i]="$prompt"
    printf "%2d) %s\n" "$i" "$label"
    ((i++))
  done < <(_ntm_load_palette_commands "$config_file")

  echo ""
  printf "Select [1-%d, q]: " "$((i-1))"
  local choice
  read -r choice

  [[ "$choice" == "q" || "$choice" == "Q" ]] && return 0

  if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -ge "$i" ]]; then
    echo "Invalid selection" >&2
    return 1
  fi

  local selected_prompt="${prompts[$choice]}"
  selected_prompt=$(echo "$selected_prompt" | sed 's/\\n/\n/g')

  echo ""
  echo "Send to: [a]ll [c]laude co[d]ex [g]emini [q]uit"
  printf "Choice: "
  local target
  read -r target

  case "$target" in
    a|A) broadcast-prompt "$session" "all" "$selected_prompt" ;;
    c|C) broadcast-prompt "$session" "cc" "$selected_prompt" ;;
    d|D) broadcast-prompt "$session" "cod" "$selected_prompt" ;;
    g|G) broadcast-prompt "$session" "gmi" "$selected_prompt" ;;
    q|Q|"") echo "Cancelled" ;;
    *) echo "Invalid target" >&2; return 1 ;;
  esac
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

# Command Palette aliases
alias ncp='ntm-palette'
alias ncpi='ntm-palette-interactive'
alias ncpq='ntm-palette-quick'
alias ncpinit='ntm-palette-init'
alias ncpbind='ntm-palette-bind'

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

  echo -e "  ${B}COMMAND PALETTE${R} ${D}(requires fzf)${R}"
  echo ""
  echo -e "  ${B}${C}ntm-palette${R} ${D}(ncp)${R} ${G}[session] [config-file]${R}"
  echo -e "      ${Y}ncp slidechase${R}"
  echo -e "      ${M}Open command palette to send pre-configured prompts${R}"
  echo ""
  echo -e "  ${B}${C}ntm-palette-interactive${R} ${D}(ncpi)${R} ${G}[session]${R}"
  echo -e "      ${Y}ncpi${R}"
  echo -e "      ${M}Fully interactive palette (auto-detects session)${R}"
  echo ""
  echo -e "  ${B}${C}ntm-palette-init${R} ${D}(ncpinit)${R} ${G}[config-file]${R}"
  echo -e "      ${Y}ncpinit${R}"
  echo -e "      ${M}Create sample command palette config file${R}"
  echo ""
  echo -e "  ${B}${C}ntm-palette-bind${R} ${D}(ncpbind)${R} ${G}[key=F6]${R}"
  echo -e "      ${Y}ncpbind F6${R}"
  echo -e "      ${M}Bind key to open palette in tmux popup${R}"
  echo ""
  echo -e "  ${B}${C}ntm-palette-quick${R} ${D}(ncpq)${R} ${G}<session>${R}"
  echo -e "      ${Y}ncpq slidechase${R}"
  echo -e "      ${M}Simple numbered menu fallback (no fzf required)${R}"
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
  echo -e "           ${D}ncp ncpi ncpq ncpinit ncpbind${R}"
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
  # Command palette completions
  compdef _ntm_complete_sessions ntm-palette ncp
  compdef _ntm_complete_sessions ntm-palette-interactive ncpi
  compdef _ntm_complete_sessions ntm-palette-quick ncpq
fi

# === NAMED-TMUX-COMMANDS-END ===
TMUX_COMMANDS

  # Optionally add tmux.conf quality-of-life settings (idempotent)
  # Skip in easy mode since it was already done
  if [[ "$easy_mode" != true ]]; then
    offer_tmux_conf_tweaks
  fi

  echo ""
  if [[ "$easy_mode" == true ]]; then
    echo "╭────────────────────────────────────────────────────────╮"
    echo "│  ✅ NTM Easy Install Complete!                         │"
    echo "╰────────────────────────────────────────────────────────╯"
    echo ""
    echo "What was installed:"
    echo "  ✓ NTM commands added to ~/.zshrc"
    echo "  ✓ tmux.conf tweaks (mouse, colors, status bar)"
    echo "  ✓ F6 keybinding for command palette"
    echo "  ✓ Sample palette config (~/.config/ntm/command_palette.md)"
    echo ""
    echo "Next steps:"
    echo "  1. Run: source ~/.zshrc"
    echo "  2. Edit: ~/.config/ntm/command_palette.md (customize commands)"
    echo "  3. Press F6 in tmux to open the command palette"
    echo ""
    echo "Quick start:"
    echo "  sat myproject 2 2 1      (spawn 2 Claude, 2 Codex, 1 Gemini)"
    echo "  rnt myproject            (reconnect to session)"
    echo "  ntm                      (show all commands)"
  else
    echo "✓ Successfully added tmux commands to ~/.zshrc"
    echo ""
    echo "Run 'source ~/.zshrc' to load the new commands, then type 'ntm' for help."
  fi
}

main "$@"
