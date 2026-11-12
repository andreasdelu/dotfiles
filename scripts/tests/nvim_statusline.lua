-- Check the rendered badge through edit/save transitions, not just config flags.
local repo = assert(vim.env.DOTFILES_TEST_REPO)
vim.opt.rtp:append(vim.fn.stdpath 'data' .. '/lazy/mini.statusline')
local spec = dofile(repo .. '/config/nvim/lua/plugins/statusline.lua')
spec.config(nil, { use_icons = false })
local function badge_visible()
  local result = vim.api.nvim_eval_statusline(MiniStatusline.active(), { highlights = true, maxwidth = 200 })
  for _, span in ipairs(result.highlights) do
    if vim.list_contains(span.groups or {}, 'MiniStatuslineModified') then
      local text = result.str:sub(span.start + 1, span.start + 3)
      if text:find('*', 1, true) then return true end
    end
  end
  return false
end
local file = vim.fn.tempname()
vim.cmd.edit(file)
assert(not badge_visible(), 'clean buffer showed unsaved badge')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unsaved edit' })
assert(badge_visible(), 'edited buffer did not show yellow badge')
vim.cmd.write()
assert(not badge_visible(), 'saved buffer kept unsaved badge')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'another edit' })
vim.api.nvim_exec_autocmds('ColorScheme', {})
assert(badge_visible(), 'badge lost after colorscheme change')
assert(vim.api.nvim_get_hl(0, { name = 'MiniStatuslineModified' }).bg == tonumber('e0af68', 16))
vim.fn.delete(file)
print('PASS: unsaved statusline badge on edit, save, and colorscheme change')
vim.cmd 'qall!'
