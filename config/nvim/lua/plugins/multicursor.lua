return {
  'jake-stewart/multicursor.nvim',
  branch = '1.0',
  event = 'VeryLazy',
  config = function()
    local mc = require 'multicursor-nvim'
    local set = vim.keymap.set

    mc.setup()

    -- Add/skip cursors vertically.
    set({ 'n', 'x' }, '<leader>mk', function()
      mc.lineAddCursor(-1)
    end, { desc = 'MultiCursor add cursor above' })

    set({ 'n', 'x' }, '<leader>mj', function()
      mc.lineAddCursor(1)
    end, { desc = 'MultiCursor add cursor below' })

    set({ 'n', 'x' }, '<leader>mK', function()
      mc.lineSkipCursor(-1)
    end, { desc = 'MultiCursor skip above' })

    set({ 'n', 'x' }, '<leader>mJ', function()
      mc.lineSkipCursor(1)
    end, { desc = 'MultiCursor skip below' })

    -- Add cursors by matching the current word/selection.
    set({ 'n', 'x' }, '<leader>mn', function()
      mc.matchAddCursor(1)
    end, { desc = 'MultiCursor add next match' })

    set({ 'n', 'x' }, '<leader>mN', function()
      mc.matchAddCursor(-1)
    end, { desc = 'MultiCursor add previous match' })

    set({ 'n', 'x' }, '<leader>ma', mc.matchAllAddCursors, { desc = 'MultiCursor add all matches' })

    -- Toggle/disable cursors.
    set({ 'n', 'x' }, '<C-q>', mc.toggleCursor, { desc = 'MultiCursor toggle cursor' })

    -- Mouse support.
    set('n', '<C-LeftMouse>', mc.handleMouse, { desc = 'MultiCursor add cursor with mouse' })
    set('n', '<C-LeftDrag>', mc.handleMouseDrag)
    set('n', '<C-LeftRelease>', mc.handleMouseRelease)

    -- These mappings only apply while multiple cursors exist.
    mc.addKeymapLayer(function(layerSet)
      layerSet({ 'n', 'x' }, '<Left>', mc.prevCursor, { desc = 'MultiCursor previous cursor' })
      layerSet({ 'n', 'x' }, '<Right>', mc.nextCursor, { desc = 'MultiCursor next cursor' })
      layerSet({ 'n', 'x' }, '<leader>x', mc.deleteCursor, { desc = 'MultiCursor delete cursor' })

      layerSet('n', '<Esc>', function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end, { desc = 'MultiCursor clear cursors' })
    end)
  end,
}
