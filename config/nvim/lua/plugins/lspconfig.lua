local function client_supports_method(client, method, bufnr)
  if vim.fn.has 'nvim-0.11' == 1 then
    return client:supports_method(method, bufnr)
  end

  return client.supports_method(method, { bufnr = bufnr })
end

local function normalize_diagnostic_uri(uri, root_dir)
  if type(uri) ~= 'string' or uri == '' or uri:match '^%a[%w+.+-]*://' then
    return uri
  end

  local path = uri
  if not uri:match '^/' then
    if not root_dir or root_dir == '' then
      return uri
    end

    path = root_dir .. '/' .. uri
  end

  return vim.uri_from_fname(vim.fs.normalize(path))
end

local function sorbet_publish_diagnostics(err, result, ctx, config)
  if result then
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local root_dir = client and client.config and client.config.root_dir or nil

    result.uri = normalize_diagnostic_uri(result.uri, root_dir)
    for _, diagnostic in ipairs(result.diagnostics or {}) do
      for _, related in ipairs(diagnostic.relatedInformation or {}) do
        if related.location then
          related.location.uri = normalize_diagnostic_uri(related.location.uri, root_dir)
        end
      end
    end
  end

  return vim.lsp.handlers['textDocument/publishDiagnostics'](err, result, ctx, config)
end

local function ruby_project_root(bufnr)
  return vim.fs.root(bufnr, { 'Gemfile', '.ruby-version' })
end

local function sorbet_project_root(bufnr)
  local root = ruby_project_root(bufnr)
  if root and vim.uv.fs_stat(root .. '/sorbet/config') then
    return root
  end
end

local function is_landfolk_api_root(root)
  return type(root) == 'string' and root:match '/Documents/landfolk/apps/api$' ~= nil
end

local function start_in_nix_dev_shell(dispatchers, config, command)
  return vim.lsp.rpc.start(command, dispatchers, {
    cwd = config.root_dir,
  })
end

local function start_sorbet(dispatchers, config)
  if is_landfolk_api_root(config.root_dir) then
    return start_in_nix_dev_shell(dispatchers, config, { 'nix', 'develop', '../..#api', '-c', './bin/srb', 'tc', '--lsp', '--disable-watchman' })
  end

  return vim.lsp.rpc.start({ 'srb', 'tc', '--lsp', '--disable-watchman' }, dispatchers, {
    cwd = config.root_dir,
  })
end

local function lsp_client_names(clients)
  local names = {}

  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end

  return names
end

local function stop_lsp(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr }
  if vim.tbl_isempty(clients) then
    vim.notify('No LSP attached to this buffer', vim.log.levels.WARN)
    return false, {}
  end

  local client_ids = {}
  local client_names = lsp_client_names(clients)

  for _, client in ipairs(clients) do
    table.insert(client_ids, client.id)
    client:stop(true)
  end

  vim.wait(1000, function()
    for _, client_id in ipairs(client_ids) do
      local client = vim.lsp.get_client_by_id(client_id)
      if client ~= nil and not vim.lsp.client_is_stopped(client_id) then
        return false
      end
    end

    return true
  end, 50)

  return true, client_names
end

local function start_lsp(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if not vim.bo[bufnr].modifiable and vim.bo[bufnr].buftype ~= '' then
    vim.notify('Cannot start LSP for this buffer type', vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd.edit()
  end)

  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    local clients = vim.lsp.get_clients { bufnr = bufnr }
    if vim.tbl_isempty(clients) then
      vim.notify('No LSP configured for this buffer', vim.log.levels.WARN)
      return
    end

    vim.notify('Started LSP: ' .. table.concat(lsp_client_names(clients), ', '), vim.log.levels.INFO)
  end, 150)
end

local function restart_lsp(bufnr)
  local ok, client_names = stop_lsp(bufnr)
  if not ok then
    return
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd.edit()
    end)
    vim.notify('Restarted LSP: ' .. table.concat(client_names, ', '), vim.log.levels.INFO)
  end
end

local function lsp_info(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr }
  if vim.tbl_isempty(clients) then
    vim.notify('No LSP attached to this buffer', vim.log.levels.INFO)
    return
  end

  local details = vim.tbl_map(function(client)
    local root = client.config and client.config.root_dir or 'unknown root'
    return string.format('%s (%s)', client.name, root)
  end, clients)

  vim.notify('LSP: ' .. table.concat(details, ' | '), vim.log.levels.INFO)
