local function ruby_root(bufnr)
  return vim.fs.root(bufnr or 0, { 'Gemfile', '.git' }) or vim.fn.getcwd()
end

local function relative_to_root(path, root)
  local prefix = root .. '/'
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end

  return path
end

local function file_exists(path)
  return path and vim.uv.fs_stat(path) ~= nil
end

local function current_path()
  return vim.api.nvim_buf_get_name(0)
end

local function spec_candidates(path)
  local root = ruby_root(0)
  local relative = relative_to_root(path, root)
  local candidates = {}

  if relative:match('^app/.+%.rb$') then
    table.insert(candidates, root .. '/' .. relative:gsub('^app/', 'spec/'):gsub('%.rb$', '_spec.rb'))
  end

  if relative:match('^lib/.+%.rb$') then
    table.insert(candidates, root .. '/' .. relative:gsub('^lib/', 'spec/'):gsub('%.rb$', '_spec.rb'))
  end

  if relative:match('^gems/[^/]+/lib/.+%.rb$') then
    table.insert(candidates, root .. '/' .. relative:gsub('/lib/', '/spec/'):gsub('%.rb$', '_spec.rb'))
  end

  local stem = relative:gsub('%.rb$', '')
  local basename = vim.fs.basename(stem)
  for _, match in ipairs(vim.fn.glob(root .. '/spec/**/' .. basename .. '_spec.rb', false, true)) do
    if not vim.tbl_contains(candidates, match) then
      table.insert(candidates, match)
    end
  end

  return candidates
end

local function spec_path_for(path)
  local root = ruby_root(0)
  local relative = relative_to_root(path, root)
  if relative:match '_spec%.rb$' then
    return path
  end

  local candidates = spec_candidates(path)
  for _, candidate in ipairs(candidates) do
    if file_exists(candidate) then
      return candidate
    end
  end

  return candidates[1]
end

local function source_candidates(path)
  local root = ruby_root(0)
  local relative = relative_to_root(path, root)
  local candidates = {}

  if relative:match('^spec/.+_spec%.rb$') then
    table.insert(candidates, root .. '/' .. relative:gsub('^spec/', 'app/'):gsub('_spec%.rb$', '.rb'))
  end

  if relative:match('^gems/[^/]+/spec/.+_spec%.rb$') then
    table.insert(candidates, root .. '/' .. relative:gsub('/spec/', '/lib/'):gsub('_spec%.rb$', '.rb'))
  end

  local stem = relative:gsub('^spec/', ''):gsub('_spec%.rb$', '.rb')
  for _, prefix in ipairs({ 'app/', 'lib/' }) do
    local candidate = root .. '/' .. prefix .. stem
    if not vim.tbl_contains(candidates, candidate) then
      table.insert(candidates, candidate)
    end
  end

  return candidates
end

local function source_path_for(path)
  local candidates = source_candidates(path)
  for _, candidate in ipairs(candidates) do
    if file_exists(candidate) then
      return candidate
    end
  end

  return candidates[1]
end

local function open_spec()
  local path = current_path()
  if path == '' then
    return
  end

  local root = ruby_root(0)
  local relative = relative_to_root(path, root)
  if relative:match('^spec/') and relative:match '_spec%.rb$' then
    local source = source_path_for(path)
    if file_exists(source) then
      vim.cmd.edit(vim.fn.fnameescape(source))
    else
      vim.notify('No matching source file found for ' .. path, vim.log.levels.WARN)
    end
    return
  end

  local spec = spec_path_for(path)
  if file_exists(spec) then
    vim.cmd.edit(vim.fn.fnameescape(spec))
  else
    vim.notify('No matching spec found for ' .. path, vim.log.levels.WARN)
  end
end

local function current_spec_path()
  local path = current_path()
  local root = ruby_root(0)
  local relative = relative_to_root(path, root)

  if relative:match('^spec/') and relative:match '_spec%.rb$' then
    return path
  end

  vim.notify('Open the spec file first to run from the current line', vim.log.levels.WARN)
  return nil
end

local function rspec_command(target)
  local root = ruby_root(0)
  local local_rspec = root .. '/bin/rspec'
  local command

  if vim.fn.executable 'nix' == 1 and file_exists(root .. '/shell.nix') and file_exists(root .. '/../../flake.nix') then
    command = 'nix develop ../..#api -c ./bin/rspec ' .. vim.fn.shellescape(target)
  else
    local runner = vim.fn.executable(local_rspec) == 1 and './bin/rspec' or 'bundle exec rspec'
    command = runner .. ' ' .. vim.fn.shellescape(target)
  end

  return command, root
end

local function run_in_terminal(command, cwd)
  vim.cmd 'botright 12split'
  vim.cmd 'enew'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.fn.termopen({ vim.o.shell, '-lc', command }, { cwd = cwd })
  vim.cmd 'startinsert'
end

local function run_spec_file()
  local path = current_path()
  if path == '' then
    return
  end

  local spec = spec_path_for(path)
  if not file_exists(spec) then
    vim.notify('No matching spec found for ' .. path, vim.log.levels.WARN)
    return
  end

  local command, cwd = rspec_command(relative_to_root(spec, ruby_root(0)))
  run_in_terminal(command, cwd)
end

local function run_nearest_spec()
  local spec = current_spec_path()
  if not spec then
    return
  end

  local target = string.format('%s:%d', relative_to_root(spec, ruby_root(0)), vim.api.nvim_win_get_cursor(0)[1])
  local command, cwd = rspec_command(target)
  run_in_terminal(command, cwd)
end

return {
  'nvim-lua/plenary.nvim',
  ft = { 'ruby' },
  config = function()
    vim.api.nvim_create_user_command('RubyOpenSpec', open_spec, {})
    vim.api.nvim_create_user_command('RubyRunSpecFile', run_spec_file, {})
    vim.api.nvim_create_user_command('RubyRunNearestSpec', run_nearest_spec, {})

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('config-ruby-spec', { clear = true }),
      pattern = 'ruby',
      callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set('n', '<leader>to', open_spec, vim.tbl_extend('force', opts, { desc = 'Test open spec' }))
        vim.keymap.set('n', '<leader>tf', run_spec_file, vim.tbl_extend('force', opts, { desc = 'Test run spec file' }))
        vim.keymap.set('n', '<leader>tn', run_nearest_spec, vim.tbl_extend('force', opts, { desc = 'Test run nearest spec' }))
      end,
    })
  end,
}
