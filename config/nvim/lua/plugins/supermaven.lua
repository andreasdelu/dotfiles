return {
  'supermaven-inc/supermaven-nvim',
  cmd = { 'SupermavenUseFree', 'SupermavenUsePro', 'SupermavenStart', 'SupermavenStatus' },
  event = 'InsertEnter',
  opts = {
    keymaps = {
      accept_suggestion = '<C-l>',
      clear_suggestion = '<C-]>',
      accept_word = '<C-j>',
    },
    ignore_filetypes = {
      oil = true,
      neo_tree = true,
      ['neo-tree'] = true,
    },
  },
}
