-- Run with: nvim --headless -u NONE -l config/nvim/lua/config/ruby.test.lua
local source = debug.getinfo(1, 'S').source:sub(2)
local config_dir = vim.fs.dirname(source)
local ruby = dofile(config_dir .. '/ruby.lua')
local temp = vim.fn.tempname()
local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end
local function project(name, package_name)
  local repo = temp .. '/' .. name
  local root = repo .. '/apps/api'
  write(repo .. '/package.json', { vim.json.encode { name = package_name or 'landfolk' } })
  for _, path in ipairs { repo .. '/flake.nix', root .. '/shell.nix', root .. '/bin/srb', root .. '/Gemfile', root .. '/sorbet/config' } do
    write(path, {})
  end
  return root
end

local ok, err = pcall(function()
  for _, name in ipairs { 'Documents/landfolk', 'code/renamed-checkout', 'worktrees/branch with spaces', 'home/linux-user/src/project' } do
    local root = project(name)
    assert(ruby.is_landfolk_api(root), name)
    assert(vim.deep_equal(ruby.sorbet_command(root), {
      'nix',
      'develop',
      '../..#api',
      '-c',
      './bin/srb',
      'tc',
      '--lsp',
      '--disable-watchman',
    }))
  end
  local other = project('unrelated', 'other-app')
  assert(not ruby.is_landfolk_api(other))
  assert(ruby.sorbet_command(other)[1] == 'srb')
  assert(not ruby.is_landfolk_api(nil))
  assert(not ruby.is_landfolk_api(temp .. '/Documents/landfolk/apps/another-app'))

  local root = project 'missing-markers'
  vim.fn.delete(root .. '/shell.nix')
  assert(not ruby.is_landfolk_api(root))
  write(root .. '/shell.nix', {})
  write(temp .. '/missing-markers/package.json', { '{broken json' })
  assert(not ruby.is_landfolk_api(root))

  -- Exercise the real formatter selector without loading/installing plugins.
  package.loaded['config.ruby'] = ruby
  local conform = dofile(config_dir .. '/../plugins/conform.lua')
  local buffer = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buffer, other .. '/example.rb')
  vim.bo[buffer].filetype = 'ruby'
  assert(conform.opts.formatters_by_ft.ruby(buffer)[1] == 'syntax_tree')
  vim.api.nvim_buf_set_name(buffer, temp .. '/code/renamed-checkout/apps/api/example.rb')
  assert(conform.opts.formatters_by_ft.ruby(buffer)[1] == 'landfolk_api_stree')
  vim.api.nvim_buf_set_name(buffer, temp .. '/code/renamed-checkout/apps/api/example.rbi')
  assert(conform.opts.format_on_save(buffer) == nil)

  -- Check the actual LSP callbacks: root gating and cwd must stay project-local.
  local lsp = dofile(config_dir .. '/../plugins/lspconfig.lua')
  local function callback(name)
    for i = 1, 100 do
      local key, value = debug.getupvalue(lsp.config, i)
      if key == name then
        return value
      end
      if not key then
        break
      end
    end
    error('Missing LSP callback: ' .. name)
  end
  local selected
  callback 'sorbet_root_dir'(buffer, function(dir)
    selected = dir
  end)
  assert(selected and ruby.is_landfolk_api(selected))
  vim.fn.delete(selected .. '/sorbet/config')
  local attached = false
  callback 'sorbet_root_dir'(buffer, function()
    attached = true
  end)
  assert(not attached, 'Sorbet must not start without sorbet/config')

  local captured
  vim.lsp.rpc.start = function(command, _, options)
    captured = { command = command, cwd = options.cwd }
  end
  callback 'start_sorbet'({}, { root_dir = selected })
  assert(captured.cwd == selected and captured.command[1] == 'nix')
  callback 'start_sorbet'({}, { root_dir = other })
  assert(captured.cwd == other and captured.command[1] == 'srb')
end)
vim.fn.delete(temp, 'rf')
assert(ok, err)
print 'PASS: relocated Landfolk roots, unrelated/malformed projects, unchanged Sorbet commands, formatter routing'
