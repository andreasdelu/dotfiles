return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  init = function()
    local runtime = vim.fn.stdpath 'data' .. '/lazy/nvim-treesitter/runtime'
    if vim.uv.fs_stat(runtime) then
      vim.opt.rtp:append(runtime)
    end
  end,
  config = function()
    require('nvim-treesitter').setup()

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('config-treesitter-highlight', { clear = true }),
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('config-ruby-regex-highlight', { clear = true }),
      pattern = 'ruby',
      callback = function()
        vim.bo.syntax = 'ruby'
      end,
    })
  end,
}
