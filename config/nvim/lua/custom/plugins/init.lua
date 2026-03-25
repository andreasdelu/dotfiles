vim.keymap.set('n', '<leader>e', ':Neotree toggle filesystem left<CR>', { silent = true })
vim.keymap.set('n', '<leader>o', ':Neotree reveal left<CR>', { silent = true })

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })
vim.keymap.set('n', '<leader>cl', function()
  local path = vim.fn.expand '%:p'
  if path == '' then
    vim.notify('No file path to copy', vim.log.levels.WARN)
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local location = string.format('%s:%d', path, line)
  vim.fn.setreg('+', location)
  vim.notify('Copied ' .. location, vim.log.levels.INFO)
end, { desc = '[C]opy file [L]ocation' })

return {
  {
    'gmr458/vscode_modern_theme.nvim',
    name = 'vscode_modern',
    priority = 1000,
    config = function()
      local function apply_bg_override()
        local bg = '#1F1F1F'
        vim.api.nvim_set_hl(0, 'Normal', { bg = bg })
        vim.api.nvim_set_hl(0, 'NormalNC', { bg = bg })
        vim.api.nvim_set_hl(0, 'SignColumn', { bg = bg })
        vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = bg })
      end

      require('vscode_modern').setup {
        cursorline = true,
        transparent_background = false,
        nvim_tree_darker = true,
        custom_dark_background = '#1F1F1F',
      }
      vim.cmd.colorscheme 'vscode_modern'
      apply_bg_override()
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('custom-vscode-modern-bg', { clear = true }),
        pattern = 'vscode_modern',
        callback = apply_bg_override,
      })
    end,
  },
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
  },
  {
    'petertriho/nvim-scrollbar',
    event = 'VeryLazy',
    config = function()
      require('scrollbar').setup {
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
      }
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
          hijack_netrw_behavior = 'disabled',
          filtered_items = { visible = true },
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
