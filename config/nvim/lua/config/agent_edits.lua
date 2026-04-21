local M = {}

local uv = vim.uv or vim.loop
local state = {
  session = nil,
  current_index = 0,
  preview = {
    buf = nil,
    win = nil,
    ns = vim.api.nvim_create_namespace 'config-agent-edits-preview',
  },
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'Agent Edits' })
end

local function read_file(path)
  local fd = assert(uv.fs_open(path, 'r', 438))
  local stat = assert(uv.fs_fstat(fd))
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data or ''
end

local function write_file(path, content)
  local parent = vim.fs.dirname(path)
  if parent and parent ~= '' then
    vim.fn.mkdir(parent, 'p')
  end

  local fd = assert(uv.fs_open(path, 'w', 420))
  uv.fs_write(fd, content, 0)
  uv.fs_close(fd)
end

local function repo_root()
  return vim.fs.root(vim.fn.getcwd(), { '.git' }) or vim.fn.getcwd()
end

local function to_absolute(root, path)
  if vim.fn.fnamemodify(path, ':p') == path then
    return path
  end

  return vim.fs.joinpath(root, path)
end

local function sanitize_name(name)
  local clean = (name or ''):gsub('[^%w%-_]+', '-')
  clean = clean:gsub('%-+', '-')
  clean = clean:gsub('^%-', ''):gsub('%-$', '')
  return clean ~= '' and clean or os.date('%Y%m%d-%H%M%S')
end

local function session_store_dir(root)
  return vim.fs.joinpath(root, '.agent-edits')
end

local function latest_session_file(root)
  local dir = session_store_dir(root)
  local fd = uv.fs_scandir(dir)
  if not fd then
    return nil
  end

  local latest_path, latest_mtime
  while true do
    local name, kind = uv.fs_scandir_next(fd)
    if not name then
      break
    end

    if kind == 'file' and name:sub(-5) == '.json' then
      local path = vim.fs.joinpath(dir, name)
      local stat = uv.fs_stat(path)
      if stat and (not latest_mtime or stat.mtime.sec > latest_mtime) then
        latest_path = path
        latest_mtime = stat.mtime.sec
      end
    end
  end

  return latest_path
end

local function decode_payload(raw_json)
  local decoded_ok, payload = pcall(vim.json.decode, raw_json)
  if not decoded_ok or type(payload) ~= 'table' then
    return nil, 'Invalid JSON payload'
  end

  if type(payload.edits) ~= 'table' then
    return nil, 'Payload must contain an edits array'
  end

  payload.root = payload.root or repo_root()
  payload.version = payload.version or 1
  payload.session_id = payload.session_id or ('session-' .. os.date('%Y%m%d-%H%M%S'))
  payload.source = payload.source or 'unknown'
  payload.created_at = payload.created_at or os.date('!%Y-%m-%dT%H:%M:%SZ')

  return payload
end

local function persist_payload(payload, raw_json)
  local root = vim.fn.fnamemodify(payload.root, ':p')
  local dir = session_store_dir(root)
  vim.fn.mkdir(dir, 'p')

  local base = sanitize_name(payload.session_id)
  local path = vim.fs.joinpath(dir, base .. '.json')
  if uv.fs_stat(path) then
    path = vim.fs.joinpath(dir, string.format('%s-%s.json', base, os.date('%H%M%S')))
  end

  write_file(path, vim.json.encode(payload))
  return path
end

