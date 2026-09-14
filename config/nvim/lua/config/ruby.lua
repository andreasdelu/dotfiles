local M = {}

-- Recognize the project, not the owner's home directory or checkout name.
-- Gemfile alone is too broad: other Ruby projects must never enter this shell.
function M.is_landfolk_api(root)
  if type(root) ~= 'string' then
    return false
  end
  root = vim.fs.normalize(root)
  if vim.fs.basename(root) ~= 'api' or vim.fs.basename(vim.fs.dirname(root)) ~= 'apps' then
    return false
  end

  local repo = vim.fs.dirname(vim.fs.dirname(root))
  for _, path in ipairs { repo .. '/flake.nix', root .. '/shell.nix', root .. '/bin/srb' } do
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.type ~= 'file' then
      return false
    end
  end

  local ok, package = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(repo .. '/package.json'), '\n'))
  end)
  return ok and type(package) == 'table' and package.name == 'landfolk'
end

function M.sorbet_command(root)
  if M.is_landfolk_api(root) then
    return { 'nix', 'develop', '../..#api', '-c', './bin/srb', 'tc', '--lsp', '--disable-watchman' }
  end
  return { 'srb', 'tc', '--lsp', '--disable-watchman' }
end

return M
