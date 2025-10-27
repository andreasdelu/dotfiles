-- ~/.config/nvim/lua/custom/themes/dark-modern.lua
local M = {}

-- Palette tuned for a Dark+/“modern” look
local P = {
  bg = '#0f1117',
  bg2 = '#121520',
  bg3 = '#161a24',
  sel = '#232838',
  fg = '#e6e6e6',
  dim = '#9aa0a6',

  red = '#f7768e',
  green = '#9ece6a',
  yellow = '#e0af68',
  blue = '#7aa2f7',
  magenta = '#bb9af7',
  cyan = '#7dcfff',
  orange = '#ff9e64',
}

local function hi(g, o)
  vim.api.nvim_set_hl(0, g, o or {})
end

function M.load()
  vim.opt.termguicolors = true

  vim.cmd 'highlight clear'
  if vim.fn.exists 'syntax_on' == 1 then
    vim.cmd 'syntax reset'
  end
  vim.g.colors_name = 'dark-modern'

  -- UI
  hi('Normal', { fg = P.fg, bg = P.bg })
  hi('NormalNC', { fg = P.fg, bg = P.bg })
  hi('NormalFloat', { fg = P.fg, bg = P.bg })
  hi('FloatBorder', { fg = P.bg3, bg = P.bg })
  hi('WinSeparator', { fg = P.bg3 })
  hi('VertSplit', { fg = P.bg3 })
  hi('SignColumn', { bg = P.bg })
  hi('LineNr', { fg = P.dim })
  hi('CursorLine', { bg = P.bg3 })
  hi('CursorLineNr', { fg = P.yellow, bold = true })
  hi('Visual', { bg = P.sel })
  hi('Search', { fg = P.bg, bg = P.yellow })
  hi('IncSearch', { fg = P.bg, bg = P.orange })
  hi('MatchParen', { fg = P.orange, bold = true })
  hi('Pmenu', { fg = P.fg, bg = P.bg2 })
  hi('PmenuSel', { fg = P.bg, bg = P.blue, bold = true })
  hi('PmenuSbar', { bg = P.bg3 })
  hi('PmenuThumb', { bg = P.dim })
  hi('StatusLine', { fg = P.fg, bg = P.bg2 })
  hi('StatusLineNC', { fg = P.dim, bg = P.bg2 })
  hi('TabLine', { fg = P.dim, bg = P.bg2 })
  hi('TabLineSel', { fg = P.fg, bg = P.bg })
  hi('TabLineFill', { bg = P.bg2 })
  hi('Folded', { fg = P.dim, bg = P.bg2 })
  hi('FoldColumn', { fg = P.dim, bg = P.bg })

  -- Base syntax (no italics)
  hi('Comment', { fg = P.dim }) -- no italics
  hi('Constant', { fg = P.cyan })
  hi('String', { fg = P.green })
  hi('Character', { fg = P.green })
  hi('Number', { fg = P.orange })
  hi('Boolean', { fg = P.orange })
  hi('Float', { fg = P.orange })
  hi('Identifier', { fg = P.fg })
  hi('Function', { fg = P.blue, bold = true })
  hi('Statement', { fg = P.magenta })
  hi('Operator', { fg = P.cyan })
  hi('Keyword', { fg = P.magenta }) -- no italics
  hi('Type', { fg = P.yellow })
  hi('Special', { fg = P.blue })
  hi('Delimiter', { fg = P.dim })
  hi('Todo', { fg = P.bg, bg = P.yellow, bold = true })

  -- Treesitter links (keep consistent across languages)
  hi('@variable', { link = 'Identifier' })
  hi('@constant', { link = 'Constant' })
  hi('@string', { link = 'String' })
  hi('@number', { link = 'Number' })
  hi('@boolean', { link = 'Boolean' })
  hi('@operator', { link = 'Operator' })
  hi('@function', { link = 'Function' })
  hi('@method', { link = '@function' })
  hi('@keyword', { link = 'Keyword' })
  hi('@type', { link = 'Type' })
  hi('@property', { link = 'Identifier' })
  hi('@field', { link = 'Identifier' })
  hi('@parameter', { fg = P.fg })
  hi('@punctuation', { link = 'Delimiter' })
  hi('@comment', { link = 'Comment' })

  -- Languages: JS/TS/React feel like the screenshot
  hi('@variable.builtin', { fg = P.cyan }) -- e.g., global objects
  hi('@constant.builtin', { fg = P.orange })
  hi('@constructor', { fg = P.yellow })
  hi('@tag', { fg = P.blue })
  hi('@tag.attribute', { fg = P.cyan })
  hi('@tag.delimiter', { fg = P.dim })

  -- LSP diagnostics
  hi('DiagnosticError', { fg = P.red })
  hi('DiagnosticWarn', { fg = P.yellow })
  hi('DiagnosticInfo', { fg = P.cyan })
  hi('DiagnosticHint', { fg = P.green })
  hi('DiagnosticOk', { fg = P.green })
  hi('DiagnosticUnderlineError', { undercurl = true, sp = P.red })
  hi('DiagnosticUnderlineWarn', { undercurl = true, sp = P.yellow })
  hi('DiagnosticUnderlineInfo', { undercurl = true, sp = P.cyan })
  hi('DiagnosticUnderlineHint', { undercurl = true, sp = P.green })

  -- Diff/Git
  hi('DiffAdd', { fg = P.green, bg = P.bg2 })
  hi('DiffChange', { fg = P.yellow, bg = P.bg2 })
  hi('DiffDelete', { fg = P.red, bg = P.bg2 })
  hi('DiffText', { fg = P.blue, bg = P.bg2, bold = true })

  -- Telescope (subtle chrome)
  hi('TelescopeNormal', { fg = P.fg, bg = P.bg })
  hi('TelescopeBorder', { fg = P.bg3, bg = P.bg })
  hi('TelescopePromptNormal', { fg = P.fg, bg = P.bg })
  hi('TelescopePromptBorder', { fg = P.bg3, bg = P.bg })
  hi('TelescopeSelection', { bg = P.sel })
  hi('TelescopeMatching', { fg = P.orange, bold = true })
end

return M
