return {
  'lewis6991/gitsigns.nvim',
  config = function()
    local function git_merge_base()
      local root = vim.fs.root(0, { '.git' }) or vim.fn.getcwd()
      for _, ref in ipairs { 'origin/main', 'origin/master' } do
        local result = vim.system({ 'git', 'merge-base', 'HEAD', ref }, { cwd = root, text = true }):wait()
        if result.code == 0 and result.stdout and result.stdout ~= '' then
          return vim.trim(result.stdout)
        end
      end
      return nil
    end

    local cached_merge_base = nil

    local function refresh_merge_base()
      cached_merge_base = git_merge_base()
    end

    local function auto_switch_base(bufnr)
      local file = vim.api.nvim_buf_get_name(bufnr)
      if file == '' then
        return
      end
      local root = vim.fs.root(bufnr, { '.git' }) or vim.fn.getcwd()
      local result = vim.system({ 'git', 'diff', '--quiet', 'HEAD', '--', file }, { cwd = root }):wait()
      local is_dirty = result.code ~= 0

      if is_dirty then
        require('gitsigns').change_base(nil, bufnr)
      elseif cached_merge_base then
        require('gitsigns').change_base(cached_merge_base, bufnr)
      end
    end

    local augroup = vim.api.nvim_create_augroup('config-gitsigns-auto-base', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
      group = augroup,
      callback = function(ev)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            auto_switch_base(ev.buf)
          end
        end)
      end,
    })

    vim.api.nvim_create_autocmd('VimEnter', {
      group = augroup,
      once = true,
      callback = function()
        vim.schedule(refresh_merge_base)
      end,
    })

    require('gitsigns').setup {
      update_debounce = 50,
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, 'Jump to next git change')

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, 'Jump to previous git change')

        map('v', '<leader>ghs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'Git stage hunk')
        map('v', '<leader>ghr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'Git reset hunk')
        map('n', '<leader>ghs', gitsigns.stage_hunk, 'Git stage hunk')
        map('n', '<leader>ghr', gitsigns.reset_hunk, 'Git reset hunk')
        map('n', '<leader>ghS', gitsigns.stage_buffer, 'Git stage buffer')
        map('n', '<leader>ghu', gitsigns.undo_stage_hunk, 'Git undo stage hunk')
        map('n', '<leader>ghR', gitsigns.reset_buffer, 'Git reset buffer')
        map('n', '<leader>ghp', gitsigns.preview_hunk, 'Git preview hunk')
        map('n', '<leader>ghb', gitsigns.blame_line, 'Git blame line')
        map('n', '<leader>ghd', gitsigns.diffthis, 'Git diff against index')
        map('n', '<leader>ghD', function()
          gitsigns.diffthis '@'
        end, 'Git diff against last commit')
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, 'Toggle git blame line')
        map('n', '<leader>tD', gitsigns.toggle_deleted, 'Toggle deleted lines')
      end,
    }
  end,
}
