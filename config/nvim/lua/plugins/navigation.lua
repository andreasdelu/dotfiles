local function telescope_config()
  local telescope = require 'telescope'
  telescope.setup {
    extensions = {
      ['ui-select'] = {
        require('telescope.themes').get_dropdown(),
      },
    },
  }

  pcall(telescope.load_extension, 'fzf')
  pcall(telescope.load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Search help' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Search keymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search files' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = 'Search Telescope pickers' })
  vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search current word' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search by grep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Search diagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Search resume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = 'Search recent files' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })
  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = 'Search in current buffer' })
  vim.keymap.set('n', '<leader>s/', function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end, { desc = 'Search in open files' })
  vim.keymap.set('n', '<leader>sn', function()
    builtin.find_files { cwd = vim.fn.stdpath 'config' }
  end, { desc = 'Search Neovim files' })
end

local function git_root()
  return vim.fs.root(0, { '.git' }) or vim.fn.getcwd()
end

local function system_lines(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    return nil, (result.stderr or result.stdout or ''):gsub('%s+$', '')
  end

  return vim.split(result.stdout or '', '\n', { trimempty = true }), nil
end

local function system_text(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    return nil, (result.stderr or result.stdout or ''):gsub('%s+$', '')
  end

  return result.stdout or '', nil
end

local function branch_base(root)
  local upstream, upstream_err = system_lines({ 'git', 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}' }, root)
  if upstream and upstream[1] and upstream[1] ~= '' then
    local base = system_lines({ 'git', 'merge-base', 'HEAD', upstream[1] }, root)
    if base and base[1] and base[1] ~= '' then
      return base[1]
    end
  end

  for _, ref in ipairs({ 'origin/main', 'origin/master' }) do
    local base = system_lines({ 'git', 'merge-base', 'HEAD', ref }, root)
    if base and base[1] and base[1] ~= '' then
      return base[1]
    end
  end

  return nil, upstream_err
end

local function parse_hunks(diff_text)
  local hunks = {}
  local first_line

  for line in diff_text:gmatch '[^\n]+' do
    local minus_start, minus_count, plus_start, plus_count = line:match '^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@'
    if plus_start then
      minus_start = tonumber(minus_start)
      minus_count = tonumber(minus_count ~= '' and minus_count or '1')
      plus_start = tonumber(plus_start)
      plus_count = tonumber(plus_count ~= '' and plus_count or '1')

      local kind = 'GitSignsChangeLn'
      if plus_count == 0 then
        kind = 'GitSignsDeleteLn'
      elseif minus_count == 0 then
        kind = 'GitSignsAddLn'
      end

      local target_line = plus_count == 0 and math.max(plus_start - 1, 1) or plus_start
      local last_line = plus_count == 0 and target_line or plus_start + plus_count - 1
      first_line = first_line or target_line

      table.insert(hunks, {
        first_line = target_line,
        last_line = last_line,
        hl = kind,
      })
    end
  end

  return hunks, first_line
end

local function diff_hunks(entry)
  if not entry.diff_cmd then
    return {}, nil
  end

  local diff_text = system_text(entry.diff_cmd, entry.root)
  if not diff_text or diff_text == '' then
    return {}, nil
  end

  return parse_hunks(diff_text)
end

local function git_change_previewer()
  local previewers = require 'telescope.previewers'
  local conf = require('telescope.config').values
  local preview_ns = vim.api.nvim_create_namespace 'config-telescope-git-changes'

  local function apply_hunk_preview(bufnr, winid, hunks, first_line)
    vim.api.nvim_buf_clear_namespace(bufnr, preview_ns, 0, -1)

    local line_count = vim.api.nvim_buf_line_count(bufnr)
    for _, hunk in ipairs(hunks) do
      local start_line = math.max(math.min(hunk.first_line, line_count), 1)
      local end_line = math.max(math.min(hunk.last_line, line_count), start_line)

      for line = start_line, end_line do
        vim.api.nvim_buf_add_highlight(bufnr, preview_ns, hunk.hl, line - 1, 0, -1)
      end
    end

    if first_line and vim.api.nvim_win_is_valid(winid) then
      local target = math.max(math.min(first_line, line_count), 1)
      pcall(vim.api.nvim_win_set_cursor, winid, { target, 0 })
      vim.api.nvim_win_call(winid, function()
        vim.cmd 'normal! zz'
      end)
    end
  end

  return previewers.new_buffer_previewer {
    title = 'Git Change Preview',
    get_buffer_by_name = function(_, entry)
      return entry.path
    end,
    define_preview = function(self, entry)
      conf.buffer_previewer_maker(entry.path, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          local hunks, first_line = diff_hunks(entry)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              apply_hunk_preview(bufnr, self.state.winid, hunks, first_line)
            end
          end)
        end,
      })
    end,
  }
end

local function open_picker(opts)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = opts.title,
      finder = finders.new_table {
        results = opts.results,
        entry_maker = function(item)
          return {
            value = item,
            ordinal = item.ordinal,
            display = item.display,
            path = item.path,
            root = item.root,
            diff_cmd = item.diff_cmd,
            filename = item.path,
          }
        end,
      },
      previewer = git_change_previewer(),
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = action_state.get_selected_entry()
          if entry and entry.path then
            vim.cmd.edit(vim.fn.fnameescape(entry.path))
          end
        end)
        return true
      end,
    })
    :find()
