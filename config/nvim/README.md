# Neovim Config

This config is organized around a small bootstrap and explicit modules:

- `init.lua`: bootstrap only
- `lua/config`: editor-wide options, keymaps, autocmds, and lazy setup
- `lua/plugins`: plugin specs grouped by responsibility
- `after/`: filetype-specific syntax and treesitter overrides

## Plugin layout

- `colorscheme.lua`: theme setup
- `editor.lua`: editing UX, statusline, treesitter, git signs, folds
- `navigation.lua`: Telescope, Neo-tree, tmux navigation, git change pickers
- `lsp.lua`: LSP, completion, formatting
- `ruby.lua`: Ruby linting and spec helpers

## Maintenance rules

- Put global editor state in `lua/config`, not inside plugin spec files.
- Give each plugin one authoritative config source.
- Treat new plugins as opt-in: if a plugin is not part of daily editing, navigation, or language tooling, do not add it to the core set.
- Keep `lazy-lock.json` tracked so updates stay reproducible.
