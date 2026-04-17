return {
  'Exafunction/windsurf.nvim',
  event = 'InsertEnter',
  cmd = { 'Codeium' },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    local function set_codeium_suggestion_highlight()
      vim.api.nvim_set_hl(0, 'CodeiumSuggestion', {
        fg = '#7f848e',
        italic = true,
      })
    end

    require('codeium').setup {
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        idle_delay = 200,
        filetypes = {
          oil = false,
          neo_tree = false,
          ['neo-tree'] = false,
        },
        default_filetype_enabled = true,
        map_keys = true,
        key_bindings = {
          accept = '<C-l>',
          accept_word = '<C-j>',
          clear = '<C-]>',
          next = '<M-]>',
          prev = '<M-[>',
        },
      },
    }

    set_codeium_suggestion_highlight()
    vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, {
      group = vim.api.nvim_create_augroup('config-codeium-highlight', { clear = true }),
      callback = set_codeium_suggestion_highlight,
    })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertEnter' }, {
      group = vim.api.nvim_create_augroup('config-codeium-env-disable', { clear = true }),
      callback = function(args)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ':t')
        local ok, codeium = pcall(require, 'codeium')
        if not ok then
          return
        end

        if filename:match '^%.env' then
          codeium.disable()
          pcall(function()
            require('codeium.virtual_text').clear()
          end)
          return
        end

        codeium.enable()
      end,
    })
  end,
}
