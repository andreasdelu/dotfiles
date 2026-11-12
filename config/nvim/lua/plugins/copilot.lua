return {
  'zbirenbaum/copilot.lua',
  event = 'InsertEnter',
  cmd = { 'Copilot' },
  config = function()
    local function set_copilot_suggestion_highlight()
      vim.api.nvim_set_hl(0, 'CopilotSuggestion', {
        fg = '#7f848e',
        italic = true,
      })
    end

    require('copilot').setup {
      panel = { enabled = false },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 200,
        keymap = {
          accept = '<C-l>',
          accept_word = '<C-j>',
          dismiss = '<C-]>',
          next = '<M-]>',
          prev = '<M-[>',
        },
      },
      filetypes = {
        oil = false,
        neo_tree = false,
        ['neo-tree'] = false,
        ['*'] = true,
      },
      should_attach = function(bufnr, _)
        -- Use the candidate buffer, not the current buffer or its filetype:
        -- dotenv files can be detected as sh, conf, or have no filetype at all.
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
        return not filename:match '^%.env'
          and vim.bo[bufnr].buflisted
          and vim.bo[bufnr].buftype == ''
      end,
    }

    set_copilot_suggestion_highlight()
    vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, {
      group = vim.api.nvim_create_augroup('config-copilot-highlight', { clear = true }),
      callback = set_copilot_suggestion_highlight,
    })
  end,
}
