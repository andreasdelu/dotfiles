return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local has_eslint = #vim.lsp.get_clients { bufnr = bufnr, name = 'eslint' } > 0
        if has_eslint then
          pcall(vim.cmd, 'LspEslintFixAll')
        end

        require('conform').format { async = false, lsp_format = 'never' }
      end,
      mode = { 'n', 'v' },
      desc = 'Fix and format buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local format_on_save_filetypes = {
        lua = true,
        javascript = true,
        javascriptreact = true,
        typescript = true,
        typescriptreact = true,
        ruby = true,
        json = true,
        jsonc = true,
        css = true,
        scss = true,
        markdown = true,
      }

      if not format_on_save_filetypes[vim.bo[bufnr].filetype] then
        return nil
      end

      return {
        timeout_ms = 1000,
        lsp_format = 'never',
      }
    end,
    formatters = {
      syntax_tree = {
        command = 'bin/stree',
        cwd = function(self, ctx)
          return require('conform.util').root_file { 'Gemfile', '.git' }(self, ctx)
        end,
      },
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      javascript = { 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      ruby = { 'syntax_tree' },
      json = { 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      css = { 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      scss = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
    },
  },
}
