#!/usr/bin/env bash
# Copy existing plugin installations: never install/update into the live HOME.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_source="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
if [[ ! -d "$plugin_source/lazy.nvim" ]]; then
  echo 'SKIP: install Neovim plugins first; this test does not fetch dependencies'
  exit 0
fi
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/home/.config" "$scratch/home/.local/share/nvim"
cp -R "$REPO_DIR/config/nvim" "$scratch/home/.config/"
cp -R "$plugin_source" "$scratch/home/.local/share/nvim/lazy"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
unset TMUX
for flag in 0 1; do
  export DOTFILES_MACOS_DESKTOP="$flag" DOTFILES_GHOSTTY_PANE_DIMMING="$flag" DOTFILES_PI_OVERWATCH="$flag"
  # No editing an actual project: unchanged Sorbet/Ruby code is not exercised.
  nvim --headless '+lua assert(vim.env.DOTFILES_PI_OVERWATCH == os.getenv("DOTFILES_PI_OVERWATCH")); assert(vim.g.mapleader == " "); assert(require("lazy.core.config").plugins["windsurf.nvim"] or require("lazy.core.config").plugins["windsurf.vim"] or require("lazy.core.config").plugins["codeium.nvim"])' '+qall' > "$scratch/nvim-$flag.log" 2>&1
  if grep -E 'Error|E[0-9]{3}:|stack traceback|Failed' "$scratch/nvim-$flag.log"; then
    exit 1
  fi
done
printf 'PASS: Neovim headless startup, both flag states, copied plugins and isolated XDG paths\n'
