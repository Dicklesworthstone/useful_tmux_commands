# 🖥️ Useful Tmux Commands

![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-blue.svg)
![Shell](https://img.shields.io/badge/shell-zsh-green.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)

**A powerful tmux session management toolkit for orchestrating multiple AI coding agents in parallel.**

Spawn, manage, and coordinate Claude Code, OpenAI Codex, and Google Gemini CLI agents across tiled tmux panes with simple commands.

<div align="center">

```bash
curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/useful_tmux_commands/main/add_useful_tmux_commands_to_zshrc.sh | bash
```

</div>

---

## 💡 Why This Exists

### The Problem

Modern AI-assisted development often involves running multiple coding agents simultaneously—Claude for architecture decisions, Codex for implementation, Gemini for testing. But managing these agents across terminal windows is painful:

- **Window chaos**: Each agent needs its own terminal, leading to cluttered desktops
- **Context switching**: Jumping between windows breaks flow and loses context
- **No orchestration**: Sending the same prompt to multiple agents requires manual copy-paste
- **Session fragility**: Disconnecting from SSH loses all your agent sessions
- **Setup friction**: Starting a new project means manually creating directories, initializing git, and spawning agents one by one

### The Solution

This toolkit transforms tmux into a **multi-agent command center**:

1. **One session, many agents**: All your AI agents live in a single tmux session with tiled panes
2. **Named panes**: Each agent pane is labeled (e.g., `myproject__cc_1`, `myproject__cod_2`) for easy identification
3. **Broadcast prompts**: Send the same task to all agents of a specific type with one command
4. **Persistent sessions**: Detach and reattach without losing any agent state
5. **Quick project setup**: Create directory, initialize git, and spawn agents in a single command

### Who Benefits

- **Individual developers**: Run multiple AI agents in parallel for faster iteration
- **Researchers**: Compare responses from different AI models side-by-side
- **Power users**: Build complex multi-agent workflows with scriptable commands
- **Remote workers**: Keep agent sessions alive across SSH disconnections

---

## ✨ Key Features

### 🚀 Quick Project Setup

Create a new project with git initialization and spawn agents in one command:

```bash
qps myproject 3 2 1  # 3 Claude, 2 Codex, 1 Gemini
```

This creates `~/Developer/myproject` (macOS) or `/data/projects/myproject` (Linux), initializes git with a README, and launches 6 AI agents in tiled panes.

### 🤖 Multi-Agent Orchestration

Spawn specific combinations of agents:

```bash
sat myproject 4 4 2   # 4 Claude + 4 Codex + 2 Gemini = 10 agents + 1 user pane
```

Add more agents to an existing session:

```bash
ant myproject 2 0 0   # Add 2 more Claude agents
```

### 📢 Broadcast Prompts

Send the same prompt to all agents of a specific type:

```bash
bp myproject cc "fix all TypeScript errors in src/"
bp myproject cod "add comprehensive unit tests"
bp myproject all "explain your current approach"
```

### 🎯 Targeted Commands

Send commands to specific agent types:

```bash
sct --cc myproject "/exit"           # Exit all Claude agents
sct --cod myproject "git status"     # Run git status in Codex panes
sct -s myproject "clear"             # Clear all panes except user pane
```

### 🛑 Interrupt All Agents

Stop all running agents instantly:

```bash
int myproject   # Send Ctrl+C to all agent panes
```

### 📋 Session Management

```bash
lnt                    # List all tmux sessions
snt myproject          # Show detailed status with agent counts
rnt myproject          # Reattach to session
vnt myproject          # View all panes in tiled layout
knt -f myproject       # Kill session (force, no confirmation)
```

### 💾 Output Capture

```bash
cpo myproject 2 1000   # Copy 1000 lines from pane 2 to clipboard
sso myproject          # Save all pane outputs to timestamped log files
```

### 🔍 Pane Navigation

```bash
znt myproject cc       # Zoom to first Claude pane
znt myproject 3        # Zoom to pane index 3
```

---

## 📦 Installation

### One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/useful_tmux_commands/main/add_useful_tmux_commands_to_zshrc.sh | bash
```

Then reload your shell:

```bash
source ~/.zshrc
```

### What Gets Installed

The installer appends a block of shell functions and aliases to your `~/.zshrc`, wrapped in markers for clean uninstallation:

```bash
# === NAMED-TMUX-COMMANDS-START ===
# ... all the functions and aliases ...
# === NAMED-TMUX-COMMANDS-END ===
```

### First-Time Setup Experience

If you don't have a `~/.zshrc` file, the installer offers to:

1. **Install Oh My Zsh** - The popular zsh framework
2. **Install Powerlevel10k** - A beautiful, fast prompt theme (wizard disabled for instant setup)

If tmux isn't installed, the first time you run any command, you'll be prompted to install it automatically via your system's package manager (brew, apt, dnf, pacman, etc.).

### Manual Installation

```bash
git clone https://github.com/Dicklesworthstone/useful_tmux_commands.git
cd useful_tmux_commands
./add_useful_tmux_commands_to_zshrc.sh
source ~/.zshrc
```

### Uninstallation

```bash
./add_useful_tmux_commands_to_zshrc.sh --uninstall
source ~/.zshrc
```

Or re-run the install script with the uninstall flag:

```bash
curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/useful_tmux_commands/main/add_useful_tmux_commands_to_zshrc.sh | bash -s -- --uninstall
```

---

## 🛠️ Command Reference

Type `ntm` for a colorized help table with all commands and examples.

### Session Creation

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `create-named-tmux` | `cnt` | `<session> [panes=10]` | Create empty session with N panes |
| `spawn-agents-in-named-tmux` | `sat` | `<session> <cc> <cod> [gmi]` | Create session and launch agents |
| `quick-project-setup` | `qps` | `<project> [cc=2] [cod=2] [gmi=0]` | Create dir, git init, spawn agents |

**Examples:**

```bash
cnt myproject 10              # 10 empty panes
sat myproject 6 6 2           # 6 Claude + 6 Codex + 2 Gemini
qps myproject 3 3 1            # Full project setup with agents
```

### Agent Management

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `add-agents-to-named-tmux` | `ant` | `<session> <cc> <cod> [gmi]` | Add more agents to existing session |
| `broadcast-prompt` | `bp` | `<session> <cc\|cod\|gmi\|all> <prompt> [--stagger=N]` | Send prompt to agents by type |
| `broadcast-prompt-file` | `bpf` | `<session> <cc\|cod\|gmi\|all> <file>` | Send prompt from file to agents |
| `repeat-prompt` | `rp` | `<session> <cc\|cod\|gmi\|all>` | Resend the last prompt to agents |
| `interrupt-agents-in-named-tmux` | `int` | `<session>` | Send Ctrl+C to all agent panes |
| `restart-agents` | `ra` | `<session>` | Restart agents that appear crashed |

**Options for `bp`:**

| Flag | Description |
|------|-------------|
| `--stagger=N` | Wait N seconds between sending to each pane (avoids API rate limits) |

**Examples:**

```bash
ant myproject 2 0 0                        # Add 2 Claude agents
bp myproject cc "fix the linting errors"   # Broadcast to Claude
bp myproject all "summarize your progress" # Broadcast to all agents
bp myproject cc "analyze code" --stagger=5 # 5 sec delay between panes
bpf myproject all prompts/analyze.md       # Broadcast prompt from file
rp myproject cc                            # Resend last Claude prompt
int myproject                              # Stop all agents
ra myproject                               # Restart crashed agents
```

### Session Navigation

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `reconnect-to-named-tmux` | `rnt` | `<session>` | Reattach (offers to create if missing) |
| `list-named-tmux` | `lnt` | | List all tmux sessions |
| `status-named-tmux` | `snt` | `<session>` | Show pane details and agent counts |
| `view-named-tmux-panes` | `vnt` | `<session>` | Unzoom, tile layout, and attach |
| `zoom-pane-in-named-tmux` | `znt` | `<session> <pane\|cc\|cod\|gmi>` | Zoom to specific pane |

**Examples:**

```bash
rnt myproject      # Reattach to session
lnt                 # Show all sessions
snt myproject      # Detailed status
vnt myproject      # View all panes tiled
znt myproject cc   # Zoom to first Claude pane
```

### Commands & Output

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `send-command-to-named-tmux` | `sct` | `[-s] [--cc\|--cod\|--gmi] <session> <cmd>` | Send command to panes |
| `copy-pane-output` | `cpo` | `<session> [pane] [lines=500]` | Copy pane output to clipboard (defaults to first pane) |
| `save-session-outputs` | `sso` | `<session> [output-dir]` | Save all outputs to files |

**Options for `sct`:**

| Flag | Description |
|------|-------------|
| `-s`, `--skip-first` | Skip the first (user) pane |
| `--cc` | Send only to Claude panes |
| `--cod` | Send only to Codex panes |
| `--gmi` | Send only to Gemini panes |

**Examples:**

```bash
sct -s myproject "git status"      # All agent panes
sct --cc myproject "/exit"         # Only Claude panes
cpo myproject 2 1000               # Copy 1000 lines from pane 2
sso myproject ~/logs               # Save all outputs
```

### Pane Operations

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `send-to-pane` | `stp` | `<session> <pane_index> <command>` | Send command to a specific pane |
| `tail-pane` | `tpo` | `<session> [pane] [lines=50]` | Show last N lines from a pane (defaults to first pane) |
| `rename-pane` | `rnp` | `<session> <pane_index> <title>` | Set custom title for a pane |
| `sync-panes` | `sp` | `<session> [on\|off]` | Toggle synchronized input to all panes |

**Examples:**

```bash
stp myproject 2 "git status"     # Send command to pane 2
tpo myproject 1 100              # Last 100 lines from pane 1
rnp myproject 0 "user_shell"     # Rename pane 0
sp myproject on                  # Enable sync (type to all panes)
sp myproject off                 # Disable sync
sp myproject                     # Toggle current state
```

### Logging

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `enable-logging` | `elog` | `<session> [dir]` | Start logging all pane output to files |
| `disable-logging` | `dlog` | `<session>` | Stop logging for all panes |

Logs are saved to `~/.local/share/ntm-logs/` by default.

**Examples:**

```bash
elog myproject                   # Start logging to default dir
elog myproject ~/mylogs          # Start logging to custom dir
dlog myproject                   # Stop logging
```

### Session Overview

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `list-all-agents` | `laa` | | List all agents across all sessions |
| `session-info` | `ssi` | `<session>` | Detailed session info with uptime |

**Examples:**

```bash
laa                              # Show all agents in all sessions
ssi myproject                    # Detailed status for session
```

### Cleanup

| Command | Alias | Arguments | Description |
|---------|-------|-----------|-------------|
| `kill-named-tmux` | `knt` | `[-f\|--force] <session>` | Kill session (with confirmation) |
| `kill-all-sessions` | `kas` | `[-f\|--force]` | Kill ALL tmux sessions (with confirmation) |

**Examples:**

```bash
knt myproject       # Prompts for confirmation
knt -f myproject    # Force kill, no prompt
knt myproject -f    # -f works in any position
kas                 # Kill all sessions (prompts for confirmation)
kas -f              # Force kill all sessions
```

### Utilities

| Command | Alias | Description |
|---------|-------|-------------|
| `check-agent-deps` | `cad` | Check if claude, codex, gemini CLIs are installed |
| `ntm` | | Show colorized help table |

---

## ⚙️ Agent Aliases

The toolkit defines these convenient aliases for the AI CLI tools:

| Alias | Expands To |
|-------|------------|
| `cc` | `claude --dangerously-skip-permissions` (with 32GB Node heap) |
| `cod` | `codex --dangerously-bypass-approvals-and-sandbox -m gpt-5.1-codex-max` |
| `gmi` | `gemini --yolo` |

These aliases are used when spawning agents in panes.

---

## 🏗️ Architecture

### Pane Naming Convention

Agent panes are named using the pattern: `<project>__<agent>_<number>`

Examples:
- `myproject__cc_1` - First Claude agent
- `myproject__cod_2` - Second Codex agent
- `myproject__gmi_1` - First Gemini agent
- `myproject__cc_added_1` - Claude agent added later via `ant`

This naming enables targeted commands via filters (`--cc`, `--cod`, `--gmi`).

### Session Layout

```
┌─────────────────────────────────────────────────────────────┐
│                      Session: myproject                      │
├─────────────────┬─────────────────┬─────────────────────────┤
│   User Pane     │  myproject__cc_1 │  myproject__cc_2       │
│   (your shell)  │  (Claude #1)     │  (Claude #2)           │
├─────────────────┼─────────────────┼─────────────────────────┤
│ myproject__cod_1│ myproject__cod_2 │  myproject__gmi_1      │
│ (Codex #1)      │ (Codex #2)       │  (Gemini #1)           │
└─────────────────┴─────────────────┴─────────────────────────┘
```

- **User pane** (index 0): Always preserved as your command pane
- **Agent panes** (index 1+): Each runs one AI agent
- **Tiled layout**: Automatically arranged for optimal visibility

### Directory Structure

| Platform | Projects Base |
|----------|---------------|
| macOS | `$HOME/Developer` |
| Linux | `/data/projects` |

Override with: `export PROJECTS_BASE="/your/custom/path"`

Each project creates a subdirectory: `$PROJECTS_BASE/<session-name>/`

---

## 🧠 Design Philosophy

The toolkit is built on several core principles that guide every design decision:

### 1. Convention Over Configuration

Sensible defaults mean zero configuration required:

- **Project directories**: Auto-detected based on OS (`~/Developer` on macOS, `/data/projects` on Linux)
- **Pane counts**: Reasonable defaults (10 panes, 2+2 agents)
- **Layouts**: Tiled by default for optimal visibility
- **No config files**: Everything works out of the box

Override when needed via environment variables—but you shouldn't need to.

### 2. Idempotency Everywhere

Every operation is safe to repeat:

```bash
# Run install 10 times—same result
./add_useful_tmux_commands_to_zshrc.sh
./add_useful_tmux_commands_to_zshrc.sh
./add_useful_tmux_commands_to_zshrc.sh  # Still works, no duplicates

# Create session twice—no error
sat myproject 3 3
sat myproject 3 3  # "Session already exists" - attaches instead
```

This eliminates "did I already run this?" anxiety.

### 3. Progressive Disclosure

Simple tasks stay simple; complexity is opt-in:

| User Need | Simple Way | Power User Way |
|-----------|------------|----------------|
| Start agents | `qps myproject 2 2` | `sat myproject 4 4 2` with custom counts |
| Send command | `bp myproject all "task"` | `sct --cc -s myproject "task"` with filters |
| Kill session | `knt myproject` | `knt -f myproject` to skip confirmation |

### 4. Fail-Safe Defaults

Destructive operations require confirmation:

```bash
knt myproject
# Output: Kill session 'myproject' with 6 pane(s)? [y/N]:

# Directory creation requires confirmation too:
sat newproject 3 3
# Output: Directory not found: ~/Developer/newproject
#         Create it? [y/N]:
```

Force flags (`-f`) exist for scripting, but interactive use is protected.

### 5. Transparency

The toolkit never hides what it's doing:

```bash
sat myproject 3 2 1
# Output:
# Creating session 'myproject' in ~/Developer/myproject...
# Creating 5 pane(s) (1 -> 6)...
# Launching agents: 3x cc, 2x cod, 1x gmi...
# ✓ Launched 6 agent(s)
```

Every action is logged. No magic.

### Why Zsh Only?

The toolkit requires zsh (not bash) because it leverages zsh-specific features:

| Feature | Zsh Syntax | Bash Equivalent |
|---------|------------|-----------------|
| Array from lines | `arr=(${(f)"$(cmd)"})` | `mapfile -t arr < <(cmd)` |
| Integer check | `[[ "$n" = <-> ]]` | `[[ "$n" =~ ^[0-9]+$ ]]` |
| Parameter expansion | `${var:-default}` | Same, but fewer flags |
| Completion system | `compdef` | `complete` (different API) |

Bash compatibility would require significant rewrites and lose elegance. If you're not using zsh yet, the installer offers to set up Oh My Zsh for you.

---

## 🔬 How It Works Internally

### Session Creation Flow

When you run `sat myproject 3 2 1`, here's exactly what happens:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. VALIDATION                                                   │
│    ├─ Check tmux is installed (offer to install if not)        │
│    ├─ Validate session name (no colons or periods)             │
│    └─ Verify agent counts are positive integers                │
├─────────────────────────────────────────────────────────────────┤
│ 2. DIRECTORY SETUP                                              │
│    ├─ Compute path: $PROJECTS_BASE/myproject                   │
│    ├─ Check if directory exists                                │
│    └─ Prompt to create if missing                              │
├─────────────────────────────────────────────────────────────────┤
│ 3. SESSION CREATION                                             │
│    ├─ tmux new-session -d -s "myproject" -c "$dir"             │
│    ├─ Determine first window index (respects base-index)       │
│    └─ Calculate required panes: 1 (user) + 3 + 2 + 1 = 7       │
├─────────────────────────────────────────────────────────────────┤
│ 4. PANE SPLITTING                                               │
│    ├─ For each additional pane needed:                         │
│    │   ├─ tmux split-window -t "$session:$win" -c "$dir"       │
│    │   └─ tmux select-layout -t "$session:$win" tiled          │
│    └─ Result: 7 equally-sized panes in tiled layout            │
├─────────────────────────────────────────────────────────────────┤
│ 5. AGENT SPAWNING                                               │
│    ├─ Get pane indices as array                                │
│    ├─ Skip pane[0] (user pane)                                 │
│    ├─ For each Claude agent (3x):                              │
│    │   ├─ tmux select-pane -T "myproject__cc_N"                │
│    │   └─ tmux send-keys "cd $dir && cc" Enter                 │
│    ├─ For each Codex agent (2x): same with "cod"               │
│    └─ For each Gemini agent (1x): same with "gmi"              │
├─────────────────────────────────────────────────────────────────┤
│ 6. ATTACHMENT                                                   │
│    ├─ If already in tmux: tmux switch-client -t "myproject"    │
│    └─ If not in tmux: tmux attach -t "myproject"               │
└─────────────────────────────────────────────────────────────────┘
```

### Pane Targeting Algorithm

The `--cc`, `--cod`, `--gmi` filters work by pattern matching on pane titles:

```bash
# 1. Get all panes with their IDs and titles
pane_info=$(tmux list-panes -s -t "$session" -F '#{pane_id}:#{pane_title}')
# Output:
# %0:zsh
# %1:myproject__cc_1
# %2:myproject__cc_2
# %3:myproject__cod_1
# ...

# 2. For each pane, check if title matches filter
for entry in $pane_info; do
    pane_id="${entry%%:*}"      # Extract %1
    pane_title="${entry#*:}"    # Extract myproject__cc_1

    # Pattern match: "__cc" matches "myproject__cc_1"
    if [[ "$pane_title" =~ "__cc" ]]; then
        tmux send-keys -t "$pane_id" "$command" Enter
    fi
done
```

The double-underscore (`__`) in pane names is intentional—it's unlikely to appear in project names, making pattern matching reliable.

### Window Index Detection

Tmux allows users to configure `base-index` (windows start at 0 or 1). The toolkit handles this dynamically:

```bash
_ntm_first_window() {
    local session="$1"
    # Ask tmux for actual window indices, take the first one
    tmux list-windows -t "$session" -F '#{window_index}' | head -1
}
```

This ensures commands work whether your tmux.conf has `set -g base-index 0` or `set -g base-index 1`.

### Marker-Based Installation

The installer injects code between markers for clean management:

```
┌─────────────────────────────────────────┐
│ ~/.zshrc BEFORE                         │
├─────────────────────────────────────────┤
│ # User's existing config                │
│ export PATH="$HOME/bin:$PATH"           │
│ alias ll='ls -la'                       │
└─────────────────────────────────────────┘
                    │
                    ▼ Install
┌─────────────────────────────────────────┐
│ ~/.zshrc AFTER                          │
├─────────────────────────────────────────┤
│ # User's existing config                │
│ export PATH="$HOME/bin:$PATH"           │
│ alias ll='ls -la'                       │
│                                         │
│ # === NAMED-TMUX-COMMANDS-START ===     │ ◄─ Marker
│ # ... 1000+ lines of functions ...      │
│ # === NAMED-TMUX-COMMANDS-END ===       │ ◄─ Marker
└─────────────────────────────────────────┘
                    │
                    ▼ Uninstall
┌─────────────────────────────────────────┐
│ ~/.zshrc RESTORED                       │
├─────────────────────────────────────────┤
│ # User's existing config                │
│ export PATH="$HOME/bin:$PATH"           │
│ alias ll='ls -la'                       │
└─────────────────────────────────────────┘
```

The `--force` reinstall:
1. Backs up current .zshrc
2. Removes old marker block with `sed`
3. Appends fresh marker block

---

## 🔧 Installer Details

### Safety Features

| Feature | Description |
|---------|-------------|
| **Idempotent** | Safe to run multiple times; checks for existing installation |
| **Backup** | Creates timestamped backup before any modification |
| **Markers** | Uses start/end markers for clean block management |
| **Cross-platform** | Handles macOS and Linux `sed` differences |

### Command-Line Options

```bash
./add_useful_tmux_commands_to_zshrc.sh [OPTIONS]

Options:
  -f, --force      Force reinstall (remove existing and add fresh)
  -u, --uninstall  Remove the commands from ~/.zshrc
  -h, --help       Show help message
```

### Auto-Install Capabilities

**tmux Installation:**

When tmux is not found, the toolkit offers to install it automatically:

| Platform | Package Manager | Command |
|----------|-----------------|---------|
| macOS | Homebrew | `brew install tmux` |
| Debian/Ubuntu | apt | `sudo apt install -y tmux` |
| Fedora | dnf | `sudo dnf install -y tmux` |
| CentOS/RHEL | yum | `sudo yum install -y tmux` |
| Arch | pacman | `sudo pacman -Sy --noconfirm tmux` |
| openSUSE | zypper | `sudo zypper install -y tmux` |
| Alpine | apk | `sudo apk add tmux` |

**Oh My Zsh + Powerlevel10k:**

If `~/.zshrc` doesn't exist:
1. Prompts to install Oh My Zsh
2. Automatically installs Powerlevel10k theme
3. Disables the p10k configuration wizard for instant setup

---

## ⚙️ Configuration & Customization

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECTS_BASE` | `~/Developer` (macOS) or `/data/projects` (Linux) | Base directory for all projects |
| `ZSH` | `~/.oh-my-zsh` | Oh My Zsh installation directory |
| `ZSH_CUSTOM` | `$ZSH/custom` | Custom plugins/themes directory |
| `LANG` | `en_US.UTF-8` | Locale (set by toolkit if unset) |
| `LC_ALL` | `en_US.UTF-8` | Locale override |

### Customizing Project Directory

**Per-session override:**

```bash
PROJECTS_BASE=/home/user/work sat myapi 3 3
```

**Permanent override in `.zshrc`:**

```bash
# Add BEFORE the NAMED-TMUX-COMMANDS block, or after the END marker
export PROJECTS_BASE="$HOME/code"
```

### Customizing Agent Aliases

The default aliases can be overridden by redefining them **after** the toolkit block in your `.zshrc`:

```bash
# Add after # === NAMED-TMUX-COMMANDS-END === marker:

# Use a different Claude model
alias cc='claude --model claude-sonnet-4'

# Add custom Codex flags
alias cod='codex -m o3 --approval-mode full-auto'

# Gemini with specific project
alias gmi='gemini --sandbox'
```

### Extending with Custom Functions

Build your own workflows on top of the toolkit:

```bash
# Add to .zshrc after the toolkit block:

# Quick prototype: create project, spawn agents, open in VS Code
proto() {
    local name="$1"
    qps "$name" 2 2 0
    code "$PROJECTS_BASE/$name"
}

# Morning routine: start all active projects
morning() {
    for project in api frontend ml-pipeline; do
        sat "$project" 2 2 0 &
    done
    wait
    echo "All projects started!"
}

# Quick status check across all sessions
status-all() {
    for session in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
        echo "=== $session ==="
        snt "$session"
    done
}

# Archive all outputs before EOD
eod() {
    local date=$(date +%Y-%m-%d)
    for session in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
        sso "$session" "$HOME/agent-logs/$date"
    done
    echo "All outputs saved to ~/agent-logs/$date"
}
```

### Tmux Configuration Tips

Add these to your `~/.tmux.conf` for better agent management:

```bash
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
```

Reload with: `tmux source-file ~/.tmux.conf`

---

## 📊 Typical Workflow

### Starting a New Project

```bash
# 1. Check if agent CLIs are installed
cad

# 2. Create project with agents
qps myapi 3 2    # 3 Claude + 2 Codex

# 3. You're now attached to the session with 5 agents + 1 user pane
```

### During Development

```bash
# Send task to all Claude agents
bp myapi cc "implement the /users endpoint with full CRUD operations"

# Send different task to Codex agents
bp myapi cod "write comprehensive unit tests for the users module"

# Check status
snt myapi

# Zoom to a specific agent to see details
znt myapi cc

# View all panes
vnt myapi
```

### Scaling Up/Down

```bash
# Need more Claude agents? Add 2 more
ant myapi 2 0 0

# Interrupt all agents to give new instructions
int myapi

# Send new prompt to all
bp myapi all "stop current work and focus on fixing the CI pipeline"
```

### Saving Work

```bash
# Save all agent outputs before ending session
sso myapi ~/logs/myapi

# Or copy specific pane output
cpo myapi 3 2000    # 2000 lines from pane 3
```

### Ending Session

```bash
# Detach (agents keep running)
# Press: Ctrl+B, then D

# Later, reattach
rnt myapi

# When done, kill session
knt -f myapi
```

---

## 🎯 Multi-Agent Coordination Strategies

Different problems call for different agent orchestration patterns. Here are proven strategies:

### Strategy 1: Divide and Conquer

Assign different aspects of a task to different agent types based on their strengths:

```bash
# Start with architecture (Claude excels at high-level design)
bp myproject cc "design the database schema for user management with roles and permissions"

# Wait for design, then implementation (Codex for code generation)
bp myproject cod "implement the User and Role models based on docs/schema.md"

# Finally, testing (Gemini for comprehensive test coverage)
bp myproject gmi "write unit and integration tests for the User and Role models"
```

**Best for:** Large features with distinct phases (design → implement → test)

### Strategy 2: Competitive Comparison

Have multiple agents solve the same problem independently, then compare approaches:

```bash
# Same prompt to all agents
bp myproject all "implement a rate limiter middleware that allows 100 requests per minute per IP"

# View all panes side-by-side
vnt myproject

# Compare implementations, pick the best one (or combine ideas)
```

**Best for:** Problems with multiple valid solutions, learning different approaches

### Strategy 3: Specialist Teams

Group agents by specialty within a session:

```bash
# Create session with specialists
sat myproject 2 2 2  # 2 Claude, 2 Codex, 2 Gemini

# Claude pair: one for frontend, one for backend
sct --cc myproject "Agent 1: focus on React components. Agent 2: focus on API endpoints."

# Codex pair: one for features, one for refactoring
sct --cod myproject "Agent 1: implement new features. Agent 2: optimize existing code."

# Gemini pair: one for unit tests, one for integration tests
sct --gmi myproject "Agent 1: write unit tests. Agent 2: write integration tests."
```

**Best for:** Large projects with multiple concerns

### Strategy 4: Pipeline Processing

Chain agents in a pipeline where each builds on the previous:

```bash
# Step 1: Claude designs
bp myproject cc "design a REST API for task management with CRUD operations"

# Save output for next agent
cpo myproject 1 > /tmp/api-design.md

# Step 2: Codex implements based on design
bp myproject cod "implement the API from /tmp/api-design.md using Express.js"

# Step 3: Gemini reviews and tests
bp myproject gmi "review src/api/*.ts for bugs, then write tests"
```

**Best for:** Complex tasks requiring sequential expertise

### Strategy 5: Parallel Exploration

Explore multiple solution paths simultaneously:

```bash
# 4 Claude agents, each tries a different approach
sat myproject 4 0 0

# Manually send different prompts to each pane
# Pane 1: "implement auth using JWT"
# Pane 2: "implement auth using sessions"
# Pane 3: "implement auth using OAuth"
# Pane 4: "implement auth using Passport.js"

# Compare results
vnt myproject
```

**Best for:** R&D, evaluating multiple libraries/approaches

### Strategy 6: Review Pipeline

Use agents to review each other's work:

```bash
# Implementation
bp myproject cc "implement feature X with full error handling"

# Wait for completion, then peer review
bp myproject cod "review the code Claude just wrote in src/features/x.ts - look for bugs, security issues, and improvements"

# Final validation
bp myproject gmi "write tests that would catch the bugs mentioned in the review"
```

**Best for:** Quality assurance, catching edge cases

### Strategy 7: Rubber Duck Escalation

Start simple, escalate when stuck:

```bash
# Start with one Claude agent
sat myproject 1 0 0

# If stuck, add more perspectives
ant myproject 1 1 0  # Add another Claude and a Codex

# Still stuck? More agents
ant myproject 0 0 1  # Add Gemini for fresh perspective

# Broadcast the problem to all
bp myproject all "I'm stuck on X. Here's what I've tried: Y. What am I missing?"
```

**Best for:** Debugging, breaking through blockers

---

## 🔗 Integration Examples

### Git Hooks

**Pre-commit: Save Agent Context**

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Save agent outputs before each commit for audit trail
SESSION=$(basename "$(pwd)")
if tmux has-session -t "$SESSION" 2>/dev/null; then
    mkdir -p .agent-logs
    # Source zshrc to get the function
    zsh -c "source ~/.zshrc && sso $SESSION .agent-logs" 2>/dev/null
fi
```

**Post-checkout: Notify Agents**

```bash
#!/bin/bash
# .git/hooks/post-checkout

SESSION=$(basename "$(pwd)")
BRANCH=$(git branch --show-current)

if tmux has-session -t "$SESSION" 2>/dev/null; then
    zsh -c "source ~/.zshrc && bp $SESSION all 'Git branch changed to: $BRANCH. Review any new files.'" 2>/dev/null
fi
```

### Shell Scripts

**Automated Project Bootstrap:**

```bash
#!/bin/zsh
# bootstrap-microservices.zsh
source ~/.zshrc

services=(auth users products orders notifications)

for svc in "${services[@]}"; do
    echo "Setting up $svc service..."

    # Create project with agents
    qps "${svc}-service" 2 1 0

    # Give initial context
    bp "${svc}-service" cc "You are working on the $svc microservice.
        Read the existing code and suggest improvements."

    # Detach to continue with next service
    tmux detach-client 2>/dev/null
done

echo "Started ${#services[@]} microservice projects"
echo "Use 'rnt <service>-service' to attach to any of them"
```

**Batch Status Report:**

```bash
#!/bin/zsh
# daily-status.zsh
source ~/.zshrc

echo "=== Daily Agent Status Report ===" > /tmp/status-report.txt
echo "Generated: $(date)" >> /tmp/status-report.txt
echo "" >> /tmp/status-report.txt

for session in $(tmux list-sessions -F '#{session_name}' 2>/dev/null); do
    echo "## $session" >> /tmp/status-report.txt
    snt "$session" >> /tmp/status-report.txt
    echo "" >> /tmp/status-report.txt
done

cat /tmp/status-report.txt
```

### Cron Jobs

**Hourly Output Backup:**

```bash
# Add to crontab: crontab -e
0 * * * * /bin/zsh -c 'source ~/.zshrc; for s in $(tmux list-sessions -F "#{session_name}" 2>/dev/null); do sso "$s" "$HOME/agent-backups/hourly"; done'
```

**Daily Session Cleanup:**

```bash
# Kill sessions older than 7 days (based on directory mtime)
0 2 * * * /bin/zsh -c 'source ~/.zshrc; for s in $(tmux list-sessions -F "#{session_name}" 2>/dev/null); do dir="$PROJECTS_BASE/$s"; if [[ -d "$dir" ]] && [[ $(find "$dir" -maxdepth 0 -mtime +7) ]]; then knt -f "$s"; fi; done'
```

### CI/CD Integration

**PR Review Bot:**

```bash
#!/bin/zsh
# review-pr.zsh - Run as part of CI pipeline
source ~/.zshrc

PR_NUMBER=$1
REPO_PATH=$2

cd "$REPO_PATH"

# Create review session
PROJECTS_BASE=/tmp sat "pr-review-$PR_NUMBER" 1 0 0

# Get changed files
CHANGED_FILES=$(git diff --name-only origin/main)

# Send review prompt
bp "pr-review-$PR_NUMBER" cc "Review this PR for:
1. Security vulnerabilities
2. Performance issues
3. Code style violations
4. Missing error handling

Changed files:
$CHANGED_FILES

Provide a structured review with severity ratings."

# Wait for analysis (adjust timeout as needed)
sleep 300

# Capture output
cpo "pr-review-$PR_NUMBER" 1 5000 > "/tmp/pr-$PR_NUMBER-review.md"

# Cleanup
knt -f "pr-review-$PR_NUMBER"

# Output review
cat "/tmp/pr-$PR_NUMBER-review.md"
```

### VS Code Integration

**tasks.json for VS Code:**

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start Agents",
            "type": "shell",
            "command": "zsh -c 'source ~/.zshrc && sat ${workspaceFolderBasename} 2 2 0'",
            "problemMatcher": []
        },
        {
            "label": "Broadcast to Claude",
            "type": "shell",
            "command": "zsh -c 'source ~/.zshrc && bp ${workspaceFolderBasename} cc \"${input:prompt}\"'",
            "problemMatcher": []
        },
        {
            "label": "View Agent Status",
            "type": "shell",
            "command": "zsh -c 'source ~/.zshrc && snt ${workspaceFolderBasename}'",
            "problemMatcher": []
        }
    ],
    "inputs": [
        {
            "id": "prompt",
            "type": "promptString",
            "description": "Enter prompt for agents"
        }
    ]
}
```

### Alfred/Raycast Workflows

**Quick Agent Launcher (Alfred):**

```bash
# Script filter that lists available sessions
tmux list-sessions -F '#{session_name}' 2>/dev/null | while read session; do
    echo "{\"title\": \"$session\", \"arg\": \"$session\"}"
