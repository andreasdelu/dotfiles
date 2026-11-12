-- Validate the real plugin's config, attachment policy and mappings offline.
local repo = assert(vim.env.DOTFILES_TEST_REPO)
vim.opt.rtp:append(vim.fn.stdpath 'data' .. '/lazy/copilot.lua')
-- Stop at the server startup boundary: no downloads, authentication or LSP.
require('copilot.command').enable = function() end
local spec = dofile(repo .. '/config/nvim/lua/plugins/copilot.lua')
assert(spec.event == 'InsertEnter' and vim.tbl_contains(spec.cmd, 'Copilot'))
spec.config()
local config = require 'copilot.config'
assert(config.suggestion.enabled and config.suggestion.auto_trigger)
assert(not config.panel.enabled)

local function buffer(name, ft, listed, buftype)
  local buf = vim.api.nvim_create_buf(listed ~= false, false)
  vim.api.nvim_buf_set_name(buf, '/tmp/dotfiles-copilot-test/' .. name)
  vim.bo[buf].filetype = ft or ''
  vim.bo[buf].buftype = buftype or ''
  return buf
end
local allowed = buffer('app.lua', 'lua')
vim.api.nvim_set_current_buf(allowed)
local should_attach = require('copilot.util').should_attach
assert(should_attach(allowed))
-- Candidate is deliberately not current: a current-buffer check leaks secrets.
for _, name in ipairs { '.env', '.env.local', '.envrc', '.environment' } do
  for _, ft in ipairs { '', 'sh', 'conf', 'lua' } do
    assert(not should_attach(buffer(name .. (ft == '' and '' or '.' .. ft), ft)), name .. ' attached as ' .. ft)
  end
end
for _, ft in ipairs { 'oil', 'neo_tree', 'neo-tree' } do
  assert(not should_attach(buffer('explorer-' .. ft, ft)))
end
assert(not should_attach(buffer('unlisted.lua', 'lua', false)))
assert(not should_attach(buffer('scratch.lua', 'lua', true, 'nofile')))
assert(should_attach(buffer('environment.lua', 'lua')))
-- A denied current buffer must not disable a different, safe candidate.
vim.api.nvim_set_current_buf(buffer('.env.secret', 'sh'))
assert(should_attach(allowed))
vim.api.nvim_set_current_buf(allowed)
require('copilot.suggestion').set_keymap(allowed)
for key, action in pairs {
  ['<C-l>'] = 'accept suggestion',
  ['<C-j>'] = 'accept suggestion (word)',
  ['<C-]>'] = 'dismiss suggestion',
  ['<M-]>'] = 'next suggestion',
  ['<M-[>'] = 'prev suggestion',
} do
  local mapping = vim.fn.maparg(key, 'i', false, true)
  assert(mapping.buffer == 1 and mapping.desc == '[copilot] ' .. action, key .. ' has wrong action')
end
vim.api.nvim_set_hl(0, 'CopilotSuggestion', { fg = '#ffffff' })
vim.api.nvim_exec_autocmds('ColorScheme', {})
local hl = vim.api.nvim_get_hl(0, { name = 'CopilotSuggestion', link = false })
assert(hl.fg == tonumber('7f848e', 16) and hl.italic)
print('PASS: Copilot offline config, filename attachment guard, mappings and highlight')
vim.cmd 'qall!'