end

local function sorbet_root_dir(bufnr, on_dir)
  local root = sorbet_project_root(bufnr)
  if root then
    on_dir(root)
  end
end

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'saghen/blink.cmp',
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('config-lsp-attach', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local telescope = require 'telescope.builtin'

        local function map(keys, func, desc, mode)
          vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('grn', vim.lsp.buf.rename, 'Rename')
        map('gra', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
        map('<leader>.', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
        map('grr', telescope.lsp_references, 'References')
        map('gri', telescope.lsp_implementations, 'Implementation')
        map('grd', vim.lsp.buf.definition, 'Definition')
        map('grD', vim.lsp.buf.declaration, 'Declaration')
        map('gO', telescope.lsp_document_symbols, 'Document symbols')
        map('gW', telescope.lsp_dynamic_workspace_symbols, 'Workspace symbols')
        map('grt', telescope.lsp_type_definitions, 'Type definition')
        map('<leader>li', function()
          lsp_info(event.buf)
        end, 'Info')
        map('<leader>ls', function()
          start_lsp(event.buf)
        end, 'Start')
        map('<leader>lx', function()
          local ok, client_names = stop_lsp(event.buf)
          if ok then
            vim.notify('Stopped LSP: ' .. table.concat(client_names, ', '), vim.log.levels.INFO)
          end
        end, 'Stop')
        map('<leader>lr', function()
          restart_lsp(event.buf)
        end, 'Restart')

        if client and client.name == 'eslint' then
          map('<leader>lf', '<cmd>LspEslintFixAll<CR>', 'Eslint fix all')
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = event.buf,
            group = vim.api.nvim_create_augroup('config-eslint-fix-on-save', { clear = false }),
            command = 'silent! LspEslintFixAll',
          })
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_group = vim.api.nvim_create_augroup('config-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_group,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_group,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('config-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'config-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, 'Toggle inlay hints')
        end
      end,
    })

    vim.diagnostic.config {
      severity_sort = true,
      update_in_insert = false,
      float = { border = 'rounded', source = 'if_many' },
      underline = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = 'E',
          [vim.diagnostic.severity.WARN] = 'W',
          [vim.diagnostic.severity.INFO] = 'I',
          [vim.diagnostic.severity.HINT] = 'H',
        },
      },
      virtual_text = {
        source = 'if_many',
        spacing = 2,
      },
    }

    local capabilities = require('blink.cmp').get_lsp_capabilities()
    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },
      tailwindcss = {},
      ts_ls = {},
      graphql = {},
      eslint = {
        settings = {
          codeActionOnSave = {
            enable = true,
            mode = 'all',
          },
          workingDirectory = { mode = 'auto' },
        },
      },
      sorbet = {
        cmd = start_sorbet,
        filetypes = { 'ruby' },
        root_dir = sorbet_root_dir,
        handlers = {
          ['textDocument/publishDiagnostics'] = sorbet_publish_diagnostics,
        },
      },
    }

    local ensure_installed = vim.tbl_filter(function(server_name)
      return servers[server_name].mason ~= false
    end, vim.tbl_keys(servers))
    vim.list_extend(ensure_installed, { 'stylua', 'prettierd' })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      ensure_installed = {},
      automatic_installation = false,
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          server.mason = nil
          vim.lsp.config(server_name, server)
        end,
      },
    }

    for server_name, server in pairs(servers) do
      if server.mason == false then
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        server.mason = nil
        vim.lsp.config(server_name, server)
      end
    end

    vim.lsp.config('sorbet', {
      cmd = start_sorbet,
      filetypes = { 'ruby' },
      root_dir = sorbet_root_dir,
      handlers = {
        ['textDocument/publishDiagnostics'] = sorbet_publish_diagnostics,
      },
    })

    for _, server_name in ipairs(vim.tbl_keys(servers)) do
      vim.lsp.enable(server_name)
    end

    -- Tailwind: add tx tagged template support (must be after lspconfig defaults load)
    vim.lsp.config('tailwindcss', {
      settings = {
        tailwindCSS = {
          classAttributes = { 'class', 'className', 'ngClass', 'tx' },
          experimental = {
            classRegex = {
              { 'tx`([^`]*)`', '([\\w-/:]+)' },
            },
          },
        },
      },
    })
  end,
}
