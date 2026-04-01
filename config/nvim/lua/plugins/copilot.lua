return {
  'github/copilot.vim',
  event = 'InsertEnter',
  cmd = { 'Copilot' },
  init = function()
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_filetypes = {
      oil = false,
      neo_tree = false,
      ['neo-tree'] = false,
    }
  end,
  config = function()
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
      group = vim.api.nvim_create_augroup('config-copilot-env-disable', { clear = true }),
      callback = function(args)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ':t')
        if filename:match '^%.env' then
          vim.b[args.buf].copilot_enabled = false
        end
      end,
    })

    vim.keymap.set('i', '<C-l>', '<Plug>(copilot-accept-word)')
    vim.keymap.set('i', '<C-]>', '<Plug>(copilot-dismiss)')
    vim.keymap.set('i', '<M-]>', '<Plug>(copilot-next)')
    vim.keymap.set('i', '<M-[>', '<Plug>(copilot-previous)')
  end,
}
