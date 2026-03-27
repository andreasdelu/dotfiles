return {
  'petertriho/nvim-scrollbar',
  event = 'VeryLazy',
  opts = {
    show = true,
    show_in_active_only = false,
    hide_if_all_visible = false,
    excluded_buftypes = { 'terminal', 'prompt', 'nofile' },
    excluded_filetypes = { 'neo-tree', 'neo-tree-popup', 'TelescopePrompt' },
    handlers = {
      cursor = false,
      diagnostic = true,
      gitsigns = true,
      handle = true,
      search = false,
    },
    marks = {
      Search = { color = '#7aa2f7' },
      Error = { color = '#f7768e' },
      Warn = { color = '#e0af68' },
      Info = { color = '#7dcfff' },
      Hint = { color = '#9ece6a' },
      Misc = { color = '#bb9af7' },
      GitAdd = { color = '#9ece6a' },
      GitChange = { color = '#7dcfff' },
      GitDelete = { color = '#f7768e' },
    },
  },
}
