#!/usr/bin/env bash
# No live HOME, bootstrap execution, package installation, or default tmux server.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/repo" "$scratch/home" "$scratch/bin"
cp -R "$REPO_DIR/config" "$REPO_DIR/scripts" "$REPO_DIR/maps.txt" "$scratch/repo/"
rm -f "$scratch/repo/config/dotfiles/local.env"
export HOME="$scratch/home"
unset TMUX DOTFILES_MACOS_DESKTOP DOTFILES_GHOSTTY_PANE_DIMMING DOTFILES_PI_OVERWATCH

for script in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/bootstrap.sh "$REPO_DIR"/config/.tmux/bin/*; do
  bash -n "$script"
done
zsh -n "$REPO_DIR/config/.zshrc"

DOTFILES_ASSUME_YES=1 DRY_RUN=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/native-dry"
[[ ! -e "$HOME/.zshrc" ]]
# Exercise the other platform's branch without pretending it is a Linux runtime.
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$scratch/bin/uname"
chmod +x "$scratch/bin/uname"
PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 DRY_RUN=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/linux-dry"
! grep -q 'Library\|karabiner.json\|linearmouse.json' "$scratch/linux-dry"
grep -q '/.config/lazygit/config.yml' "$scratch/linux-dry"

# Real linking and backup behavior, but only in a temporary copy of the repo.
printf 'old config\n' > "$HOME/.zshrc"
DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/links"
[[ -L "$HOME/.zshrc" ]]
grep -q 'old config' "$scratch/repo"/.backup_*/.zshrc
DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/relinks"
grep -q 'OK (linked)' "$scratch/relinks"
env -i HOME="$HOME" PATH=/usr/bin:/bin TERM=xterm-256color zsh -d -i -c '[[ -z ${aliases[pax]-} ]]' > "$scratch/zsh-out" 2> "$scratch/zsh-err"
[[ ! -s "$scratch/zsh-err" ]]
# Defaults load once, without evaluating code or overriding explicit zero.
printf 'DOTFILES_MACOS_DESKTOP=1\nDOTFILES_GHOSTTY_PANE_DIMMING=1\nDOTFILES_PI_OVERWATCH=1\n' > "$scratch/repo/config/dotfiles/local.env"
for shell in bash zsh; do
  "$shell" -c '. "$1"; dotfiles_load_preferences "$2"; test "$DOTFILES_MACOS_DESKTOP:$DOTFILES_GHOSTTY_PANE_DIMMING:$DOTFILES_PI_OVERWATCH" = 1:1:1' _ "$REPO_DIR/config/dotfiles/env.sh" "$scratch/repo/config/dotfiles/local.env"
  DOTFILES_MACOS_DESKTOP=0 DOTFILES_GHOSTTY_PANE_DIMMING=0 DOTFILES_PI_OVERWATCH=0 "$shell" -c '. "$1"; dotfiles_load_preferences "$2"; test "$DOTFILES_MACOS_DESKTOP:$DOTFILES_GHOSTTY_PANE_DIMMING:$DOTFILES_PI_OVERWATCH" = 0:0:0' _ "$REPO_DIR/config/dotfiles/env.sh" "$scratch/repo/config/dotfiles/local.env"
done
# Simulate macOS for deterministic desktop link checks on either host OS.
printf '#!/bin/sh\nprintf "Darwin\\n"\n' > "$scratch/bin/uname"
PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/desktop-on"
[[ -L "$HOME/.config/linearmouse/linearmouse.json" ]]
PATH="$scratch/bin:$PATH" DOTFILES_MACOS_DESKTOP=0 DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/desktop-off"
[[ ! -e "$HOME/.config/linearmouse/linearmouse.json" ]]
printf 'user owned\n' > "$HOME/.config/linearmouse/linearmouse.json"
PATH="$scratch/bin:$PATH" DOTFILES_MACOS_DESKTOP=0 DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > /dev/null
grep -q 'user owned' "$HOME/.config/linearmouse/linearmouse.json"
mkdir -p "$HOME/.tmux/plugins/tmux-worktree-manager/dist" "$HOME/.pi/overwatch/agents"
printf '#!/bin/sh\nexit 0\n' > "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm"
chmod +x "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm"
DOTFILES_PI_OVERWATCH=1 zsh -d -i -c '[[ ${aliases[twm]} == *ENABLE=true* ]]; export DOTFILES_PI_OVERWATCH=0; source ~/.zshrc; [[ ${aliases[twm]} == *ENABLE=false* ]]'
printf 'PASS: syntax, native/simulated maps, isolated links/backups, minimal zsh, preference precedence, desktop/Overwatch on-off\n'
