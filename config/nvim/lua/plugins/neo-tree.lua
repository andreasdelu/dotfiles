return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
    's1n7ax/nvim-window-picker',
  },
  opts = {
    window = { position = 'left', width = 30 },
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = 'disabled',
      filtered_items = { visible = true },
    },
    default_component_configs = {
      git_status = { symbols = {} },
    },
  },
}
