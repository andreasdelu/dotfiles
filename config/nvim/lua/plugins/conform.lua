local function is_ruby_file(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.bo[bufnr].filetype == 'ruby' and name:match '%.rb$' ~= nil
end

local function ruby_root(bufnr)
  return vim.fs.root(bufnr or 0, { 'Gemfile', '.git' })
end

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

        if vim.bo[bufnr].filetype == 'ruby' and not is_ruby_file(bufnr) then
          return
        end

        require('conform').format {
          async = false,
          timeout_ms = vim.bo[bufnr].filetype == 'ruby' and 30000 or nil,
          lsp_format = 'never',
        }
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
        json = true,
        jsonc = true,
        css = true,
        scss = true,
        markdown = true,
        ruby = true,
        rust = true,
      }

      if not format_on_save_filetypes[vim.bo[bufnr].filetype] then
        return nil
      end

      if vim.bo[bufnr].filetype == 'ruby' and not is_ruby_file(bufnr) then
        return nil
      end

      return {
        timeout_ms = vim.bo[bufnr].filetype == 'ruby' and 5000 or 1000,
        lsp_format = 'never',
      }
    end,
    formatters = {
      syntax_tree = function(bufnr)
        local root = ruby_root(bufnr) or vim.fn.getcwd()
        return {
          inherit = false,
          command = root .. '/bin/stree',
          stdin = false,
          args = { 'write', '$FILENAME' },
          cwd = function()
            return root
          end,
        }
      end,
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      javascript = { 'oxfmt', 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'oxfmt', 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'oxfmt', 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'oxfmt', 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      ruby = { 'syntax_tree' },
      rust = { 'rustfmt' },
      json = { 'oxfmt', 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'oxfmt', 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      css = { 'oxfmt', 'biome-check', 'prettierd', 'prettier', stop_after_first = true },
      scss = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
    },
  },
}
