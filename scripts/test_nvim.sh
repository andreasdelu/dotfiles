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
# Keep normal editor/LSP setup, but never fetch Mason tools during a smoke test.
no_install='lua package.preload["mason-tool-installer"] = function() return { setup = function() end } end'
nvim --headless -u NONE -i NONE -l "$REPO_DIR/config/nvim/lua/config/ruby.test.lua"
for flag in 0 1; do
  export DOTFILES_MACOS_DESKTOP="$flag" DOTFILES_GHOSTTY_PANE_DIMMING="$flag" DOTFILES_PI_OVERWATCH="$flag"
  # Startup-only mode opens no project file; real attachment is opt-in below.
  nvim --headless --cmd "$no_install" '+lua assert(vim.env.DOTFILES_PI_OVERWATCH == os.getenv("DOTFILES_PI_OVERWATCH")); assert(vim.g.mapleader == " "); assert(require("lazy.core.config").plugins["windsurf.nvim"] or require("lazy.core.config").plugins["windsurf.vim"] or require("lazy.core.config").plugins["codeium.nvim"])' '+qall' > "$scratch/nvim-$flag.log" 2>&1
  if grep -E 'Error|E[0-9]{3}:|stack traceback|Failed' "$scratch/nvim-$flag.log"; then
    exit 1
  fi
done
printf 'PASS: Neovim headless startup, both flag states, copied plugins and isolated XDG paths\n'
if [[ $# -gt 0 ]]; then
  # Explicit opt-in: start real Sorbet/Nix, including the API shell's normal
  # local-service hooks. No buffer writes, formatting, or gem installation.
  if ! nvim --headless --cmd "$no_install" "$1" '+lua assert(vim.wait(60000, function() for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = "sorbet" })) do if client.initialized then return true end end return false end, 100), "Sorbet did not attach within 60s"); print("PASS: real-file Sorbet attachment"); for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end' '+qall' > "$scratch/attachment.log" 2>&1 ||
      ! grep -q 'PASS: real-file Sorbet attachment' "$scratch/attachment.log"; then
    tail -n 30 "$scratch/attachment.log" "$XDG_STATE_HOME/nvim/lsp.log" >&2
    exit 1
  fi
  printf 'PASS: real-file Sorbet attachment\n'
fi
