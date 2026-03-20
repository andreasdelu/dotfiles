return {
  'karb94/neoscroll.nvim',
  opts = {
    ignored_events = { 'CursorMoved' },
    post_hook = function()
      require('scrollbar').render()
    end,
  },
}
