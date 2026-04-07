# AGENTS.md

A quick guide for LLMs working in this dotfiles repo.

## Repo shape

This is a personal macOS dotfiles repo.

Main jobs:
- bootstrap a machine
- install packages with Homebrew
- symlink tracked config into the right places
- maintain terminal, shell, git, keyboard, and Neovim config

The repo is small and fairly direct. Most good changes are small edits to existing files.

## How config is stored

Tracked config lives in `config/`.

`maps.txt` describes where each item is linked on the machine. `scripts/setup_dotfiles.sh` reads that file, backs up existing targets into a timestamped `.backup_*` folder in the repo, and creates the symlinks.

Current mappings:
- `config/.ghostty` → `~/Library/Application Support/com.mitchellh.ghostty/config`
- `config/.gitconfig` → `~/.gitconfig`
- `config/.zshrc` → `~/.zshrc`
- `config/nvim` → `~/.config/nvim`
- `config/karabiner.json` → `~/.config/karabiner/karabiner.json`
- `config/.tmux.conf` → `~/.tmux.conf`
- `config/.tmux` → `~/.tmux`

If you add a new dotfile, the usual flow is:
1. add it under `config/`
2. add its destination to `maps.txt`
3. let `scripts/setup_dotfiles.sh` manage the link

## Important files

Top level:
- `README.md` — setup overview
- `bootstrap.sh` — interactive setup entrypoint
- `Brewfile` — Homebrew packages
- `maps.txt` — symlink map
- `scripts/` — setup helpers
- `config/` — tracked source config

Scripts:
- `scripts/set_macos_defaults.sh`
- `scripts/install_homebrew.sh`
- `scripts/install_ohmyzsh.sh`
- `scripts/authenticate_git.sh`
- `scripts/setup_dotfiles.sh`
- `scripts/common.sh`

## Bootstrap flow

`bootstrap.sh` runs:
1. macOS defaults
2. Homebrew install
3. oh-my-zsh install
4. GitHub auth
5. dotfile linking
6. `brew bundle install`

The flow is interactive and each script can be skipped.

## Neovim

Neovim config lives in `config/nvim`.

Structure:
- `init.lua` — tiny entrypoint
- `lua/config/` — global options, keymaps, autocmds, plugin bootstrap
- `lua/plugins/` — plugin-specific files
- `after/` — syntax and query overrides
- `lazy-lock.json` — plugin lockfile
- `minimal.lua` — minimal debug path

Useful Neovim conventions in this repo:
- global editor state usually belongs in `lua/config/`
- plugin-specific behavior usually belongs in `lua/plugins/<name>.lua`
- `lazy-lock.json` is tracked

### Current Neovim setup worth knowing

#### Plugin manager
The repo still uses `lazy.nvim`.

#### Ruby
Current active Ruby setup:
- Ruby LSP is disabled
- Sorbet is used for Ruby LSP features in Sorbet projects
- Sorbet only starts when `sorbet/config` is present
- in `~/Documents/landfolk/apps/api`, Sorbet is launched via:
  - `nix develop ../..#api -c ./bin/srb tc --lsp --disable-watchman`
- Rubocop linting and Syntax Tree formatting are limited to actual `.rb` files

Files involved:
- `config/nvim/lua/plugins/lspconfig.lua`
- `config/nvim/lua/plugins/lint.lua`
- `config/nvim/lua/plugins/conform.lua`
- `config/nvim/lua/plugins/ruby-spec.lua`

#### Tree-sitter
Current working setup on Neovim 0.12:
- `nvim-treesitter` on `branch = 'main'`
- `require('nvim-treesitter').setup()`
- `vim.treesitter.start()` on `FileType`
- append `.../lazy/nvim-treesitter/runtime` to `runtimepath`

That runtime-path detail matters here because the plugin’s queries live there.

#### Copilot
Current setup:
- plugin: `github/copilot.vim`
- loads on `VimEnter`
- keybindings:
  - `<C-l>` full accept
  - `<C-j>` accept word
  - `<C-]>` dismiss
  - `<M-]>` next
  - `<M-[>` previous

Useful reference if editing Copilot mappings:
- `~/.local/share/nvim/lazy/copilot.vim/doc/copilot.txt`

Notable detail: full accept uses `copilot#Accept(...)` as an expr mapping; word accept is exposed as `<Plug>(copilot-accept-word)`.

## Validation

After changing shell/bootstrap/symlink logic:
- read the affected script end-to-end
- sanity-check `maps.txt` if link behavior changed

After changing Neovim config:
- startup check:
  - `cd ~/.dotfiles && nvim --headless '+lua dofile(vim.fn.expand("config/nvim/init.lua"))' '+qall'`
- if plugin/parsers changed:
  - `cd ~/.dotfiles && nvim --headless '+TSUpdate' '+qall'`
- if LSP behavior changed, test against a real file in the target project, not just headless startup

## Working style

This repo generally responds best to:
- small, concrete edits
- reading the actual script/plugin docs when something is unclear
- checking the real runtime path/command instead of assuming

Good first questions when debugging:
- is the wrong file being edited?
- is the symlink target correct?
- is the language tool starting in the wrong root?
- is the runtime/tool path different from what the config assumes?
- does the plugin’s own documentation match memory?