end

local function worktree_changes()
  local root = git_root()
  local lines, err = system_lines({ 'git', 'status', '--short', '--untracked-files=all' }, root)
  if not lines then
    vim.notify('Git status failed: ' .. err, vim.log.levels.ERROR)
    return
  end

  local results = {}
  for _, line in ipairs(lines) do
    local status = line:sub(1, 2)
    local relative = line:sub(4):gsub('^.+ %-%> ', '')
    if relative ~= '' then
      table.insert(results, {
        display = string.format('%s %s', status, relative),
        ordinal = status .. ' ' .. relative,
        path = root .. '/' .. relative,
        root = root,
        diff_cmd = status == '??' and nil or { 'git', 'diff', '--unified=0', 'HEAD', '--', relative },
      })
    end
  end

  if #results == 0 then
    vim.notify('Working tree is clean', vim.log.levels.INFO)
    return
  end

  open_picker { title = 'Git Worktree Changes', results = results }
end

local function branch_changes()
  local root = git_root()
  local base, err = branch_base(root)
  if not base then
    vim.notify('Could not determine branch base' .. (err ~= '' and ': ' .. err or ''), vim.log.levels.WARN)
    return
  end

  local lines, diff_err = system_lines({ 'git', 'diff', '--name-only', '--diff-filter=ACMR', base .. '..HEAD' }, root)
  if not lines then
    vim.notify('Git diff failed: ' .. diff_err, vim.log.levels.ERROR)
    return
  end

  local results = {}
  for _, relative in ipairs(lines) do
    if relative ~= '' then
      table.insert(results, {
        display = relative,
        ordinal = relative,
        path = root .. '/' .. relative,
        root = root,
        diff_cmd = { 'git', 'diff', '--unified=0', base .. '..HEAD', '--', relative },
      })
    end
  end

  if #results == 0 then
    vim.notify('No committed file changes on this branch', vim.log.levels.INFO)
    return
  end

  open_picker { title = 'Git Branch Changes', results = results }
end

return {
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
  },
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = true },
    },
    config = telescope_config,
    keys = {
      { '<leader>gw', worktree_changes, desc = 'Git worktree changes' },
      { '<leader>gb', branch_changes, desc = 'Git branch changes' },
    },
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
      's1n7ax/nvim-window-picker',
    },
    opts = {
      window = { position = 'left', width = 30 },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = 'disabled',
        filtered_items = { visible = true },
      },
      default_component_configs = {
        git_status = { symbols = {} },
      },
    },
  },
  {
    's1n7ax/nvim-window-picker',
    version = '2.*',
    opts = {
      filter_rules = {
        include_current_win = false,
        autoselect_one = true,
        bo = {
          filetype = { 'neo-tree', 'neo-tree-popup', 'notify' },
          buftype = { 'terminal', 'quickfix' },
        },
      },
    },
  },
  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neo-tree/neo-tree.nvim',
    },
    opts = {},
  },
}
