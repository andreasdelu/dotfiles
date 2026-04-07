return {
  'github/copilot.vim',
  event = 'VimEnter',
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

    vim.keymap.set('i', '<C-l>', 'copilot#Accept("")', {
      expr = true,
      replace_keycodes = false,
    })
    vim.keymap.set('i', '<C-j>', '<Plug>(copilot-accept-word)', { remap = true })
    vim.keymap.set('i', '<C-]>', '<Plug>(copilot-dismiss)', { remap = true })
    vim.keymap.set('i', '<M-]>', '<Plug>(copilot-next)', { remap = true })
    vim.keymap.set('i', '<M-[>', '<Plug>(copilot-previous)', { remap = true })
  end,
}
