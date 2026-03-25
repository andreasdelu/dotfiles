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
        group = vim.api.nvim_create_augroup('config-vscode-modern-bg', { clear = true }),
        pattern = 'vscode_modern',
        callback = apply_bg_override,
      })
    end,
  },
}
