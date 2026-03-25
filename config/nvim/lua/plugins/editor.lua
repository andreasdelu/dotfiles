local function statusline_diagnostic_badge()
  local bufnr = vim.api.nvim_get_current_buf()
  local errors = #vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.WARN })

  if errors > 0 and warnings > 0 then
    return {
      { text = string.format('ERROR %d', errors), hl = 'MiniStatuslineDiagnosticError' },
      { text = string.format('WARN %d', warnings), hl = 'MiniStatuslineDiagnosticWarn' },
    }
  end

  if errors > 0 then
    return {
      { text = string.format('ERROR %d', errors), hl = 'MiniStatuslineDiagnosticError' },
    }
  end

  if warnings > 0 then
    return {
      { text = string.format('WARN %d', warnings), hl = 'MiniStatuslineDiagnosticWarn' },
    }
  end

  return {}
end

local function set_statusline_highlights()
  vim.api.nvim_set_hl(0, 'MiniStatuslineDiagnosticError', { fg = '#0f1117', bg = '#f7768e', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineDiagnosticWarn', { fg = '#0f1117', bg = '#e0af68', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGitAdd', { fg = '#9ece6a', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGitChange', { fg = '#7dcfff', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGitDelete', { fg = '#f7768e', bold = true })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModified', { fg = '#0f1117', bg = '#e0af68', bold = true })
end

local function statusline_git_totals()
  local git = vim.b.gitsigns_status_dict
  if type(git) ~= 'table' then
    return ''
  end

  local parts = {}
  if (git.added or 0) > 0 then
    table.insert(parts, string.format('%%#MiniStatuslineGitAdd# +%d', git.added))
  end
  if (git.changed or 0) > 0 then
    table.insert(parts, string.format('%%#MiniStatuslineGitChange#~%d', git.changed))
  end
  if (git.removed or 0) > 0 then
    table.insert(parts, string.format('%%#MiniStatuslineGitDelete#-%d', git.removed))
  end

  return table.concat(parts, '')
end

local function format_filesize()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == '' then
    return ''
  end

  local size = vim.fn.getfsize(bufname)
  if size <= 0 then
    return ''
  end

  local units = { 'B', 'K', 'M', 'G' }
  local value = size
  local unit = units[1]

  for i = 2, #units do
    if value < 1024 then
      break
    end

    value = value / 1024
    unit = units[i]
  end

  if unit == 'B' then
    return string.format('%d%s', value, unit)
  end

  return string.format('%.1f%s', value, unit)
end

return {
  { 'NMAC427/guess-indent.nvim' },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      spec = {
        { '<leader>s', group = 'Search' },
        { '<leader>g', group = 'Git' },
        { '<leader>t', group = 'Test / Toggle' },
        { '<leader>c', group = 'Claude / Copy' },
        { '<leader>h', group = 'Git Hunk', mode = { 'n', 'v' } },
      },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    opts = {
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

        map('v', '<leader>hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'Git stage hunk')
        map('v', '<leader>hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'Git reset hunk')
        map('n', '<leader>hs', gitsigns.stage_hunk, 'Git stage hunk')
        map('n', '<leader>hr', gitsigns.reset_hunk, 'Git reset hunk')
        map('n', '<leader>hS', gitsigns.stage_buffer, 'Git stage buffer')
        map('n', '<leader>hu', gitsigns.undo_stage_hunk, 'Git undo stage hunk')
        map('n', '<leader>hR', gitsigns.reset_buffer, 'Git reset buffer')
        map('n', '<leader>hp', gitsigns.preview_hunk, 'Git preview hunk')
        map('n', '<leader>hb', gitsigns.blame_line, 'Git blame line')
        map('n', '<leader>hd', gitsigns.diffthis, 'Git diff against index')
        map('n', '<leader>hD', function()
          gitsigns.diffthis '@'
        end, 'Git diff against last commit')
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, 'Toggle git blame line')
        map('n', '<leader>tD', gitsigns.toggle_deleted, 'Toggle deleted lines')
      end,
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()

      local statusline = require 'mini.statusline'

      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
            local lsp = statusline.section_lsp({ trunc_width = 75 })
            local filename = statusline.section_filename({ trunc_width = 140 })
            local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
            local location = statusline.section_location({ trunc_width = 75 })
            local search = statusline.section_searchcount({ trunc_width = 75 })
            local groups = {
              { hl = mode_hl, strings = { mode } },
              { hl = 'MiniStatuslineModified', strings = vim.bo.modified and { '*' } or {} },
              { hl = 'MiniStatuslineDevinfo', strings = { lsp } },
              '%<',
              { hl = 'MiniStatuslineFilename', strings = { filename } },
            }

            for _, badge in ipairs(statusline_diagnostic_badge()) do
              table.insert(groups, { hl = badge.hl, strings = { badge.text } })
            end

            table.insert(groups, '%=')
            table.insert(groups, statusline_git_totals())
            table.insert(groups, { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } })
            table.insert(groups, { hl = mode_hl, strings = { search, location } })

            return statusline.combine_groups(groups)
          end,
        },
      }

      set_statusline_highlights()

      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('config-statusline-highlights', { clear = true }),
        callback = set_statusline_highlights,
      })

      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('config-statusline-gitsigns', { clear = true }),
        pattern = 'GitSignsUpdate',
        callback = vim.schedule_wrap(function()
          vim.cmd 'redrawstatus'
        end),
      })

      statusline.section_location = function()
        return '%2l:%-2v'
      end

      statusline.section_fileinfo = function(args)
        if statusline.is_truncated(args.trunc_width) then
          return ''
        end

        local filetype = vim.bo.filetype ~= '' and vim.bo.filetype or 'no ft'
        local size = format_filesize()
        return size ~= '' and string.format('%s %s', filetype, size) or filetype
      end
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'diff',
        'graphql',
        'html',
        'javascript',
        'jsdoc',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'ruby',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
  },
  {
    'kevinhwang91/nvim-ufo',
    event = 'VeryLazy',
    dependencies = { 'kevinhwang91/promise-async' },
    init = function()
      vim.opt.foldcolumn = '1'
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
      vim.opt.foldenable = true
    end,
    opts = {
      provider_selector = function(_, filetype)
        if filetype == 'gitcommit' or filetype == 'markdown' then
          return { 'indent' }
        end

        return { 'treesitter', 'indent' }
      end,
    },
    config = function(_, opts)
      local ufo = require 'ufo'
      ufo.setup(opts)

      vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = 'Open all folds' })
      vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = 'Close all folds' })
      vim.keymap.set('n', 'zr', ufo.openFoldsExceptKinds, { desc = 'Open folds except kinds' })
      vim.keymap.set('n', 'zm', function()
        ufo.closeFoldsWith()
      end, { desc = 'Close folds with' })
      vim.keymap.set('n', 'K', function()
        local winid = ufo.peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end, { desc = 'Peek folded lines or hover' })
    end,
  },
}
