return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = {
      'kevinhwang91/promise-async',
    },
    event = 'VeryLazy',
    init = function()
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    opts = {
      provider_selector = function(_, filetype, _)
        if filetype == 'gitcommit' or filetype == 'markdown' then
          return { 'indent' }
        end

        return { 'treesitter', 'indent' }
      end,
    },
    config = function(_, opts)
      local ufo = require 'ufo'
      ufo.setup(opts)

      vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = 'Open all folds' })
      vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = 'Close all folds' })
      vim.keymap.set('n', 'zr', ufo.openFoldsExceptKinds, { desc = 'Open folds except kinds' })
      vim.keymap.set('n', 'zm', function()
        ufo.closeFoldsWith()
      end, { desc = 'Close folds with' })
      vim.keymap.set('n', 'K', function()
        local winid = ufo.peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end, { desc = 'Peek folded lines or hover' })
    end,
  },
}
