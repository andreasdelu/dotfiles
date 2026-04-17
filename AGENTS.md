# AGENTS.md

Guide for LLMs and coding agents working in this dotfiles repo.

## What this repo is

This is a personal macOS-focused dotfiles repo.

Primary responsibilities:

- bootstrap a new machine
- install packages via Homebrew
- symlink files from `config/` into their real locations
- maintain Neovim, shell, terminal, tmux, git, and Karabiner config

The repo is intentionally small and direct. Prefer simple edits over abstractions.

## Repo layout

### Top level

- `README.md` — human-facing setup overview
- `bootstrap.sh` — interactive machine setup entrypoint
- `Brewfile` — Homebrew packages
- `maps.txt` — source-to-destination symlink map
- `scripts/` — bootstrap helpers
- `config/` — canonical source of truth for symlinked config files

### Symlink model

`config/` contains the real tracked files. `scripts/setup_dotfiles.sh` links them into `$HOME` or `~/Library/...`.

Current mappings from `maps.txt`:

- `config/.ghostty` → `~/Library/Application Support/com.mitchellh.ghostty/config`
- `config/.gitconfig` → `~/.gitconfig`
- `config/.zshrc` → `~/.zshrc`
- `config/nvim` → `~/.config/nvim`
- `config/karabiner.json` → `~/.config/karabiner/karabiner.json`
- `config/.tmux.conf` → `~/.tmux.conf`
- `config/.tmux` → `~/.tmux`

## Working rules

### 1. Edit inside `config/`, not the live destination

If you want to change Neovim, zsh, Ghostty, tmux, Git, or Karabiner config, edit the tracked file under `config/`.

Do **not** edit the symlink target path directly unless you are explicitly debugging a symlink problem.

### 2. Preserve the bootstrap/symlink model

If you add a new dotfile:

1. create it under `config/`
2. add the mapping to `maps.txt`
3. only then mention how it gets linked

Do not introduce a second linking mechanism.

### 3. Keep scripts boring

Shell scripts here are intentionally simple:

- `bash`
- `set -euo pipefail`
- small functions
- interactive prompts through `scripts/common.sh`

Prefer readability over clever shell tricks.

### 4. Avoid unnecessary framework churn

For editor config especially, do not migrate tools/managers just because a newer built-in exists.
Prefer targeted fixes and repo-fit over trend-chasing.

## Bootstrap flow

`bootstrap.sh` runs these in order:

1. `scripts/set_macos_defaults.sh`
2. `scripts/install_homebrew.sh`
3. `scripts/install_ohmyzsh.sh`
4. `scripts/authenticate_git.sh`
5. `scripts/setup_dotfiles.sh`
6. `brew bundle install`

Important characteristics:

- interactive by default
- safe to skip steps one by one
- symlink setup backs up existing files into a timestamped `.backup_*` folder at repo root

## Neovim guide

Neovim lives in `config/nvim`.

### Structure

- `init.lua` — tiny bootstrap only
- `lua/config/` — global options, keymaps, autocmds, plugin manager bootstrap
- `lua/plugins/` — one file per plugin/responsibility
- `after/` — filetype-specific syntax and Tree-sitter overrides
- `lazy-lock.json` — tracked plugin lockfile
- `minimal.lua` — minimal startup/debug path

### Editing rules for Neovim

- put global editor behavior in `lua/config/*`
- put plugin-specific behavior in `lua/plugins/<name>.lua`
- give each plugin one authoritative config source
- keep `lazy-lock.json` in sync when plugin revisions actually change
- prefer small plugin-local edits over giant rewrites

### Current important Neovim behavior

These are worth preserving unless intentionally changing them:

#### Plugin manager

- still uses `lazy.nvim`
- do not assume a migration to `vim.pack`

#### Ruby setup

Current intended Ruby setup is:

- **Ruby LSP disabled in active config**
- **Sorbet** is the Ruby LSP for Sorbet projects
- Sorbet is root-gated by presence of `sorbet/config`
- in `~/Documents/landfolk/apps/api`, Sorbet is started through:
  - `nix develop ../..#api -c ./bin/srb tc --lsp --disable-watchman`
- Rubocop linting and Syntax Tree formatting are limited to actual `.rb` files

If Ruby tooling seems broken, check `config/nvim/lua/plugins/`:

- `lspconfig.lua`
- `lint.lua`
- `conform.lua`
- `ruby-spec.lua`

#### Tree-sitter on Neovim 0.12

This repo uses:

- `nvim-treesitter` on `branch = 'main'`
- `require('nvim-treesitter').setup()`
- `vim.treesitter.start()` on `FileType`
- explicit append of `.../lazy/nvim-treesitter/runtime` to `runtimepath`

That `runtime` path append is important here because without it, queries may not load and highlighting disappears.

#### Copilot

- plugin: `github/copilot.vim`
- loads on `VimEnter`
- current intended keybindings:
  - `<C-l>` full accept
  - `<C-j>` accept word
  - `<C-]>` dismiss
  - `<M-]>` next
  - `<M-[>` previous

When editing Copilot mappings, check the installed plugin docs instead of guessing:

- `~/.local/share/nvim/lazy/copilot.vim/doc/copilot.txt`

Full accept is an `expr` mapping via `copilot#Accept(...)`; it is **not** a `<Plug>(copilot-accept)` mapping in this plugin.

## Useful file map

### Shell / terminal

- `config/.zshrc`
- `config/.ghostty`
- `config/.tmux.conf`
- `config/.tmux/`

### Git

- `config/.gitconfig`
- `scripts/authenticate_git.sh`

### macOS / keyboard

- `config/karabiner.json`
- `scripts/set_macos_defaults.sh`

### Bootstrap / installation

- `bootstrap.sh`
- `Brewfile`
- `scripts/install_homebrew.sh`
- `scripts/install_ohmyzsh.sh`
- `scripts/setup_dotfiles.sh`
- `maps.txt`

## Validation checklist

After changing shell/bootstrap/symlink behavior:

- read the changed script end-to-end
- make sure paths still point into `config/`
- if symlink behavior changed, sanity-check `maps.txt` and `scripts/setup_dotfiles.sh`

After changing Neovim config:

- run a headless startup check:
  - `cd ~/.dotfiles && nvim --headless '+lua dofile(vim.fn.expand("config/nvim/init.lua"))' '+qall'`
- if plugin/parser behavior changed, also run:
  - `cd ~/.dotfiles && nvim --headless '+TSUpdate' '+qall'`
- if LSP behavior changed, validate against a real file in the target project, not just startup

## Things not to do casually

- do not rewrite bootstrap into a larger framework
- do not move config out of `config/`
- do not edit live symlink destinations as the primary change path
- do not remove `lazy-lock.json`
- do not reintroduce Ruby LSP unless there is a clear benefit over Sorbet in this setup
- do not assume Homebrew, Nix, or language runtime behavior without checking the actual command paths used

## When in doubt

Start from the simplest explanation:

- symlink issue?
- wrong file under `config/`?
- wrong runtime/root for language tools?
- plugin docs differ from memory?

This repo rewards small, precise fixes.
