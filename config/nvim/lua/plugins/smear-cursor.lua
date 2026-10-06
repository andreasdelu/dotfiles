return {
  'sphamba/smear-cursor.nvim',
  -- The plugin hides Neovim's real cursor while drawing its animation, which
  -- can make the cursor flicker or briefly disappear in terminal rendering.
  enabled = false,
  event = 'VeryLazy',
  opts = {
    stiffness = 0.8,
    trailing_stiffness = 0.6,
    stiffness_insert_mode = 0.7,
    trailing_stiffness_insert_mode = 0.7,
    damping = 0.95,
    damping_insert_mode = 0.95,
    distance_stop_animating = 0.5,
  },
}
