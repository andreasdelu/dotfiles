# AGENTS.md

Guide for LLMs and coding agents working in this dotfiles repo.

## What this repo is

This is a personal portable dotfiles repo with macOS and Linux setup helpers.

Primary responsibilities:

- bootstrap a new machine
- install packages via Homebrew on macOS or the native package manager on Linux (apt supported first)
- symlink files from `config/` into their real locations
- maintain Neovim, shell, terminal, tmux, Git, and platform-specific app config

The repo is intentionally small and direct. Prefer simple edits over abstractions.

## Repo layout

### Top level

- `README.md` — human-facing setup overview
- `bootstrap.sh` — interactive machine setup entrypoint
- `Brewfile` — Homebrew packages
- `maps/common.txt`, `maps/macos.txt`, `maps/linux.txt` — source-to-destination symlink maps
- `scripts/install/` — shared Oh My Zsh plus `macos/` (Homebrew/Brewfile) and `linux/` (apt/editor)
- `exports/` — app setting snapshots (not linked)
- `scripts/tests/` — isolated setup/editor checks
- `scripts/` — linker, defaults, and bootstrap helpers
- `config/` — canonical source of truth for symlinked config files

### Symlink model

`config/` contains the real tracked files, with plain source names (for example
`config/zshrc` -> `~/.zshrc`, `config/zsh/` -> `~/.config/zsh/`,
`config/tmux/` -> `~/.tmux/`).
`scripts/setup_dotfiles.sh` links them into `$HOME` or `~/Library/...`.

`maps/common.txt` and one platform map are the authoritative mapping lists;
fixed feature conditions follow `|`. Core shell, tmux, Neovim, and Git links
are shared; lazygit destinations differ by OS, while Ghostty links are
macOS-only. macOS defaults require separate confirmation.
`config/dotfiles` links to `~/.config/dotfiles`; its gitignored `local.env` only
controls optional Ghostty pane dimming and never overrides explicit process
values. See README for reload boundaries.

## Working rules

### 1. Edit inside `config/`, not the live destination

If you want to change Neovim, zsh, Ghostty, tmux, Git, or app config, edit the tracked file under `config/`.

Do **not** edit the symlink target path directly unless you are explicitly debugging a symlink problem.

### 2. Preserve the bootstrap/symlink model

If you add a new dotfile:

1. create it under `config/`
2. add the mapping to `maps/common.txt` or the relevant platform map
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

`bootstrap.sh` offers supported steps in a checkbox menu, then runs selected
native Linux packages (apt adapter, version-independent) plus latest stable
Neovim/Tree-sitter CLI, or macOS Homebrew/Brewfile, then Oh My Zsh, dotfile
linking, TPM, GitHub authentication, and macOS defaults. TPM is installed after
linking, independently of package selection, so it is not stranded in a backup
directory. For other Linux package managers, add an adapter rather than falling
back to Linuxbrew; macOS defaults always need a separate confirmation and run
per-user settings without `sudo`.

Important characteristics:

- interactive by default
- safe to skip steps one by one
- linking preflights both maps and backs up existing files and foreign symlinks into a unique `.backup_*` folder only when needed

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
- Landfolk API checkouts are recognized by `lua/config/ruby.lua` using project
  markers, not the checkout's name or home directory; Sorbet is started through:
  - `nix develop ../..#api -c ./bin/srb tc --lsp --disable-watchman`
- Rubocop linting and Syntax Tree formatting are limited to actual `.rb` files

If Ruby tooling seems broken, check `config/nvim/lua/plugins/`:

- `lspconfig.lua`
- `lint.lua`
- `conform.lua`

#### Tree-sitter on Neovim 0.12

This repo uses:

- `nvim-treesitter` on `branch = 'main'`
- `require('nvim-treesitter').setup()`
- `vim.treesitter.start()` on `FileType`
- explicit append of `.../lazy/nvim-treesitter/runtime` to `runtimepath`

That `runtime` path append is important here because without it, queries may not load and highlighting disappears.

#### Inline suggestions

- plugin: `Exafunction/windsurf.nvim` (Codeium), loaded on `InsertEnter`
- keybindings: `<C-l>` accept, `<C-j>` accept word, `<C-]>` dismiss, `<M-]>` next, `<M-[>` previous
- `.env*` buffers disable suggestions; keep this protection when changing the plugin
- Copilot is not configured; do not reintroduce a second suggestion engine casually.

## Useful file map

### Shell / terminal

- `config/zshrc` — ordered loader; source `landfolk.sh` before PATH/plugins for Nix
- `config/zsh/` — Landfolk (including Nix/Pax), environment, plugins, general aliases/functions
- `config/ghostty/config`
- `config/tmux.conf`
- `config/tmux/` (`features.conf` loads the optional pane-dimming handler)

### Git

- `config/gitconfig`
- `scripts/authenticate_git.sh`

### macOS / keyboard

- `config/linearmouse.json`
- `scripts/set_macos_defaults.sh`

### Bootstrap / installation

- `bootstrap.sh`
- `Brewfile`
- `scripts/install/macos/homebrew.sh` and `scripts/install/macos/brewfile.sh`
- `scripts/install/linux/apt.sh` and `scripts/install/linux/editor.sh`
- `scripts/install/ohmyzsh.sh` (shared)
- `scripts/setup_dotfiles.sh`
- `maps/`

## Validation checklist

After changing shell/bootstrap/symlink behavior:

- read the changed script end-to-end
- make sure paths still point into `config/`
- if symlink behavior changed, sanity-check `maps/{common,macos,linux}.txt` and `scripts/setup_dotfiles.sh`
- run `bash scripts/tests/test_portability.sh`, `bash scripts/tests/test_bootstrap.sh`,
  `bash scripts/tests/test_tmux_features.sh`, `bash scripts/tests/test_pane_metadata.sh`, and
  `bash scripts/tests/test_ghostty.sh`
- never run bootstrap against live HOME or use the live tmux server for tests

After changing Neovim config:

- run an isolated headless startup check:
  - `bash scripts/tests/test_nvim.sh` (copies installed plugins to a temporary HOME)
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
