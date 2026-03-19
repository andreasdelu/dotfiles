return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      if lint.linters.rubocop then
        lint.linters.rubocop.cmd = 'bin/rubocop'
      end

      lint.linters_by_ft = {
        ruby = { 'rubocop' },
      }

      local lint_augroup = vim.api.nvim_create_augroup('custom-lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })

      vim.keymap.set('n', '<leader>l', function()
        lint.try_lint()
      end, { desc = '[L]int buffer' })
    end,
  },
}
