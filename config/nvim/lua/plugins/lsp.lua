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

return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
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
        ruby_lsp = {
          filetypes = { 'ruby', 'eruby' },
          init_options = {
            formatter = 'syntax_tree',
          },
        },
        sorbet = {
          cmd = { 'srb', 'tc', '--lsp', '--disable-watchman' },
          filetypes = { 'ruby', 'eruby' },
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
            vim.lsp.enable(server_name)
          end,
        },
      }

      for server_name, server in pairs(servers) do
        if server.mason == false then
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          server.mason = nil
          vim.lsp.config(server_name, server)
          vim.lsp.enable(server_name)
        end
      end
    end,
  },
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          local has_eslint = #vim.lsp.get_clients { bufnr = bufnr, name = 'eslint' } > 0
          if has_eslint then
            pcall(vim.cmd, 'LspEslintFixAll')
          end

          require('conform').format { async = false, lsp_format = 'never' }
        end,
        mode = { 'n', 'v' },
        desc = 'Fix and format buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local format_on_save_filetypes = {
          lua = true,
          javascript = true,
          javascriptreact = true,
          typescript = true,
          typescriptreact = true,
          ruby = true,
          json = true,
          jsonc = true,
          css = true,
          scss = true,
          markdown = true,
        }

        if not format_on_save_filetypes[vim.bo[bufnr].filetype] then
          return nil
        end

        return {
          timeout_ms = 1000,
          lsp_format = 'never',
        }
      end,
      formatters = {
        syntax_tree = {
          command = 'bin/stree',
          cwd = function(self, ctx)
            return require('conform.util').root_file { 'Gemfile', '.git' }(self, ctx)
          end,
        },
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        ruby = { 'syntax_tree' },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        jsonc = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        scss = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    opts = {
      keymap = {
        preset = 'super-tab',
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
        menu = {
          border = 'rounded',
        },
      },
      signature = { enabled = true },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
    },
  },
}
