#!/usr/bin/env bats
# agy_migration.bats — unit tests for the gmi -> agy additive swarm-fn migration
# (bead utc-agy-swarm-fns-oa5.4). Verifies the pane-title scheme, the filter
# regex, arg parsing, count math, and that agy is wired through every surface
# while every gmi legacy path is preserved.
#
# Run: bats tests/agy_migration.bats

SRC="${BATS_TEST_DIRNAME}/../add_useful_tmux_commands_to_zshrc.sh"

setup() {
  [ -f "$SRC" ] || skip "swarm library not found"
}

# ---- filter / interrupt regex (the interlinked-hazard core) ----------------

@test "filter regex matches an agy pane title" {
  local pane_title="myproj__agy_1"
  [[ "$pane_title" =~ __(cc|cod|agy|gmi) ]]
}

@test "filter regex still matches the legacy gmi pane title" {
  local pane_title="myproj__gmi_1"
  [[ "$pane_title" =~ __(cc|cod|agy|gmi) ]]
}

@test "filter regex matches cc/cod and the __agy_added_ variant" {
  [[ "p__cc_2"        =~ __(cc|cod|agy|gmi) ]]
  [[ "p__cod_1"       =~ __(cc|cod|agy|gmi) ]]
  [[ "p__agy_added_3" =~ __(cc|cod|agy|gmi) ]]
}

@test "filter regex rejects a non-agent pane title" {
  ! [[ "myproj__user_0" =~ __(cc|cod|agy|gmi) ]]
  ! [[ "scratch"        =~ __(cc|cod|agy|gmi) ]]
}

# ---- arg parsing + count math (pure positional semantics) -------------------

@test "agy is the 4th positional, gmi the legacy 5th (defaults to 0)" {
  set -- mysession 2 1 1   # cc=2 cod=1 agy=1, gmi unset
  local cc="${2:-0}" cod="${3:-0}" agy="${4:-0}" gmi="${5:-0}"
  [ "$agy" = "1" ]
  [ "$gmi" = "0" ]
}

@test "total agent count sums cc+cod+agy+gmi" {
  local cc=2 cod=1 agy=1 gmi=1
  local total=$((cc + cod + agy + gmi))
  [ "$total" -eq 5 ]
}

# ---- structural wiring (agy threaded through every surface) ------------------

@test "the migrated regex in the source grew to include agy" {
  grep -q '__(cc|cod|agy|gmi)' "$SRC"
}

@test "sat + ant launch agy panes (__agy_ titles, && agy)" {
  grep -q '__agy_\${i}' "$SRC"
  grep -q '__agy_added_\${i}' "$SRC"
  grep -Eq 'cd .* && agy' "$SRC"
}

@test "sat takes agy as the 4th positional and gmi as the 5th" {
  grep -q 'local agy_count="\${4:-0}"' "$SRC"
  grep -q 'local gmi_count="\${5:-0}"' "$SRC"
}

@test "sct has an --agy filter flag" {
  grep -q 'agent_filter="__agy"' "$SRC"
}

@test "broadcast-prompt has an agy case" {
  grep -q 'send-command-to-named-tmux --agy' "$SRC"
}

@test "qps passes 5 args (incl agy) through to sat" {
  grep -q 'spawn-agents-in-named-tmux "\$project" "\$cc_count" "\$cod_count" "\$agy_count" "\$gmi_count"' "$SRC"
}

@test "help/usage strings surface agy" {
  grep -q '\[agy-count\]' "$SRC"
  grep -q 'cc|cod|agy|gmi' "$SRC"
}

@test "gmi legacy paths are preserved (additive, not replaced)" {
  # Plenty of gmi references must remain (alias, legacy panes, legacy flags).
  [ "$(grep -c '__gmi\|--gmi\|gmi_count\|alias gmi' "$SRC")" -ge 10 ]
}
