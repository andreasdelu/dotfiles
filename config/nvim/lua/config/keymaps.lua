local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })
map('n', '<leader>dd', function()
  vim.diagnostic.jump { count = 1 }
end, { desc = 'Next diagnostic' })
map('n', '<leader>dD', function()
  vim.diagnostic.jump { count = -1 }
end, { desc = 'Previous diagnostic' })
map('n', '<leader>de', function()
  vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR }
end, { desc = 'Next diagnostic error' })
map('n', '<leader>dE', function()
  vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR }
end, { desc = 'Previous diagnostic error' })
map('n', '<leader>dw', function()
  vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.WARN }
end, { desc = 'Next diagnostic warning' })
map('n', '<leader>dW', function()
  vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.WARN }
end, { desc = 'Previous diagnostic warning' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

map('n', '<leader>e', '<cmd>Neotree toggle filesystem left<CR>', { desc = 'Toggle explorer', silent = true })
map('n', '<leader>o', '<cmd>Neotree reveal left<CR>', { desc = 'Reveal current file', silent = true })

map('n', '<leader>ai', '<cmd>AgentEditsImportClipboard<CR>', { desc = 'Agent edits import clipboard', silent = true })
map('n', '<leader>aI', '<cmd>AgentEditsImportBuffer<CR>', { desc = 'Agent edits import buffer', silent = true })
map('n', '<leader>al', '<cmd>AgentEditsLoadLatest<CR>', { desc = 'Agent edits load latest', silent = true })
map('n', '<leader>ap', '<cmd>AgentEditsPreview<CR>', { desc = 'Agent edits preview', silent = true })
map('n', '<leader>an', '<cmd>AgentEditsNext<CR>', { desc = 'Agent edits next', silent = true })
map('n', '<leader>aN', '<cmd>AgentEditsPrev<CR>', { desc = 'Agent edits previous', silent = true })
map('n', '<leader>aa', '<cmd>AgentEditsAccept<CR>', { desc = 'Agent edits accept', silent = true })
map('n', '<leader>ar', '<cmd>AgentEditsReject<CR>', { desc = 'Agent edits reject', silent = true })
map('n', '<leader>as', '<cmd>AgentEditsStatus<CR>', { desc = 'Agent edits status', silent = true })

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
