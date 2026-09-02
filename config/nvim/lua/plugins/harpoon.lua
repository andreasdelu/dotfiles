return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    harpoon:setup()
    harpoon:extend {
      UI_CREATE = function(context)
        for index = 1, 9 do
          vim.keymap.set('n', tostring(index), function()
            if index > vim.api.nvim_buf_line_count(context.bufnr) then
              return
            end

            vim.api.nvim_win_set_cursor(context.win_id, { index, 0 })
            harpoon.ui:select_menu_item()
          end, {
            buffer = context.bufnr,
            desc = ('Harpoon file %d'):format(index),
          })
        end
      end,
    }
  end,
  keys = {
    {
      '<leader>ha',
      function()
        require('harpoon'):list():add()
      end,
      desc = 'Harpoon add file',
    },
    {
      '<leader>hh',
      function()
        local harpoon = require 'harpoon'
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = 'Harpoon quick menu',
    },
    {
      '<leader>hp',
      function()
        require('harpoon'):list():prev()
      end,
      desc = 'Harpoon previous file',
    },
    {
      '<leader>hn',
      function()
        require('harpoon'):list():next()
      end,
      desc = 'Harpoon next file',
    },
    {
      '<leader>h1',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = 'Harpoon file 1',
    },
    {
      '<leader>h2',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = 'Harpoon file 2',
    },
    {
      '<leader>h3',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = 'Harpoon file 3',
    },
    {
      '<leader>h4',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = 'Harpoon file 4',
    },
  },
}
