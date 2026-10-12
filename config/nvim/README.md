# Neovim config

`init.lua` loads `lua/config/` (options, keymaps, autocmds, lazy.nvim). Each file in `lua/plugins/` owns one plugin; `after/` contains Ruby syntax and Tree-sitter overrides.

- Neovim 0.12 supplies default LSP mappings and `:lsp` commands. `lspconfig.lua` keeps server overrides, diagnostics, and extra mappings.
- Sorbet starts only where `sorbet/config` exists, using the enclosing Sorbet workspace even for nested gems. `lua/config/ruby.lua` recognizes Landfolk API checkouts by project markers, regardless of checkout location, and selects their Nix command. Other Sorbet projects use `srb` on PATH.
- RuboCop is manual via `<leader>l`; Syntax Tree formats `.rb` on save or with `<leader>f`. Both prefer project binstubs; Ruby and Nix tooling must be installed separately.
- FFF handles file finding, grep, and resume. `<leader><leader>` opens its file finder (not unsaved buffers). Neo-tree shows Git status via `<leader>gw` or `gs` in the tree; Gitsigns shows working-tree hunks. Use Git tooling for branch diffs rather than a custom picker.
- For the former general-purpose pickers, use `:help`, `:map`, `:buffers`, and `/`. `<leader>sd` opens diagnostics in quickfix; `gW` prompts for workspace symbols and opens quickfix.
- Windsurf supplies inline suggestions. Ruby spec discovery and custom statusline rendering are intentionally absent.

These plugins are shared across platforms; AI and animation preferences are not dotfiles feature flags. Keep `lazy-lock.json` tracked. Prefer deleting unused behavior over adding fallback branches. Check `scripts/tests/test_nvim.sh` and the real project workflow before changing Sorbet or Tree-sitter startup.
