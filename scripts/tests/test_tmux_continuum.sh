#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d)"
TMUX_BIN="$(command -v tmux)"
cleanup() {
  "$TMUX_BIN" -S "$scratch/host" kill-server 2>/dev/null || true
  "$TMUX_BIN" -S "$scratch/host.twm" kill-server 2>/dev/null || true
  rm -rf "$scratch"
}
trap cleanup EXIT
installed_plugins="$HOME/.tmux/plugins"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
unset TMUX TMUX_PLUGIN_MANAGER_PATH
mkdir -p "$HOME/.tmux/plugins/tmux-continuum/scripts" "$scratch/bin"
cp "$REPO_DIR/config/tmux.conf" "$HOME/.tmux.conf"
cp -R "$REPO_DIR/config/tmux/bin" "$HOME/.tmux/bin"
cp "$REPO_DIR/config/tmux/features.conf" "$HOME/.tmux/features.conf"
# The fixture stands in for the save callback, never a real session snapshot.
save_script="$HOME/.tmux/plugins/tmux-continuum/scripts/continuum_save.sh"
printf '#!/bin/sh\nexit 0\n' > "$save_script"
chmod +x "$save_script"
t() { "$TMUX_BIN" -S "$scratch/host" "$@"; }
h() { "$TMUX_BIN" -S "$scratch/host.twm" "$@"; }
t -f /dev/null new-session -d -s workspace 'sleep 120'
h -f /dev/null new-session -d -s popup -e TWM_POPUP=1 -e "TWM_HOST_SOCKET=$scratch/host" 'sleep 120'
export TEST_TMUX_BIN="$TMUX_BIN" TEST_SOCKET="$scratch/host"
TEST_HOST_PID="$(t display-message -p '#{pid}')"
TEST_HELPER_PID="$(h display-message -p '#{pid}')"
export TEST_HOST_PID TEST_HELPER_PID
# Route every script call to the isolated server. Explicit -S selects its helper.
cat > "$scratch/bin/tmux" <<'STUB'
#!/bin/bash
if [[ "${1:-}" == -S ]]; then exec "$TEST_TMUX_BIN" "$@"; fi
exec "$TEST_TMUX_BIN" -S "$TEST_SOCKET" "$@"
STUB
# Control process discovery so unrelated live servers cannot affect the test.
cat > "$scratch/bin/ps" <<'STUB'
#!/bin/bash
printf 'tmux %s\ntmux -S helper %s\n' "$TEST_HOST_PID" "$TEST_HELPER_PID"
if [[ "${TEST_OTHER_SERVER:-0}" == 1 ]]; then printf 'tmux: server 999999\n'; fi
STUB
chmod +x "$scratch/bin/"*
export PATH="$scratch/bin:$PATH"
t set-environment -g PATH "$PATH"
for name in TEST_TMUX_BIN TEST_SOCKET TEST_HOST_PID TEST_HELPER_PID; do
  t set-environment -g "$name" "${!name}"
done
reset_state() {
  t set-option -gu @continuum-save-last-timestamp
  t set-option -g status-right 'theme stays here'
}
reload() { t source-file "$HOME/.tmux.conf"; }
# Missing resurrect must leave the status and timestamps alone.
reset_state
reload
[[ -z "$(t show-option -gqv @continuum-save-last-timestamp)" ]]
t set-option -g @resurrect-save-script-path /fixture/save.sh
reset_state
reload
[[ -n "$(t show-option -gqv @continuum-save-last-timestamp)" ]]
[[ "$(t show-option -gqv status-right)" == "#($save_script)theme stays here" ]]
t set-option -g @continuum-save-last-timestamp 12345
reload
[[ "$(t show-option -gqv @continuum-save-last-timestamp)" == 12345 ]]
[[ "$(t show-option -gqv status-right)" == "#($save_script)theme stays here" ]]
# A real second workspace must still block initialization.
t set-environment -g TEST_OTHER_SERVER 1
reset_state
reload
[[ -z "$(t show-option -gqv @continuum-save-last-timestamp)" ]]
[[ "$(t show-option -gqv status-right)" == 'theme stays here' ]]
t set-environment -gu TEST_OTHER_SERVER
# Neither a foreign helper nor an unmarked workspace gets exempted.
h set-environment -t popup TWM_HOST_SOCKET /different/host
reset_state
reload
[[ -z "$(t show-option -gqv @continuum-save-last-timestamp)" ]]
h set-environment -t popup TWM_HOST_SOCKET "$scratch/host"
h new-session -d -s regular 'sleep 120'
reload
[[ -z "$(t show-option -gqv @continuum-save-last-timestamp)" ]]
# Continuum must be last so theme initialization cannot erase its callback.
last_plugin="$(grep '^set -g @plugin ' "$HOME/.tmux.conf" | tail -1)"
[[ "$last_plugin" == "set -g @plugin 'tmux-plugins/tmux-continuum'" ]]
printf 'PASS: continuum TWM exemption, workspace protection, reload safety, plugin order\n'
# When available, exercise the real TPM/theme/continuum chain too, not only the
# fallback adapter. All plugin writes and restores stay inside the temporary HOME.
if [[ -d "$installed_plugins/tpm" && -d "$installed_plugins/tmux-power" &&
      -d "$installed_plugins/tmux-continuum" && -d "$installed_plugins/tmux-resurrect" ]]; then
  h kill-session -t regular
  for plugin in tpm tmux-power tmux-continuum tmux-resurrect; do
    rm -rf "$HOME/.tmux/plugins/$plugin"
    cp -R "$installed_plugins/$plugin" "$HOME/.tmux/plugins/$plugin"
  done
  reset_state
  reload
  actual_status="$(t show-option -gqv status-right)"
  [[ "$actual_status" == *"#($save_script)"* ]]
  [[ "$actual_status" == *'#[fg='* ]]
  reload
  [[ "$(t show-option -gqv status-right)" == "$actual_status" ]]
  # Execute the installed callback with an isolated resurrect stand-in. This
  # verifies that the armed callback can actually request a save when due.
  cat > "$scratch/save-fixture" <<'STUB'
#!/bin/bash
[[ "$1" == quiet ]] || exit 1
touch "$HOME/save-called"
tmux wait-for -S continuum-saved
STUB
  chmod +x "$scratch/save-fixture"
  t set-option -g @resurrect-save-script-path "$scratch/save-fixture"
  t set-option -g @continuum-save-last-timestamp 0
  t run-shell -b "bash '$save_script'"
  t wait-for continuum-saved
  [[ -f "$HOME/save-called" ]]
  [[ "$(t show-option -gqv @continuum-save-last-timestamp)" -gt 0 ]]
  printf 'PASS: installed TPM, tmux-power and continuum integration; due save callback\n'
else
  printf 'SKIP: installed TPM/theme/continuum/resurrect required for plugin integration\n'
fi