done | jq -s '{items: .}'
```

**Action script:**

```bash
# Attach to selected session in new Terminal window
osascript -e "tell application \"Terminal\" to do script \"tmux attach -t $1\""
```

---

## ⌨️ Tmux Essentials

If you're new to tmux, here are the key bindings (default prefix is `Ctrl+B`):

| Keys | Action |
|------|--------|
| `Ctrl+B, D` | Detach from session |
| `Ctrl+B, [` | Enter scroll/copy mode |
| `Ctrl+B, z` | Toggle zoom on current pane |
| `Ctrl+B, Arrow` | Navigate between panes |
| `Ctrl+B, c` | Create new window |
| `Ctrl+B, ,` | Rename current window |
| `q` | Exit scroll mode |

---

## 🔍 Tab Completion

The toolkit registers zsh completions for session names. Type a command and press `Tab` to autocomplete:

```bash
rnt sli<Tab>    # Completes to: rnt myproject
knt my<Tab>     # Completes to: knt myproject
```

Completion works for:
- `rnt`, `vnt`, `snt`, `knt`
- `sct`, `cpo`, `sso`, `znt`
- `ant`, `int`, `bp`

---

## 🐛 Troubleshooting

### "tmux not found"

The toolkit will offer to install tmux automatically. If that fails:

```bash
# macOS
brew install tmux

# Ubuntu/Debian
sudo apt install tmux

# Fedora
sudo dnf install tmux
```

### "Session already exists"

Use `--force` with `knt` or attach to the existing session:

```bash
rnt myproject    # Attach to existing
# OR
knt -f myproject && sat myproject 3 3   # Kill and recreate
```

### Panes not tiling correctly

Force a re-tile:

```bash
vnt myproject
```

### Agent not responding

Interrupt and restart:

```bash
int myproject
bp myproject cc "continue where you left off"
```

### "Directory not found"

The toolkit prompts to create missing directories. Answer `y` to create, or create manually:

```bash
mkdir -p ~/Developer/myproject
```

### Commands not found after install

Reload your shell configuration:

```bash
source ~/.zshrc
```

Or start a new terminal session.

---

## ❓ Frequently Asked Questions

### General

**Q: Does this work with bash?**

A: No, the toolkit requires zsh due to its use of zsh-specific features (array handling, pattern matching, completion system). Consider switching to zsh—the installer even offers to set up Oh My Zsh for you.

**Q: Can I use this over SSH?**

A: Yes! This is one of the primary use cases. Tmux sessions persist on the server:
1. SSH to your server
2. Start agents: `sat myproject 3 3`
3. Detach: `Ctrl+B, D`
4. Disconnect SSH
5. Later: SSH back, run `rnt myproject`

All agents continue running while you're disconnected.

**Q: How many agents can I run simultaneously?**

A: Practically limited by:
- **Memory**: Each agent CLI uses 100-500MB RAM
- **API rate limits**: Provider-specific throttling
- **Screen real estate**: Beyond ~20 panes, they become too small

The toolkit has successfully managed 20+ panes on a 32GB machine.

**Q: Does this work on Windows?**

A: Not natively. Options:
- **WSL2**: Install zsh in WSL2, then use the toolkit normally
- **Git Bash**: Won't work (bash, not zsh)
- **Cygwin**: Might work with zsh installed (untested)

### Agents

**Q: Why are agents run with "dangerous" flags?**

A: The flags (`--dangerously-skip-permissions`, `--yolo`, etc.) allow agents to work autonomously without confirmation prompts for every action. This is intentional for productivity—you're trading safety guardrails for speed. Only use in development environments where agents can't cause real damage.

**Q: Can I add support for other AI CLIs (Aider, Cursor, etc.)?**

A: Yes! Add a new alias after the toolkit block:

```bash
# In ~/.zshrc after the END marker:
alias aid='aider --yes-always'
alias cur='cursor --accept-all'
```

Then use them manually in panes, or create custom spawn functions.

**Q: Do agents share context with each other?**

A: No, each agent runs independently in its own pane. They:
- ✅ Can see the same filesystem
- ✅ Can read each other's file changes
- ❌ Cannot communicate directly
- ❌ Don't share conversation history

Use broadcast (`bp`) to coordinate, or have them write to shared files.

**Q: Can I give different prompts to agents of the same type?**

A: Yes, but not with `bp` (which broadcasts the same prompt). Options:
1. **Manual**: Navigate to each pane and type different prompts
2. **Indexed commands**: Use `tmux send-keys` directly to specific panes
3. **Custom function**: Write a wrapper that sends different prompts to different pane indices

### Sessions

**Q: What happens if an agent crashes?**

A: The pane stays open with a shell prompt. You can:
- Restart: Type the agent alias (`cc`, `cod`, `gmi`) in that pane
- Check what happened: Scroll up with `Ctrl+B, [`
- Replace: The pane title remains, so filters still work

**Q: Can I rename a session?**

A: Yes, using tmux directly:

```bash
tmux rename-session -t oldname newname
```

Note: This doesn't rename the project directory.

**Q: How do I move a pane to a different session?**

A: Use tmux commands:

```bash
# Move pane to existing session
tmux move-pane -t othersession:

# Or break into new window
tmux break-pane -t mysession:0.2
```

### Troubleshooting

**Q: Why do pane titles show `zsh` instead of agent names?**

A: Pane titles are set when agents spawn. If an agent exits (crashes, `/exit`, `Ctrl+D`), the pane reverts to showing the shell. Solutions:
- Restart the agent: type `cc`/`cod`/`gmi` in the pane
- Re-run spawn: `ant myproject 0 0 1` to add fresh agents

**Q: How do I increase scrollback history?**

A: Add to `~/.tmux.conf`:

```bash
set-option -g history-limit 50000  # Default is 2000
```

Then reload: `tmux source-file ~/.tmux.conf`

**Q: Why does `bp` send to wrong panes?**

A: The filter matches pane titles containing `__cc`, `__cod`, or `__gmi`. If your project name contains these patterns (e.g., `decode_project`), it might match incorrectly. Solution: avoid these patterns in project names.

---

## 🔒 Security Considerations

The agent aliases include flags that bypass safety prompts:

| Alias | Flag | Purpose |
|-------|------|---------|
| `cc` | `--dangerously-skip-permissions` | Allows Claude to make changes without confirmation |
| `cod` | `--dangerously-bypass-approvals-and-sandbox` | Allows Codex full system access |
| `gmi` | `--yolo` | Allows Gemini to execute without confirmation |

**These are intentional for productivity** but mean the agents can:
- Read/write any files
- Execute system commands
- Make network requests

**Recommendations:**
- Only use in development environments
- Review agent outputs before committing code
- Don't use with sensitive credentials in scope
- Consider sandboxed environments for untrusted projects

---

## 📈 Performance Considerations

### Memory Usage

| Component | Typical RAM | Notes |
|-----------|-------------|-------|
| tmux server | 5-10 MB | Single process for all sessions |
| Per tmux pane | 1-2 MB | Minimal overhead |
| Claude CLI (`cc`) | 200-400 MB | Node.js process |
| Codex CLI (`cod`) | 150-300 MB | Varies by model |
| Gemini CLI (`gmi`) | 100-200 MB | Lighter footprint |

**Rough formula for planning:**

```
Total RAM = 10 + (panes × 2) + (claude × 300) + (codex × 200) + (gemini × 150) MB
```

**Example:** Session with 3 Claude + 2 Codex + 1 Gemini + 1 user pane:
```
10 + (7 × 2) + (3 × 300) + (2 × 200) + (1 × 150) = 1,474 MB ≈ 1.5 GB
```

### Scaling Limits

| Metric | Practical Limit | Notes |
|--------|-----------------|-------|
| Panes per window | ~16-20 | Beyond this, panes become too small to read |
| Windows per session | Unlimited | Use `Ctrl+B, c` to create additional windows |
| Sessions | Unlimited | Each session is independent |
| Scrollback lines | 2,000 (default) | Increase with `set -g history-limit 50000` |
| Concurrent API calls | Provider-limited | Claude: ~10/min, Codex: varies, Gemini: varies |

### Optimization Tips

1. **Close idle agents**
   ```bash
   # Check which agents are idle
   snt myproject

   # Exit specific agents you don't need
   sct --gmi myproject "/exit"
   ```

2. **Use multiple windows instead of many panes**
   ```bash
   # Create additional windows for organization
   tmux new-window -t myproject -n "tests"
   tmux new-window -t myproject -n "docs"
   ```

3. **Save outputs before scrollback is lost**
   ```bash
   # Periodic saves
   sso myproject ~/logs

   # Or copy critical output immediately
   cpo myproject 3 5000 > important-output.txt
   ```

4. **Start minimal, scale up**
   ```bash
   # Start with just what you need
   sat myproject 1 0 0

   # Add more only when needed
   ant myproject 1 1 0
   ```

### Network Considerations

When running on remote servers:

- **Latency**: Agent responses may feel slower due to network round-trip
- **Bandwidth**: Large code outputs can be slow on poor connections
- **Disconnection**: Use `mosh` instead of `ssh` for unstable connections
- **Timeouts**: Set `ServerAliveInterval 60` in `~/.ssh/config` to prevent drops

---

## 🆚 Comparison with Alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **This Toolkit** | Purpose-built for AI agents, named panes, broadcast prompts, session persistence | Requires zsh, tmux learning curve |
| **Multiple Terminal Windows** | Simple, no setup required | No persistence, window chaos, no orchestration |
| **Terminal Tabs** | Built into most terminals | No broadcasting, limited visibility, no persistence |
| **GNU Screen** | Available everywhere, simple | Fewer features than tmux, no named panes, dated |
| **Tmux (manual)** | Full control, no dependencies | Verbose commands, no agent-specific features |
| **VS Code Terminals** | IDE integration, familiar UI | No persistence across sessions, no broadcasting |
| **iTerm2 (macOS)** | Native, good split panes | macOS only, no persistence, no orchestration |
| **Docker Containers** | Full isolation per agent | Heavyweight, complex setup, resource overhead |
| **Background processes** | Lightweight | No visibility, hard to interact, log management |

### When to Use This Toolkit

✅ **Good fit:**
- Running multiple AI agents in parallel
- Remote development over SSH
- Projects requiring persistent sessions
- Workflows needing broadcast prompts
- Developers comfortable with CLI

❌ **Consider alternatives:**
- Single-agent workflows (just use the CLI directly)
- GUI-preferred workflows (use IDE integration)
- Non-zsh environments
- Windows without WSL (tmux isn't native)

### Migration from Manual Tmux

If you're already using tmux manually, here's how the toolkit improves your workflow:

| Manual Command | Toolkit Equivalent |
|----------------|-------------------|
| `tmux new -s proj -c ~/proj` | `cnt proj` |
| `tmux split-window` (×10) | Automatic with pane count |
| `tmux select-pane -T name` (×10) | Automatic with `__cc_1` pattern |
| `for pane in ...; do tmux send-keys ...; done` | `bp proj all "prompt"` |
| `tmux list-panes -F ...` + parsing | `snt proj` |
| `tmux capture-pane` + clipboard | `cpo proj 2` |

---

## 📚 Shell Scripting Techniques

The toolkit demonstrates several advanced shell scripting patterns that may be educational:

### 1. Zsh Array Handling

```bash
# Split command output into array by newlines
local -a pane_ids
pane_ids=(${(f)"$(tmux list-panes -F '#{pane_index}')"})

# The ${(f)...} splits string on newlines (zsh parameter expansion flag)
# Result: pane_ids=("0" "1" "2" "3" ...)
```

### 2. Integer Validation Without External Commands

```bash
# Zsh glob pattern for integers
if [[ "$panes" = <-> ]]; then
    echo "Valid positive integer"
fi

# <-> matches any sequence of digits
# <1-100> would match 1 to 100 only
# No need for: [[ "$panes" =~ ^[0-9]+$ ]]
```

### 3. Cross-Platform Compatibility

```bash
# macOS sed requires '' after -i, Linux doesn't
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' 's/old/new/' file
else
    sed -i 's/old/new/' file
fi
```

### 4. Heredoc with Variable Protection

```bash
# Single-quoted delimiter prevents variable expansion
cat >> file << 'EOF'
$HOME will be literal $HOME, not expanded
Variables like $PATH stay as-is
EOF

# Unquoted delimiter allows expansion
cat >> file << EOF
$HOME expands to /Users/yourname
EOF
```

### 5. Safe Parameter Expansion

```bash
# Default value if unset or empty
local base="${PROJECTS_BASE:-$HOME/projects}"

# Check if variable is set (even if empty)
if [[ -n "${TMUX:-}" ]]; then
    # We're inside tmux
fi

# The :- means "use default if unset or empty"
# The - alone means "use default only if unset"
```

### 6. Error Handling Patterns

```bash
# Capture output AND check exit status in one line
local first_win
if ! first_win=$(_ntm_first_window "$session"); then
    echo "error: could not determine first window" >&2
    return 1
fi

# The if ! var=$(cmd) pattern:
# 1. Runs cmd
# 2. Captures stdout into var
# 3. Checks exit status with if !
```

### 7. Robust String Parsing

```bash
# Parse "id:title" format safely
local entry="pane_1:myproject__cc_1"
local pane_id="${entry%%:*}"     # "pane_1" (remove longest :* from end)
local pane_title="${entry#*:}"   # "myproject__cc_1" (remove shortest *: from start)

# %% and ## are greedy, % and # are non-greedy
```

### 8. Dynamic Completion Registration

```bash
# Check if completion system is available before registering
if (( $+functions[compdef] )); then
    compdef _ntm_complete_sessions reconnect-to-named-tmux
fi

# $+functions[name] returns 1 if function exists, 0 otherwise
# Prevents errors on systems without zsh completion
```

### 9. Argument Parsing Loop

```bash
# Flexible flag parsing that works in any position
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            force=true
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            return 1
            ;;
        *)
            # Non-flag argument
            session="$1"
            shift
            ;;
    esac
done
```

### 10. Safe Array Iteration

```bash
# Iterate over array with index (zsh arrays are 1-indexed)
local -a items=("a" "b" "c")
for ((i=1; i<=${#items[@]}; i++)); do
    echo "Item $i: ${items[$i]}"
done

# Or with foreach
for item in "${items[@]}"; do
    echo "Item: $item"
done
```

These patterns combine to create robust, maintainable shell scripts that handle edge cases gracefully.

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [tmux](https://github.com/tmux/tmux) - The terminal multiplexer that makes this possible
- [Oh My Zsh](https://ohmyz.sh/) - For making zsh delightful
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - For the beautiful prompt
- [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [Gemini CLI](https://ai.google.dev/) - The AI agents this toolkit orchestrates
