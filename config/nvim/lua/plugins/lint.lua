local function ruby_root(bufnr)
  return vim.fs.root(bufnr or 0, { 'Gemfile', '.git' }) or vim.fn.getcwd()
end

local function is_landfolk_api_root(root)
  if type(root) ~= 'string' then
    return false
  end

  return root:match '/Documents/landfolk/apps/api$' ~= nil
    or root:match '/Documents/lf%-worktrees/[^/]+/apps/api$' ~= nil
    or root:match '/Documents/landfolk%-worktrees/[^/]+/apps/api$' ~= nil
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

      local root = ruby_root(bufnr)
      local linter = is_landfolk_api_root(root) and 'landfolk_api_rubocop' or 'rubocop'
      lint.try_lint(linter, { cwd = root })
    end

    if lint.linters.rubocop then
      lint.linters.rubocop.cmd = rubocop_cmd
      lint.linters.landfolk_api_rubocop = vim.tbl_deep_extend('force', {}, lint.linters.rubocop, {
        cmd = 'nix',
        args = {
          'develop',
          '../..#api',
          '-c',
          './bin/rubocop',
          '--format',
          'json',
          '--force-exclusion',
          '--server',
          '--stdin',
          function()
            return vim.api.nvim_buf_get_name(0)
          end,
        },
      })
    end

    lint.linters_by_ft = {
      ruby = { 'rubocop' },
    }

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = vim.api.nvim_create_augroup('config-ruby-lint', { clear = true }),
      callback = function(args)
        if vim.bo[args.buf].modifiable then
          lint_ruby(args.buf)
        end
      end,
    })

    vim.keymap.set('n', '<leader>l', function()
      if is_ruby_file(0) then
        lint_ruby(0)
      else
        lint.try_lint()
      end
    end, { desc = 'Lint buffer' })
  end,
}
