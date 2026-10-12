#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d)"
TMUX_BIN="$(command -v tmux)"
cleanup() {
  "$TMUX_BIN" -S "$scratch/socket" kill-server 2>/dev/null || true
  rm -rf "$scratch"
}
trap cleanup EXIT
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
unset TMUX TMUX_PANE_METADATA_FILE
mkdir -p "$HOME/.config/ghostty"
cp -R "$REPO_DIR/config/tmux" "$HOME/.tmux"
rm -rf "$HOME/.tmux/plugins"
cp "$REPO_DIR/config/tmux.conf" "$HOME/.tmux.conf"
cp "$REPO_DIR/config/ghostty/pane-dimming.conf" "$HOME/.config/ghostty/"
t() { "$TMUX_BIN" -S "$scratch/socket" "$@"; }
DOTFILES_GHOSTTY_PANE_DIMMING=0 t -f "$HOME/.tmux.conf" new-session -d -s test 'sleep 120'
[[ "$(t show-option -gqv @dotfiles-pane-dimming)" == off ]]
t set-hook -g 'client-attached[42]' 'display-message unrelated'
t set-environment -g DOTFILES_GHOSTTY_PANE_DIMMING 1
t source-file "$HOME/.tmux.conf"
if [[ "$(t display-message -p '#{>=:#{version},3.7}')" == 1 ]]; then
  [[ "$(t show-option -gqv @dotfiles-pane-dimming)" == on ]]
  t show-hooks -g | grep -q 'client-attached\[90\]'
  if command -v uv >/dev/null 2>&1 && infocmp xterm-ghostty >/dev/null 2>&1; then
    uv run --no-project "$REPO_DIR/scripts/tests/test_tmux_client.py" "$scratch/socket"
  else
    echo 'SKIP: PTY cleanup check requires uv and xterm-ghostty terminfo'
  fi
  # Even with a flag and shader, Linux must not activate Mac-only dimming.
  mkdir -p "$scratch/bin"
  printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$scratch/bin/uname"
  cat > "$scratch/bin/tmux" <<'STUB'
#!/bin/sh
exec "$TMUX_TEST_BIN" -S "$TMUX_TEST_SOCKET" "$@"
STUB
  chmod +x "$scratch/bin/uname" "$scratch/bin/tmux"
  export TMUX_TEST_BIN="$TMUX_BIN" TMUX_TEST_SOCKET="$scratch/socket"
  PATH="$scratch/bin:$PATH" bash "$HOME/.tmux/bin/apply-pane-dimming"
  [[ "$(t show-option -gqv @dotfiles-pane-dimming)" == off ]]
fi
t set-environment -g DOTFILES_GHOSTTY_PANE_DIMMING 0
t source-file "$HOME/.tmux.conf"
[[ "$(t show-option -gqv @dotfiles-pane-dimming)" == off ]]
! t show-hooks -g | grep -q 'emit-pane-'
t show-hooks -g | grep -q 'client-attached\[42\]'
# Missing shader configuration must not activate hooks, even with the flag set.
rm "$HOME/.config/ghostty/pane-dimming.conf"
t set-environment -g DOTFILES_GHOSTTY_PANE_DIMMING 1
t source-file "$HOME/.tmux.conf"
[[ "$(t show-option -gqv @dotfiles-pane-dimming)" == off ]]
# TWM itself remains an optional worktree picker.
mkdir -p "$HOME/.tmux/plugins/tmux-worktree-manager/dist"
printf '#!/bin/sh\nexit 0\n' > "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm"
chmod +x "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm"
t source-file "$HOME/.tmux.conf"
t list-keys -T prefix | grep 'prefix W ' | grep -q worktrees
t list-keys -T prefix | grep 'prefix W ' | grep -q worktrees
rm "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm"
t source-file "$HOME/.tmux.conf"
! t list-keys -T prefix | grep 'prefix W ' | grep -q worktrees
printf 'PASS: isolated tmux, dimming off-on-off, unrelated hooks, optional TWM binding\n'
