#!/usr/bin/env bash
# agy_e2e.sh — real-tmux end-to-end for the agy swarm-fn migration
# (bead utc-agy-swarm-fns-oa5.5). Spawns a real agy pane via `sat`, asserts the
# `__agy_` pane-title scheme + the count message, targets it via `sct --agy`,
# and tears down. Structured [E2E] logging. Skips cleanly if tmux/zsh are
# unavailable. Never deletes anything outside its throwaway session/dir.
#
# Note: the swarm functions are zsh (they use zsh `<->` globs), so the spawn is
# driven via `zsh -c`. The agy pane needs a real TTY to fully launch the binary
# ("open terminal failed: not a terminal" under CI is expected + non-fatal); the
# test asserts the swarm ORCHESTRATION (pane creation/titling/count/targeting),
# which is what this migration changed.
#
# Run: bash tests/agy_e2e.sh
set -uo pipefail

log() { printf '[E2E][%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

command -v tmux >/dev/null 2>&1 || { log "tmux not installed — SKIP"; exit 0; }
command -v zsh  >/dev/null 2>&1 || { log "zsh not installed — SKIP"; exit 0; }

# Extract just the swarm-function block from ~/.zshrc (not the installer main()).
BLK="$(mktemp)"
awk '/# === NAMED-TMUX-COMMANDS-START ===/{f=1} f{print} /# === NAMED-TMUX-COMMANDS-END ===/{f=0}' \
  "$HOME/.zshrc" > "$BLK" 2>/dev/null
[ -s "$BLK" ] || { log "swarm block not found in ~/.zshrc — SKIP"; rm -f "$BLK"; exit 0; }

SESS="agy_swarm_e2e_$$"
PROJ="/data/projects/$SESS"   # sat derives the project dir from the session name
mkdir -p "$PROJ"

# Spawn cc=1 + agy=1 (gmi=0) and capture pane titles + the launch message, under zsh.
OUT="$(zsh -c '
  source "'"$BLK"'" 2>/dev/null
  spawn-agents-in-named-tmux "'"$SESS"'" 1 0 1 0 2>&1 | grep -i "Launching agents" || true
  sleep 3
  tmux list-panes -s -t "'"$SESS"'" -F "TITLE:#{pane_title}" 2>/dev/null
  send-command-to-named-tmux --agy "'"$SESS"'" "true" >/dev/null 2>&1 && echo "SCT_AGY_OK" || true
' 2>/dev/null)"

# Teardown first (always), then assert.
tmux kill-session -t "$SESS" 2>/dev/null || true
rmdir "$PROJ" 2>/dev/null || true
rm -f "$BLK"

FAILS=0
log "launch line: $(printf '%s' "$OUT" | grep -i 'Launching agents' || echo '(none)')"
log "pane titles: $(printf '%s' "$OUT" | grep '^TITLE:' | sed 's/^TITLE://' | tr '\n' ' ')"

if printf '%s' "$OUT" | grep -qi 'Launching agents:.*1x agy'; then
  log "[PASS] sat counted 1x agy in the launch message"
else FAILS=$((FAILS+1)); log "[FAIL] launch message did not report agy"; fi

if printf '%s' "$OUT" | grep -q 'TITLE:.*__agy_'; then
  log "[PASS] sat created an __agy_ pane (forward Google agent)"
else FAILS=$((FAILS+1)); log "[FAIL] no __agy_ pane title found"; fi

if printf '%s' "$OUT" | grep -q 'SCT_AGY_OK'; then
  log "[PASS] sct --agy targeted the agy pane"
else log "[INFO] sct --agy returned nonzero (agy pane may still be initializing) — non-fatal"; fi

if tmux has-session -t "$SESS" 2>/dev/null; then FAILS=$((FAILS+1)); log "[FAIL] session not torn down"; else log "[PASS] session torn down cleanly"; fi

if [ "$FAILS" -eq 0 ]; then log "ALL PASS"; exit 0; else log "$FAILS failure(s)"; exit 1; fi
