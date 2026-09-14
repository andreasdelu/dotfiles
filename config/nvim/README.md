# Neovim Config

This config is organized around a small bootstrap and explicit modules:

- `init.lua`: bootstrap only
- `lua/config`: editor-wide options, keymaps, autocmds, and lazy setup
- `lua/plugins`: plugin specs grouped by responsibility
- `after/`: filetype-specific syntax and treesitter overrides

## Plugin layout

- `colorscheme.lua`: theme setup
- `statusline.lua`, `treesitter.lua`, `gitsigns.lua`, `ufo.lua`: editing UI
- `telescope.lua`, `neo-tree.lua`, `harpoon.lua`, `vim-tmux-navigator.lua`: navigation
- `lspconfig.lua`, `blink-cmp.lua`, `conform.lua`: LSP, completion, formatting
- `lint.lua`, `ruby-spec.lua`: Ruby linting and spec helpers
- `windsurf.lua`: active AI completion; `copilot.lua` is disabled

These plugins are shared across platforms. AI and animation preferences are not
part of the dotfiles feature flags. Sorbet remains gated on `sorbet/config`, with
the existing Landfolk checkout-specific Nix command; Rubocop/Syntax Tree are
limited to actual `.rb` files.

## Maintenance rules

- Put global editor state in `lua/config`, not inside plugin spec files.
- Give each plugin one authoritative config source.
- Treat new plugins as opt-in: if a plugin is not part of daily editing, navigation, or language tooling, do not add it to the core set.
- Keep `lazy-lock.json` tracked so updates stay reproducible.
