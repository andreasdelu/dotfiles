vim.keymap.set('n', '<leader>e', ':Neotree toggle filesystem left<CR>', { silent = true })
vim.keymap.set('n', '<leader>o', ':Neotree reveal left<CR>', { silent = true })

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })

return {
  --{
  --dir = vim.fn.stdpath 'config',
  --lazy = false,
  --priority = 1000,
  --config = function()
  --vim.cmd.colorscheme 'dark-modern' -- this calls colors/dark-modern.lua
  --end,
  --},
  {
    'rockyzhang24/arctic.nvim',
    dependencies = { 'rktjmp/lush.nvim' },
    name = 'arctic',
    branch = 'v2',
    priority = 1000,
    config = function()
      vim.cmd 'colorscheme arctic'
    end,
  },
  {

    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    config = function()
      require('neo-tree').setup {
        window = { position = 'left', width = 30 },
        filesystem = {
          follow_current_file = { enabled = true },
          filtered_items = { visible = false },
        },
        default_component_configs = {
          git_status = { symbols = {} },
        },
      }
    end,
  },
  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neo-tree/neo-tree.nvim', -- makes sure that this loads after Neo-tree.
    },
    config = function()
      require('lsp-file-operations').setup()
    end,
  },
  {
    's1n7ax/nvim-window-picker',
    version = '2.*',
    config = function()
      require('window-picker').setup {
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          -- filter using buffer options
          bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = { 'neo-tree', 'neo-tree-popup', 'notify' },
            -- if the buffer type is one of following, the window will be ignored
            buftype = { 'terminal', 'quickfix' },
          },
        },
      }
    end,
  },
  {
    'greggh/claude-code.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim', -- Required for git operations
    },
    config = function()
      require('claude-code').setup {
        window = {
          position = 'vertical',
        },
        command = 'claude',
      }
    end,
  },
}
