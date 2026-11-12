return {
  'petertriho/nvim-scrollbar',
  -- v2 lives here until it replaces main; keep its config and revision together.
  branch = 'refactor/v2',
  event = 'VeryLazy',
  opts = {
    scrollbar = {
      show = true,
      visibility = 'all',
      hide_if_all_visible = false,
      throttle_ms = 100,
    },
    exclude = {
      buftypes = { 'terminal', 'prompt', 'nofile' },
      filetypes = { 'neo-tree', 'neo-tree-popup', 'TelescopePrompt' },
    },
    providers = {
      cursor = false,
      diagnostic = true,
      gitsigns = true,
      search = false,
      marks = false,
    },
    marks = {
      Search = { highlight = { fg = '#7aa2f7' } },
      Error = { highlight = { fg = '#f7768e' } },
      Warn = { highlight = { fg = '#e0af68' } },
      Info = { highlight = { fg = '#7dcfff' } },
      Hint = { highlight = { fg = '#9ece6a' } },
      Misc = { highlight = { fg = '#bb9af7' } },
      GitAdd = { highlight = { fg = '#9ece6a' } },
      GitChange = { highlight = { fg = '#7dcfff' } },
      GitDelete = { highlight = { fg = '#f7768e' } },
    },
  },
}
