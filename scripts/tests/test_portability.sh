#!/usr/bin/env bash
# No live HOME, bootstrap execution, package installation, or default tmux server.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/repo" "$scratch/home" "$scratch/bin"
cp -R "$REPO_DIR/config" "$REPO_DIR/scripts" "$REPO_DIR/maps" "$scratch/repo/"
rm -f "$scratch/repo/config/dotfiles/local.env"
export HOME="$scratch/home"
unset TMUX DOTFILES_GHOSTTY_PANE_DIMMING

for script in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/scripts/install/*.sh \
              "$REPO_DIR"/scripts/install/{macos,linux}/*.sh \
              "$REPO_DIR"/scripts/tests/*.sh "$REPO_DIR"/bootstrap.sh \
              "$REPO_DIR"/config/tmux/bin/*; do
  bash -n "$script"
done
zsh -n "$REPO_DIR/config/zshrc"
for fragment in "$REPO_DIR"/config/zsh/*.sh; do zsh -n "$fragment"; done

DOTFILES_ASSUME_YES=1 DRY_RUN=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/native-dry"
[[ ! -e "$HOME/.zshrc" ]]
# Exercise the other platform's branch without pretending it is a Linux runtime.
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$scratch/bin/uname"
chmod +x "$scratch/bin/uname"
PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 DRY_RUN=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/linux-dry"
! grep -q 'Library\|karabiner.json\|linearmouse.json' "$scratch/linux-dry"
grep -q '/.config/lazygit/config.yml' "$scratch/linux-dry"
! grep -q 'ghostty/' "$scratch/linux-dry"
# A new OS only needs a map file; an unknown OS must fail before touching links.
printf '#!/bin/sh\nprintf "FreeBSD\\n"\n' > "$scratch/bin/uname"
if PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 DRY_RUN=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/unknown-os" 2>&1; then
  echo 'Unexpected success without FreeBSD map' >&2; exit 1
fi
! grep -q '\[DRY\]' "$scratch/unknown-os"
printf 'lazygit/config.yml=~/.config/lazygit/config.yml\n' > "$scratch/repo/maps/freebsd.txt"
PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 DRY_RUN=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/freebsd-dry"
grep -q '/.config/lazygit/config.yml' "$scratch/freebsd-dry"
grep -q '/.zshrc' "$scratch/freebsd-dry"
printf 'lazygit/config.yml=~/.config/other|unknown\n' >> "$scratch/repo/maps/freebsd.txt"
if PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/bad-map" 2>&1; then
  echo 'Malformed platform map unexpectedly linked files' >&2; exit 1
fi
[[ ! -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]
printf 'missing-equals\n' > "$scratch/repo/maps/freebsd.txt"
if PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/malformed-map" 2>&1; then
  echo 'Malformed map entry unexpectedly linked files' >&2; exit 1
fi
[[ ! -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]

# Real linking and backup behavior, but only in a temporary copy of the repo.
mkdir -p "$scratch/date-bin"
printf '#!/bin/sh\nprintf "20990101_010101\\n"\n' > "$scratch/date-bin/date"
chmod +x "$scratch/date-bin/date"
ln -s "$scratch/missing-user-file" "$HOME/.zshrc"
PATH="$scratch/date-bin:$PATH" DOTFILES_ASSUME_YES=1 DRY_RUN=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/dry-backup"
[[ -L "$HOME/.zshrc" && ! -d "$scratch/repo/.backup_20990101_010101.DRY_RUN" ]]
PATH="$scratch/date-bin:$PATH" DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/links"
[[ -L "$HOME/.zshrc" && -L "$HOME/.config/zsh" ]]
first_backup=("$scratch/repo"/.backup_20990101_010101.*)
[[ -L "${first_backup[0]}/.zshrc" ]]
[[ "$(readlink "${first_backup[0]}/.zshrc")" == "$scratch/missing-user-file" ]]
rm "$HOME/.zshrc"
printf 'old config\n' > "$HOME/.zshrc"
PATH="$scratch/date-bin:$PATH" DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/second-links"
backups=("$scratch/repo"/.backup_20990101_010101.*)
[[ "${#backups[@]}" == 2 ]]
for backup in "${backups[@]}"; do
  if [[ "$backup" != "${first_backup[0]}" ]]; then
    grep -q 'old config' "$backup/.zshrc"
  fi
done
DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/relinks"
grep -q 'OK (linked)' "$scratch/relinks"
env -i HOME="$HOME" PATH=/usr/bin:/bin TERM=xterm-256color zsh -d -i -c '[[ -z ${aliases[pax]-} && ${aliases[md]-} == "make dev" && $+functions[grbia] == 1 ]]' > "$scratch/zsh-out" 2> "$scratch/zsh-err"
[[ ! -s "$scratch/zsh-err" ]]
mkdir -p "$HOME/Documents/pax/bin"
printf '#!/bin/sh\nexit 0\n' > "$HOME/Documents/pax/bin/pax"
chmod +x "$HOME/Documents/pax/bin/pax"
env -i HOME="$HOME" PATH=/usr/bin:/bin TERM=xterm-256color zsh -d -i -c '[[ -n ${aliases[pax]-} && -n ${aliases[paxc]-} ]]' > "$scratch/pax-out" 2> "$scratch/pax-err"
[[ ! -s "$scratch/pax-err" ]]
# The remaining opt-in loads as data, without overriding explicit zero or empty.
printf 'DOTFILES_GHOSTTY_PANE_DIMMING=1\n' > "$scratch/repo/config/dotfiles/local.env"
for shell in bash zsh; do
  "$shell" -c '. "$1"; dotfiles_load_preferences "$2"; test "$DOTFILES_GHOSTTY_PANE_DIMMING" = 1' _ "$REPO_DIR/config/dotfiles/env.sh" "$scratch/repo/config/dotfiles/local.env"
  DOTFILES_GHOSTTY_PANE_DIMMING=0 "$shell" -c '. "$1"; dotfiles_load_preferences "$2"; test "$DOTFILES_GHOSTTY_PANE_DIMMING" = 0' _ "$REPO_DIR/config/dotfiles/env.sh" "$scratch/repo/config/dotfiles/local.env"
  DOTFILES_GHOSTTY_PANE_DIMMING='' "$shell" -c '. "$1"; dotfiles_load_preferences "$2"; test -z "$DOTFILES_GHOSTTY_PANE_DIMMING"' _ "$REPO_DIR/config/dotfiles/env.sh" "$scratch/repo/config/dotfiles/local.env"
done
# Simulate macOS for deterministic app links on either host OS.
printf '#!/bin/sh\nprintf "Darwin\\n"\n' > "$scratch/bin/uname"
PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/desktop-on"
[[ -L "$HOME/.config/linearmouse/linearmouse.json" ]]
[[ -L "$HOME/Library/Application Support/com.mitchellh.ghostty/config" ]]
[[ -L "$HOME/Library/Application Support/lazygit/config.yml" ]]
PATH="$scratch/bin:$PATH" DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/setup_dotfiles.sh" > "$scratch/mac-relinks"
[[ -L "$HOME/.config/linearmouse/linearmouse.json" ]]
mkdir -p "$HOME/.tmux/plugins/tmux-worktree-manager/dist"
printf '#!/bin/sh\nexit 0\n' > "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm"
chmod +x "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm"
zsh -d -i -c '[[ ${aliases[twm]} == *tmux-worktree-manager/dist/twm* ]]'
printf 'PASS: syntax, native/simulated maps, isolated links/backups, minimal zsh, preference precedence, macOS app links\n'
