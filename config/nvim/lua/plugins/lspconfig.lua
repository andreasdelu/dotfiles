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

local function sorbet_root_dir(bufnr, on_dir)
  local root = vim.fs.root(bufnr, function(name, path)
    if name ~= 'sorbet' then
      return false
    end

    local config = vim.uv.fs_stat(vim.fs.joinpath(path, name, 'config'))
    return config ~= nil and config.type == 'file'
  end)
  if root then
    on_dir(root)
  end
end

local function start_sorbet(dispatchers, config)
  return vim.lsp.rpc.start(require('config.ruby').sorbet_command(config.root_dir), dispatchers, {
    cwd = config.root_dir,
  })
end

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'saghen/blink.cmp',
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('config-lsp-attach', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        local function map(keys, rhs, desc)
          vim.keymap.set('n', keys, rhs, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('grd', vim.lsp.buf.definition, 'Definition')
        map('grD', vim.lsp.buf.declaration, 'Declaration')
        map('gW', vim.lsp.buf.workspace_symbol, 'Workspace symbols')
        map('<leader>.', vim.lsp.buf.code_action, 'Code action')
        map('<leader>li', '<cmd>checkhealth vim.lsp<CR>', 'Info')
        map('<leader>ls', '<cmd>edit<CR>', 'Start (reload buffer)')
        map('<leader>lx', '<cmd>lsp stop<CR>', 'Stop')
        map('<leader>lr', '<cmd>lsp restart<CR>', 'Restart')

        if client and client.name == 'eslint' then
          map('<leader>lf', '<cmd>LspEslintFixAll<CR>', 'Eslint fix all')
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = event.buf,
            group = vim.api.nvim_create_augroup('config-eslint-fix-on-save', { clear = false }),
            command = 'silent! LspEslintFixAll',
          })
        end

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
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
      virtual_text = { source = 'if_many', spacing = 2 },
    }

    require('mason-tool-installer').setup {
      ensure_installed = {
        'lua-language-server',
        'tailwindcss-language-server',
        'typescript-language-server',
        'graphql-language-service-cli',
        'eslint-lsp',
        'sorbet',
        'stylua',
        'prettierd',
      },
      integrations = { ['mason-lspconfig'] = false },
    }

    vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
    vim.lsp.config('lua_ls', { settings = { Lua = { completion = { callSnippet = 'Replace' } } } })
    vim.lsp.config('eslint', {
      settings = {
        codeActionOnSave = { enable = true, mode = 'all' },
        workingDirectory = { mode = 'auto' },
      },
    })
    -- Root on the oxlint config so a monorepo's hoisted binary is found.
    vim.lsp.config('oxlint', {
      root_dir = function(bufnr, on_dir)
        local root = vim.fs.root(bufnr, { '.oxlintrc.json', '.oxlintrc.jsonc', 'oxlint.config.ts' })
        if root then
          on_dir(root)
        end
      end,
      cmd = function(dispatchers, config)
        local local_cmd = vim.fs.joinpath(config.root_dir or '', 'node_modules/.bin/oxlint')
        local cmd = vim.fn.executable(local_cmd) == 1 and local_cmd or 'oxlint'
        return vim.lsp.rpc.start({ cmd, '--lsp' }, dispatchers)
      end,
    })
    vim.lsp.config('sorbet', {
      cmd = start_sorbet,
      filetypes = { 'ruby' },
      root_dir = sorbet_root_dir,
      handlers = { ['textDocument/publishDiagnostics'] = sorbet_publish_diagnostics },
    })
    vim.lsp.config('tailwindcss', {
      settings = {
        tailwindCSS = {
          classAttributes = { 'class', 'className', 'ngClass', 'tx' },
          experimental = { classRegex = { { 'tx`([^`]*)`', '([\\w-/:]+)' } } },
        },
      },
    })

    vim.lsp.enable { 'lua_ls', 'tailwindcss', 'rust_analyzer', 'ts_ls', 'graphql', 'oxlint', 'eslint', 'sorbet' }
  end,
}
