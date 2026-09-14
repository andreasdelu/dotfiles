#!/usr/bin/env bash
# No live HOME, bootstrap execution, package installation, or default tmux server.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/repo" "$scratch/home" "$scratch/bin"
cp -R "$REPO_DIR/config" "$REPO_DIR/scripts" "$REPO_DIR/maps.txt" "$scratch/repo/"
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
printf 'PASS: syntax, native/simulated-Linux maps, isolated links/backups, minimal zsh startup\n'
