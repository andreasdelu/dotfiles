return {
  'dmtrKovalenko/fff',
  build = function()
    require('fff.download').download_or_build_binary()
  end,
  lazy = false,
  opts = {
    prompt_vim_mode = true,
  },
  keys = {
    {
      '<leader>sf',
      function()
        require('fff').find_files()
      end,
      desc = 'Search files',
    },
    {
      '<leader>sg',
      function()
        require('fff').live_grep()
      end,
      desc = 'Search by grep',
    },
    {
      '<leader>sw',
      function()
        require('fff').live_grep_under_cursor()
      end,
      mode = { 'n', 'x' },
      desc = 'Search current word or selection',
    },
    {
      '<leader>sr',
      function()
        require('fff').resume()
      end,
      desc = 'Resume search',
    },
    {
      '<leader>sn',
      function()
        require('fff').find_files_in_dir(vim.fn.stdpath 'config')
      end,
      desc = 'Search Neovim files',
    },
  },
}
