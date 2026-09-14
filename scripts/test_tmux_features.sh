#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
TMUX_BIN="$(command -v tmux)"
cleanup() {
  "$TMUX_BIN" -S "$scratch/socket" kill-server 2>/dev/null || true
  rm -rf "$scratch"
}
trap cleanup EXIT
export HOME="$scratch/home"
unset TMUX
mkdir -p "$HOME/.config/ghostty"
cp -R "$REPO_DIR/config/.tmux" "$HOME/.tmux"
rm -rf "$HOME/.tmux/plugins"
cp "$REPO_DIR/config/.tmux.conf" "$HOME/.tmux.conf"
cp "$REPO_DIR/config/ghostty/pane-dimming.conf" "$HOME/.config/ghostty/"
t() { "$TMUX_BIN" -S "$scratch/socket" "$@"; }
DOTFILES_GHOSTTY_PANE_DIMMING=0 DOTFILES_PI_OVERWATCH=0 t -f "$HOME/.tmux.conf" new-session -d -s test 'sleep 120'
[[ "$(t show-option -gqv @dotfiles-pane-dimming)" == off ]]
t set-hook -g 'client-attached[42]' 'display-message unrelated'
t set-environment -g DOTFILES_GHOSTTY_PANE_DIMMING 1
t source-file "$HOME/.tmux.conf"
if [[ "$(t display-message -p '#{>=:#{version},3.7}')" == 1 ]]; then
  [[ "$(t show-option -gqv @dotfiles-pane-dimming)" == on ]]
  t show-hooks -g | grep -q 'client-attached\[90\]'
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
printf 'PASS: isolated tmux server, dimming off/on/off, unrelated hook preserved, missing dependency\n'
