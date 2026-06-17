local function ruby_root(bufnr)
  return vim.fs.root(bufnr or 0, { 'Gemfile', '.git' }) or vim.fn.getcwd()
end

local function is_ruby_file(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.bo[bufnr].filetype == 'ruby' and name:match '%.rb$' ~= nil
end

return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require 'lint'

    local function rubocop_cmd()
      local root = ruby_root(0)
      local local_cmd = root .. '/bin/rubocop'
      if vim.fn.executable(local_cmd) == 1 then
        return local_cmd
      end
      return 'rubocop'
    end

    local function lint_ruby(bufnr)
      bufnr = bufnr or 0
      if not is_ruby_file(bufnr) then
        return
      end

      lint.try_lint('rubocop', { cwd = ruby_root(bufnr) })
    end

    if lint.linters.rubocop then
      lint.linters.rubocop.cmd = rubocop_cmd
    end

    lint.linters_by_ft = {
      ruby = { 'rubocop' },
    }

    vim.keymap.set('n', '<leader>l', function()
      if is_ruby_file(0) then
        lint_ruby(0)
      else
        lint.try_lint()
      end
    end, { desc = 'Lint buffer' })
  end,
}
