local function toggle_git_status(state)
  require('neo-tree.command').execute {
    action = 'focus',
    source = state.name == 'git_status' and 'filesystem' or 'git_status',
    position = state.current_position,
  }
end

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
    -- The git-status source refreshes synchronously; let the filesystem watcher
    -- update the normal tree without blocking every write.
    enable_refresh_on_write = false,
    event_handlers = {
      {
        event = 'before_git_status',
        handler = function(args)
          -- Enumerating ignored files dominates git status in large repositories.
          for index, argument in ipairs(args.status_args) do
            if vim.startswith(argument, '--ignored=') then
              args.status_args[index] = '--ignored=no'
            end
          end
        end,
      },
    },
    window = {
      position = 'left',
      width = 30,
      mappings = {
        gs = { toggle_git_status, desc = 'Toggle git changes' },
      },
    },
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = 'disabled',
      filtered_items = { visible = true },
      use_libuv_file_watcher = true,
    },
    default_component_configs = {
      git_status = { symbols = {} },
    },
  },
}