local function line_starts(text)
  local starts = { 1 }
  for i = 1, #text do
    if text:sub(i, i) == '\n' then
      starts[#starts + 1] = i + 1
    end
  end
  starts[#starts + 1] = #text + 1
  return starts
end

local function line_col_to_offset(text, line, col)
  local starts = line_starts(text)
  if line < 1 or line >= #starts then
    return nil
  end

  local start = starts[line]
  local next_start = starts[line + 1] or (#text + 1)
  local line_end = next_start - 1
  local max_col = next_start - start
  if text:sub(line_end, line_end) == '\n' then
    max_col = max_col - 1
  end

  if col < 0 or col > math.max(max_col, 0) then
    return nil
  end

  return start + col
end

local function offset_to_line_col(text, offset)
  local line = 1
  local last_break = 0
  for i = 1, math.max(offset - 1, 0) do
    if text:sub(i, i) == '\n' then
      line = line + 1
      last_break = i
    end
  end

  return line, offset - last_break - 1
end

local function find_exact_matches(text, needle)
  local matches = {}
  if not needle or needle == '' then
    return matches
  end

  local start = 1
  while true do
    local s, e = text:find(needle, start, true)
    if not s then
      break
    end

    matches[#matches + 1] = { start = s, finish = e + 1 }
    start = s + 1
  end

  return matches
end

local function normalize_edit(root, edit, index)
  local normalized = {
    id = edit.id or ('edit_' .. index),
    file = edit.file,
    path = edit.file and to_absolute(root, edit.file) or nil,
    kind = edit.kind or 'replace',
    summary = edit.summary or edit.reason or ('Edit ' .. index),
    old_text = edit.old_text,
    new_text = edit.new_text,
    range = edit.range,
    status = 'pending',
    resolution = nil,
    error = nil,
  }

  if not normalized.file or normalized.file == '' then
    normalized.status = 'failed'
    normalized.error = 'Missing file'
    return normalized
  end

  if normalized.kind ~= 'replace' and normalized.kind ~= 'create' and normalized.kind ~= 'delete' then
    normalized.status = 'failed'
    normalized.error = 'Unsupported kind: ' .. tostring(normalized.kind)
    return normalized
  end

  if normalized.kind ~= 'delete' and normalized.new_text == nil then
    normalized.status = 'failed'
    normalized.error = 'Missing new_text'
    return normalized
  end

  return normalized
end

local function resolve_edit(edit)
  if edit.status == 'rejected' or edit.status == 'applied' or edit.status == 'failed' then
    return edit.status, edit.resolution, edit.error
  end

  if edit.kind == 'create' then
    local exists = uv.fs_stat(edit.path) ~= nil
    if not exists then
      edit.status = 'pending'
      edit.resolution = { kind = 'create' }
      edit.error = nil
      return edit.status, edit.resolution
    end

    local current = read_file(edit.path)
    if current == (edit.new_text or '') then
      edit.status = 'applied'
      edit.resolution = { kind = 'create' }
      edit.error = nil
      return edit.status, edit.resolution
    end

    edit.status = 'stale'
    edit.resolution = nil
    edit.error = 'Target file already exists'
    return edit.status, edit.resolution, edit.error
  end

  if uv.fs_stat(edit.path) == nil then
    edit.status = 'stale'
    edit.resolution = nil
    edit.error = 'Target file does not exist'
    return edit.status, edit.resolution, edit.error
  end

  local text = read_file(edit.path)

  if edit.range and edit.range.start and edit.range['end'] then
    local start_offset = line_col_to_offset(text, edit.range.start.line, edit.range.start.col)
    local end_offset = line_col_to_offset(text, edit.range['end'].line, edit.range['end'].col)

    if start_offset and end_offset and start_offset <= end_offset then
      local candidate = text:sub(start_offset, end_offset - 1)
      if edit.old_text == nil or candidate == edit.old_text then
        edit.status = 'pending'
        edit.resolution = {
          kind = 'range',
          start_offset = start_offset,
          end_offset = end_offset,
          start_line = edit.range.start.line,
          start_col = edit.range.start.col,
        }
        edit.error = nil
        return edit.status, edit.resolution
      end
    end
  end

  local old_text = edit.old_text
  if old_text and old_text ~= '' then
    local matches = find_exact_matches(text, old_text)
    if #matches == 1 then
      local match = matches[1]
      local line, col = offset_to_line_col(text, match.start)
      edit.status = 'pending'
      edit.resolution = {
        kind = 'search',
        start_offset = match.start,
        end_offset = match.finish,
        start_line = line,
        start_col = col,
      }
      edit.error = nil
      return edit.status, edit.resolution
    end

    if #matches > 1 then
      edit.status = 'ambiguous'
      edit.resolution = nil
      edit.error = 'old_text matched multiple locations'
      return edit.status, edit.resolution, edit.error
    end
  end

  if edit.kind == 'delete' and (edit.old_text == nil or edit.old_text == '') then
    edit.status = 'failed'
    edit.resolution = nil
    edit.error = 'Delete edits require old_text or range'
    return edit.status, edit.resolution, edit.error
  end

  if edit.old_text and edit.new_text and edit.new_text ~= '' and text:find(edit.new_text, 1, true) then
    edit.status = 'stale'
    edit.resolution = nil
    edit.error = 'old_text no longer matches; file may already include new_text'
    return edit.status, edit.resolution, edit.error
  end

  edit.status = 'stale'
  edit.resolution = nil
  edit.error = 'Could not resolve edit safely'
  return edit.status, edit.resolution, edit.error
end

local function resolve_all()
  if not state.session then
    return
  end

  for _, edit in ipairs(state.session.edits) do
    if edit.status ~= 'rejected' and edit.status ~= 'applied' and edit.status ~= 'failed' then
      resolve_edit(edit)
    end
  end
end

local function ensure_session()
  if state.session then
    return true
  end

  notify('No agent edit session loaded', vim.log.levels.WARN)
  return false
end

local function current_edit()
  if not ensure_session() then
    return nil
  end

  return state.session.edits[state.current_index]
end

local function first_edit_index()
  if not state.session or #state.session.edits == 0 then
    return 0
  end

  for i, edit in ipairs(state.session.edits) do
    if edit.status == 'pending' then
      return i
    end
  end

  return 1
end

local function jump_to_edit(edit)
  if not edit then
    return
  end

  if uv.fs_stat(edit.path) == nil then
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(edit.path))
  local line = 1
  local col = 0
  if edit.resolution then
    line = edit.resolution.start_line or line
    col = edit.resolution.start_col or col
  end

  pcall(vim.api.nvim_win_set_cursor, 0, { math.max(line, 1), math.max(col, 0) })
  vim.cmd 'normal! zz'
end

local function render_preview(edit)
  if not edit then
    return
  end

  local buf = state.preview.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
    state.preview.buf = buf
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = 'diff'
  end

  local old_lines = vim.split(edit.old_text or '', '\n', { plain = true })
  local new_lines = vim.split(edit.new_text or '', '\n', { plain = true })
  if old_lines[#old_lines] == '' then
    table.remove(old_lines, #old_lines)
  end
  if new_lines[#new_lines] == '' then
    table.remove(new_lines, #new_lines)
  end

  local lines = {
    string.format('Edit %d/%d', state.current_index, #state.session.edits),
    string.format('id: %s', edit.id),
    string.format('file: %s', edit.file),
    string.format('kind: %s', edit.kind),
    string.format('status: %s', edit.status),
    string.format('summary: %s', edit.summary),
  }

  if edit.error then
    lines[#lines + 1] = string.format('note: %s', edit.error)
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = '@@ old @@'
  local old_start = #lines + 1
  if #old_lines == 0 then
    lines[#lines + 1] = '- <empty>'
  else
    for _, line in ipairs(old_lines) do
      lines[#lines + 1] = '- ' .. line
    end
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = '@@ new @@'
  local new_start = #lines + 1
  if #new_lines == 0 then
    lines[#lines + 1] = '+ <empty>'
  else
    for _, line in ipairs(new_lines) do
      lines[#lines + 1] = '+ ' .. line
    end
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, state.preview.ns, 0, -1)

  local old_end = new_start - 2
  for line = old_start - 1, old_end - 1 do
    vim.api.nvim_buf_add_highlight(buf, state.preview.ns, 'DiffDelete', line, 0, -1)
  end
  for line = new_start - 1, #lines - 1 do
    vim.api.nvim_buf_add_highlight(buf, state.preview.ns, 'DiffAdd', line, 0, -1)
  end

  local win = state.preview.win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    vim.cmd 'botright split'
    win = vim.api.nvim_get_current_win()
    state.preview.win = win
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_height(win, math.min(math.max(#lines + 2, 12), 24))
  else
    vim.api.nvim_win_set_buf(win, buf)
  end
end

local function render_status()
  if not ensure_session() then
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    string.format('Agent edit session: %s', state.session.session_id or 'unknown'),
    string.format('source: %s', state.session.source or 'unknown'),
    string.format('root: %s', state.session.root),
    '',
  }

  for i, edit in ipairs(state.session.edits) do
    local prefix = (i == state.current_index) and '>' or ' '
    local note = edit.error and (' -- ' .. edit.error) or ''
    lines[#lines + 1] = string.format('%s [%s] %s :: %s%s', prefix, edit.status, edit.file, edit.summary, note)
  end

  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'text'
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.cmd 'botright vnew'
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_width(0, math.min(120, math.max(60, math.floor(vim.o.columns * 0.35))))
end

local function step(delta)
  if not ensure_session() then
    return
  end

  local count = #state.session.edits
  if count == 0 then
    notify('No edits in current session', vim.log.levels.WARN)
    return
  end

  state.current_index = ((state.current_index - 1 + delta) % count) + 1
  local edit = current_edit()
  resolve_edit(edit)
  jump_to_edit(edit)
  render_preview(edit)
end

local function apply_edit(edit)
  resolve_edit(edit)
  if edit.status ~= 'pending' or not edit.resolution then
    notify('Edit is not safely applicable: ' .. (edit.error or edit.status), vim.log.levels.WARN)
    return false
  end

  if edit.kind == 'create' then
    write_file(edit.path, edit.new_text or '')
    edit.status = 'applied'
    edit.error = nil
    return true
  end

  local text = read_file(edit.path)
  local start_offset = edit.resolution.start_offset
  local end_offset = edit.resolution.end_offset
  local replacement = edit.kind == 'delete' and '' or (edit.new_text or '')
  local updated = text:sub(1, start_offset - 1) .. replacement .. text:sub(end_offset)
  write_file(edit.path, updated)

  edit.status = 'applied'
  edit.error = nil
  return true
end

function M.load(path)
  local absolute = vim.fn.fnamemodify(path, ':p')
  local ok, contents = pcall(read_file, absolute)
  if not ok then
    notify('Could not read ' .. absolute, vim.log.levels.ERROR)
    return
  end

  local payload, err = decode_payload(contents)
  if not payload then
    notify(err .. ' in ' .. absolute, vim.log.levels.ERROR)
    return
  end

  local root = vim.fn.fnamemodify(payload.root, ':p')
  local edits = {}
  for index, edit in ipairs(payload.edits or {}) do
    edits[#edits + 1] = normalize_edit(root, edit, index)
  end

  state.session = {
    path = absolute,
    root = root,
    version = payload.version,
    session_id = payload.session_id,
    source = payload.source,
    created_at = payload.created_at,
    edits = edits,
  }
  resolve_all()
  state.current_index = first_edit_index()

  if state.current_index == 0 then
    notify('Loaded session with no edits', vim.log.levels.WARN)
    return
  end

  local edit = current_edit()
  jump_to_edit(edit)
  render_preview(edit)
  notify(string.format('Loaded %d agent edits from %s', #edits, vim.fn.fnamemodify(absolute, ':~:.')))
end

function M.import(raw_json)
  local payload, err = decode_payload(raw_json)
  if not payload then
    notify(err, vim.log.levels.ERROR)
    return
  end

  local path = persist_payload(payload, raw_json)
  M.load(path)
end

function M.import_clipboard()
  local raw_json = vim.fn.getreg '+'
  if not raw_json or vim.trim(raw_json) == '' then
    notify('Clipboard is empty', vim.log.levels.WARN)
    return
  end

  M.import(raw_json)
end

function M.import_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local raw_json = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
  if vim.trim(raw_json) == '' then
    notify('Current buffer is empty', vim.log.levels.WARN)
    return
  end

  M.import(raw_json)
end

function M.load_latest()
  local path = latest_session_file(repo_root())
  if not path then
    notify('No saved agent edit sessions found', vim.log.levels.WARN)
    return
  end

  M.load(path)
end

function M.next()
  step(1)
end

function M.prev()
  step(-1)
end

function M.preview()
  local edit = current_edit()
  if not edit then
    return
  end

  resolve_edit(edit)
  jump_to_edit(edit)
  render_preview(edit)
end

function M.status()
  resolve_all()
  render_status()
end

function M.accept()
  local edit = current_edit()
  if not edit then
    return
  end

  if apply_edit(edit) then
    notify('Applied ' .. edit.id)
    resolve_all()
    render_preview(edit)
  end
end

function M.reject()
  local edit = current_edit()
  if not edit then
    return
  end

  edit.status = 'rejected'
  edit.resolution = nil
  notify('Rejected ' .. edit.id)
  render_preview(edit)
end

function M.setup()
  vim.api.nvim_create_user_command('AgentEditsLoad', function(opts)
    M.load(opts.args)
  end, {
    nargs = 1,
    complete = 'file',
  })

  vim.api.nvim_create_user_command('AgentEditsImportClipboard', function()
    M.import_clipboard()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsImportBuffer', function()
    M.import_buffer()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsLoadLatest', function()
    M.load_latest()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsNext', function()
    M.next()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsPrev', function()
    M.prev()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsPreview', function()
    M.preview()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsAccept', function()
    M.accept()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsReject', function()
    M.reject()
  end, {})

  vim.api.nvim_create_user_command('AgentEditsStatus', function()
    M.status()
  end, {})
end

return M
