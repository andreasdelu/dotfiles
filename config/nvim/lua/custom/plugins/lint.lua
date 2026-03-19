return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      local function ruby_root(bufnr)
        return vim.fs.root(bufnr or 0, { 'Gemfile', '.git' }) or vim.fn.getcwd()
      end

      local function rubocop_cmd(bufnr)
        local root = ruby_root(bufnr)
        local local_cmd = root .. '/bin/rubocop'
        if vim.fn.executable(local_cmd) == 1 then
          return local_cmd
        end
        return 'rubocop'
      end

      local function lint_ruby()
        lint.try_lint('rubocop', { cwd = ruby_root(0) })
      end

      if lint.linters.rubocop then
        lint.linters.rubocop.cmd = function()
          return rubocop_cmd(0)
        end
      end

      lint.linters_by_ft = {
        ruby = { 'rubocop' },
      }

      local lint_augroup = vim.api.nvim_create_augroup('custom-lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if vim.bo.modifiable and vim.bo.filetype == 'ruby' then
            lint_ruby()
          end
        end,
      })

      vim.keymap.set('n', '<leader>l', function()
        if vim.bo.filetype == 'ruby' then
          lint_ruby()
        else
          lint.try_lint()
        end
      end, { desc = '[L]int buffer' })
    end,
  },
}
