local function has_special_startup_arg()
  for index = 2, #vim.v.argv do
    local arg = vim.v.argv[index]
    if arg == '-' or arg == '-S' or arg:match('^-S.') or arg == '-c' or arg:match('^-c.') or arg:match('^%+') then
      return true
    end
  end

  return false
end

local function auto_session_cwd()
  if has_special_startup_arg() then
    return nil
  end

  if not vim.env.TMUX then
    return nil
  end

  if #vim.api.nvim_list_uis() == 0 then
    return nil
  end

  if vim.v.this_session ~= '' or vim.g.this_obsession then
    return nil
  end

  local cwd = vim.fn.getcwd()
  if cwd == vim.env.HOME then
    return nil
  end

  local current_buffer = vim.api.nvim_get_current_buf()
  if vim.bo[current_buffer].buftype ~= '' then
    return nil
  end

  local filetype = vim.bo[current_buffer].filetype
  if filetype == 'gitcommit' or filetype == 'gitrebase' then
    return nil
  end

  local result = vim.system({ 'git', '-C', cwd, 'rev-parse', '--is-inside-work-tree' }, { text = true }):wait()
  if result.code == 0 and result.stdout:match('true') ~= nil then
    return cwd
  end
end

local function auto_track_session()
  vim.schedule(function()
    local cwd = auto_session_cwd()
    if not cwd then
      return
    end

    if vim.fn.filereadable(cwd .. '/Session.vim') == 0 then
      vim.cmd('silent! Obsession ' .. vim.fn.fnameescape(cwd))
    end
  end)
end

return {
  'tpope/vim-obsession',
  lazy = false,
  config = function()
    vim.api.nvim_create_autocmd('VimEnter', {
      group = vim.api.nvim_create_augroup('auto_obsession', { clear = true }),
      callback = auto_track_session,
      desc = 'Automatically track tmux Neovim sessions in git worktrees',
    })

    auto_track_session()
  end,
}
