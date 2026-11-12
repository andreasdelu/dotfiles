-- Exercise real mapped scrolling and its scrollbar post-hook, not startup alone.
local repo = assert(vim.env.DOTFILES_TEST_REPO)
for _, plugin in ipairs { 'neoscroll.nvim', 'nvim-scrollbar', 'gitsigns.nvim' } do
  vim.opt.rtp:append(vim.fn.stdpath 'data' .. '/lazy/' .. plugin)
end
require('scrollbar').setup(dofile(repo .. '/config/nvim/lua/plugins/scrollbar.lua').opts)
local opts = dofile(repo .. '/config/nvim/lua/plugins/neoscroll.lua').opts
local completed = 0
local post_hook = opts.post_hook
opts.post_hook = function(...)
  post_hook(...)
  completed = completed + 1
end
require('neoscroll').setup(opts)
vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn['repeat']({ 'test line' }, 500))
vim.api.nvim_win_set_cursor(0, { 100, 0 })
vim.cmd 'normal! zz'
local initial = vim.fn.line '.'
for index, key in ipairs { '<C-d>', '<C-u>', '<C-d>' } do
  local before = vim.fn.line '.'
  vim.fn.maparg(key, 'n', false, true).callback()
  assert(vim.wait(3000, function() return completed == index end, 10), key .. ' did not complete')
  local after = vim.fn.line '.'
  assert(key == '<C-u>' and after < before or key == '<C-d>' and after > before, key .. ' did not move the cursor')
end
assert(vim.fn.line '.' > initial)
print('PASS: repeated Ctrl-D/Ctrl-U scrolling with scrollbar post-hook')
vim.cmd 'qall!'
