return {
  'echasnovski/mini.statusline',
  opts = { use_icons = vim.g.have_nerd_font },
  config = function(_, opts)
    local statusline = require 'mini.statusline'
    statusline.setup(opts)

    -- Keep the default layout, but badge unsaved edits beside the mode.
    local section_mode = statusline.section_mode
    statusline.section_mode = function(args)
      local mode, highlight = section_mode(args)
      if vim.bo.modified then
        mode = mode .. ' %#MiniStatuslineModified# * %#' .. highlight .. '#'
      end
      return mode, highlight
    end

    local function set_modified_highlight()
      vim.api.nvim_set_hl(0, 'MiniStatuslineModified', { fg = '#0f1117', bg = '#e0af68', bold = true })
    end
    set_modified_highlight()
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('config-statusline-modified', { clear = true }),
      callback = set_modified_highlight,
    })
  end,
}
