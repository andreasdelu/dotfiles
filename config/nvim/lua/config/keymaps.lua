local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

map('n', '<leader>e', '<cmd>Neotree toggle filesystem left<CR>', { desc = 'Toggle explorer', silent = true })
map('n', '<leader>o', '<cmd>Neotree reveal left<CR>', { desc = 'Reveal current file', silent = true })

map('n', '<leader>cl', function()
  local path = vim.fn.expand '%:p'
  if path == '' then
    vim.notify('No file path to copy', vim.log.levels.WARN)
    return
  end

  local location = string.format('%s:%d', path, vim.api.nvim_win_get_cursor(0)[1])
  vim.fn.setreg('+', location)
  vim.notify('Copied ' .. location, vim.log.levels.INFO)
end, { desc = 'Copy file location' })

map('n', '<leader>rW', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word (Exact)' })
map('n', '<leader>rw', [[:%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word' })
