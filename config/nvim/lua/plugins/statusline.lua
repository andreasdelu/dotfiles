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
  'echasnovski/mini.statusline',
  dependencies = { 'lewis6991/gitsigns.nvim' },
  config = function()
    local statusline = require 'mini.statusline'

    statusline.setup {
      use_icons = vim.g.have_nerd_font,
      content = {
        active = function()
          local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
          local lsp = statusline.section_lsp { trunc_width = 75 }
          local filename = statusline.section_filename { trunc_width = 140 }
          local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
          local location = statusline.section_location { trunc_width = 75 }
          local search = statusline.section_searchcount { trunc_width = 75 }
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
}
