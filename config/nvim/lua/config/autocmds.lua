vim.api.nvim_create_autocmd('FileType', {
  desc = '2-space indent for web filetypes',
  group = vim.api.nvim_create_augroup('config-web-indent', { clear = true }),
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'json', 'jsonc', 'html', 'css', 'scss', 'graphql', 'lua' },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking',
  group = vim.api.nvim_create_augroup('config-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Replace directory startup with an empty buffer',
  group = vim.api.nvim_create_augroup('config-start-empty-dir', { clear = true }),
  callback = function()
    if vim.fn.argc() ~= 1 then
      return
    end

    local arg = vim.fn.argv(0)
    if vim.fn.isdirectory(arg) == 1 then
      vim.cmd.cd(arg)
      vim.cmd.enew()
    end
  end,
})
