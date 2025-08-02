local config = require('db_ui.config')
local utils = require('db_ui.utils')
local notifications = require('db_ui.notifications')

local M = {}

-- Query execution class
local Query = {}
Query.__index = Query

-- Global query info for tracking
local query_info = {
  last_query_start_time = 0,
  last_query_time = 0
}

function M:new(drawer)
  local instance = setmetatable({}, Query)
  
  instance.drawer = drawer
  instance.buffer_counter = {}
  instance.last_query = {}
  
  -- Set up async query handling
  local augroup = vim.api.nvim_create_augroup('dbui_async_queries', { clear = true })
  
  vim.api.nvim_create_autocmd('User', {
    group = augroup,
    pattern = '*DBExecutePre',
    callback = function()
      query_info.last_query_start_time = vim.loop.hrtime()
    end
  })
  
  vim.api.nvim_create_autocmd('User', {
    group = augroup,
    pattern = '*DBExecutePost', 
    callback = function()
      local elapsed = (vim.loop.hrtime() - query_info.last_query_start_time) / 1e9
      query_info.last_query_time = elapsed
      notifications.info(string.format('Query executed in %.2f seconds', elapsed))
    end
  })
  
  return instance
end

function Query:open(item, edit_action)
  local db = self.drawer.dbui.dbs[item.dbui_db_key_name]
  
  if item.type == 'buffer' then
    return self:open_buffer(db, item.file_path, edit_action)
  end
  
  local label = item.label or ''
  local table = ''
  local schema = ''
  
  if item.type ~= 'query' then
    table = item.table or ''
    schema = item.schema or ''
  end
  
  local buffer_name = self:generate_buffer_name(db, {
    schema = schema,
    table = table,
    label = label,
    filetype = db.filetype
  })
  
  self:open_buffer(db, buffer_name, edit_action, {
    table = table,
    content = item.content,
    schema = schema
  })
end

function Query:generate_buffer_name(db, opts)
  local time = os.date('%Y-%m-%d-%H-%M-%S')
  local suffix = 'query'
  
  if opts.table ~= '' then
    suffix = string.format('%s-%s', opts.table, opts.label)
  end
  
  local buffer_name = utils.slug(string.format('%s-%s', db.name, suffix))
  
  if config.buffer_name_generator and type(config.buffer_name_generator) == 'function' then
    buffer_name = string.format('%s-%s', db.name, config.buffer_name_generator(opts))
  end
  
  if self.drawer.dbui.tmp_location ~= '' then
    return string.format('%s/%s', self.drawer.dbui.tmp_location, buffer_name)
  end
  
  local tmp_name = string.format('%s/%s', vim.fn.fnamemodify(vim.fn.tempname(), ':p:h'), buffer_name)
  table.insert(db.buffers.tmp, tmp_name)
  return tmp_name
end

function Query:focus_window()
  local win_pos = config.win_position == 'left' and 'botright' or 'topleft'
  local win_cmd = 'vertical ' .. win_pos .. ' new'
  
  if vim.fn.winnr('$') == 1 then
    vim.cmd(win_cmd)
    return
  end
  
  local found = false
  
  -- Look for existing query buffer
  for win = 1, vim.fn.winnr('$') do
    local buf = vim.fn.winbufnr(win)
    if vim.fn.getbufvar(buf, 'dbui_db_key_name') ~= '' then
      found = true
      vim.cmd(win .. 'wincmd w')
      break
    end
  end
  
  -- Look for any modifiable buffer
  if not found then
    for win = 1, vim.fn.winnr('$') do
      local filetype = vim.fn.getwinvar(win, '&filetype')
      local buftype = vim.fn.getwinvar(win, '&buftype')
      local modifiable = vim.fn.getwinvar(win, '&modifiable')
      
      if filetype ~= 'dbui' and buftype ~= 'nofile' and modifiable == 1 then
        found = true
        vim.cmd(win .. 'wincmd w')
        break
      end
    end
  end
  
  if not found then
    vim.cmd(win_cmd)
  end
end

function Query:open_buffer(db, buffer_name, edit_action, opts)
  opts = opts or {}
  local table = opts.table or ''
  local schema = opts.schema or ''
  local default_content = opts.content or config.default_query
  local was_single_win = vim.fn.winnr('$') == 1
  
  if edit_action == 'edit' then
    self:focus_window()
    local bufnr = vim.fn.bufnr(buffer_name)
    if bufnr > -1 then
      vim.cmd('b ' .. bufnr)
      self:setup_buffer(db, vim.tbl_extend('force', opts, { existing_buffer = true }), buffer_name, was_single_win)
      return
    end
  end
  
  vim.cmd(edit_action .. ' ' .. buffer_name)
  self:setup_buffer(db, opts, buffer_name, was_single_win)
  
  if table == '' then
    return
  end
  
  -- Process template variables
  local optional_schema = schema == db.default_scheme and '' or schema
  
  if optional_schema ~= '' then
    if db.quote then
      optional_schema = '"' .. optional_schema .. '"'
    end
    optional_schema = optional_schema .. '.'
  end
  
  local content = default_content:gsub('{table}', table)
  content = content:gsub('{optional_schema}', optional_schema)
  content = content:gsub('{schema}', schema)
  
  local db_name = schema ~= '' and schema or db.db_name
  content = content:gsub('{dbname}', db_name)
  content = content:gsub('{last_query}', table.concat(self.last_query, '\n'))
  
  -- Set buffer content
  vim.cmd('silent 1,$delete _')
  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  
  if config.auto_execute_table_helpers then
    if config.execute_on_save then
      vim.cmd('write')
    else
      self:execute_query()
    end
  end
end

function Query:setup_buffer(db, opts, buffer_name, was_single_win)
  self:resize_if_single(was_single_win)
  
  -- Set buffer variables
  vim.b.dbui_db_key_name = db.key_name
  vim.b.dbui_table_name = opts.table or ''
  vim.b.dbui_schema_name = opts.schema or ''
  vim.b.db = db.conn
  
  local is_existing_buffer = opts.existing_buffer or false
  local is_tmp = self.drawer.dbui:is_tmp_location_buffer(db, buffer_name)
  local db_buffers = self.drawer.dbui.dbs[db.key_name].buffers
  
  -- Add to buffers list
  local buffer_in_list = false
  for _, buf in ipairs(db_buffers.list) do
    if buf == buffer_name then
      buffer_in_list = true
      break
    end
  end
  
  if not buffer_in_list then
    if #db_buffers.list == 0 then
      db_buffers.expanded = true
    end
    table.insert(db_buffers.list, buffer_name)
    self.drawer:render()
  end
  
  -- Set filetype and options
  if vim.bo.filetype ~= db.filetype or not is_existing_buffer then
    vim.bo.swapfile = false
    vim.bo.wrap = false
    vim.bo.spell = false
    vim.bo.modifiable = true
    vim.bo.filetype = db.filetype
  end
  
  local is_sql = vim.bo.filetype == db.filetype
  
  -- Set up buffer mappings
  local opts_map = { buffer = true, silent = true }
  vim.keymap.set('n', '<Plug>(DBUI_EditBindParameters)', function() self:edit_bind_parameters() end, opts_map)
  vim.keymap.set('n', '<Plug>(DBUI_ExecuteQuery)', function() self:execute_query() end, opts_map)
  vim.keymap.set('v', '<Plug>(DBUI_ExecuteQuery)', function() self:execute_query(true) end, opts_map)
  
  if is_tmp and is_sql then
    vim.keymap.set('n', '<Plug>(DBUI_SaveQuery)', function() self:save_query() end, opts_map)
  end
  
  -- Set up autocommands
  local bufnr = vim.api.nvim_get_current_buf()
  local augroup = vim.api.nvim_create_augroup('db_ui_query_' .. bufnr, { clear = true })
  
  if config.execute_on_save and is_sql then
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = augroup,
      buffer = bufnr,
      callback = function() self:execute_query() end
    })
  end
  
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = augroup,
    buffer = bufnr,
    callback = function() self:remove_buffer(bufnr) end
  })
end

function Query:resize_if_single(is_single_win)
  if is_single_win then
    local drawer_winnr = self.drawer:get_winnr()
    if drawer_winnr > 0 then
      vim.cmd(drawer_winnr .. 'wincmd w')
      vim.cmd('vertical resize ' .. config.winwidth)
      vim.cmd('wincmd p')
    end
  end
end

function Query:remove_buffer(bufnr)
  local dbui_db_key_name = vim.fn.getbufvar(bufnr, 'dbui_db_key_name')
  
  if dbui_db_key_name == '' then
    return
  end
  
  local db = self.drawer.dbui.dbs[dbui_db_key_name]
  local buffer_name = vim.fn.bufname(bufnr)
  
  -- Remove from buffers list
  for i, buf in ipairs(db.buffers.list) do
    if buf == buffer_name then
      table.remove(db.buffers.list, i)
      break
    end
  end
  
  -- Remove from tmp list
  for i, buf in ipairs(db.buffers.tmp) do
    if buf == buffer_name then
      table.remove(db.buffers.tmp, i)
      break
    end
  end
  
  return self.drawer:render()
end

function Query:execute_query(is_visual_mode)
  is_visual_mode = is_visual_mode or false
  local lines = self:get_lines(is_visual_mode)
  
  -- Start query timing
  query_info.last_query_start_time = vim.loop.hrtime()
  
  local bind_param_pattern = '(^|[[:blank:]]|[^:])(' .. config.bind_param_pattern .. ')'
  
  if not is_visual_mode and vim.fn.search(bind_param_pattern, 'n') <= 0 then
    utils.print_debug({ message = 'Executing whole buffer', command = '%DB' })
    vim.cmd('silent! %DB')
  else
    local db = self.drawer.dbui.dbs[vim.b.dbui_db_key_name]
    self:execute_lines(db, lines, is_visual_mode)
  end
  
  -- Check for async support
  local has_async = vim.fn.exists('*db#cancel') == 1
  if has_async then
    notifications.info('Executing query...')
  else
    local elapsed = (vim.loop.hrtime() - query_info.last_query_start_time) / 1e9
    query_info.last_query_time = elapsed
    notifications.info(string.format('Query executed in %.2f seconds', elapsed))
  end
  
  self.last_query = lines
end

function Query:execute_lines(db, lines, is_visual_mode)
  local extension = vim.fn['db#adapter#call'](db.conn, 'input_extension', {}, 'sql')
  local filename = vim.fn.tempname() .. '.' .. extension
  local processed_lines = vim.deepcopy(lines)
  
  local bind_param_pattern = '(^|[[:blank:]]|[^:])(' .. config.bind_param_pattern .. ')'
  local should_inject_vars = vim.fn.match(table.concat(lines), bind_param_pattern) > -1
  
  if should_inject_vars then
    local success, result = pcall(function()
      return self:inject_variables(processed_lines)
    end)
    
    if not success then
      return notifications.error(result)
    end
    processed_lines = result
  end
  
  if #processed_lines == 1 then
    utils.print_debug({
      message = 'Executing single line',
      line = processed_lines[1],
      command = 'DB ' .. processed_lines[1]
    })
    vim.cmd('DB ' .. processed_lines[1])
    return processed_lines
  end
  
  if not should_inject_vars then
    utils.print_debug({ message = 'Executing visual selection', command = "'<,'>DB" })
    vim.cmd("'<,'>DB")
  else
    utils.print_debug({
      message = 'Executing multiple lines',
      lines = processed_lines,
      input_filename = filename,
      command = 'DB < ' .. filename
    })
    vim.fn.writefile(processed_lines, filename)
    vim.cmd('DB < ' .. filename)
  end
  
  return processed_lines
end

function Query:get_lines(is_visual_mode)
  if not is_visual_mode then
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
  end
  
  return utils.get_visual_selection()
end

function Query:inject_variables(lines)
  local processed_lines = {}
  local bind_param_pattern = config.bind_param_pattern
  local variables = {}
  
  -- Find all parameters
  for _, line in ipairs(lines) do
    for param in line:gmatch(':(' .. bind_param_pattern .. ')') do
      if not variables[param] then
        variables[param] = true
      end
    end
  end
  
  -- Get values for parameters
  local param_values = {}
  for param in pairs(variables) do
    local value = utils.input(string.format('Enter value for %s: ', param), '')
    if value == '' then
      error(string.format('Parameter %s cannot be empty', param))
    end
    param_values[param] = value
  end
  
  -- Replace parameters in lines
  for _, line in ipairs(lines) do
    local processed_line = line
    for param, value in pairs(param_values) do
      processed_line = processed_line:gsub(':' .. param, value)
    end
    table.insert(processed_lines, processed_line)
  end
  
  return processed_lines
end

function Query:edit_bind_parameters()
  notifications.info('Edit bind parameters functionality to be implemented')
end

function Query:save_query()
  local db_key_name = vim.b.dbui_db_key_name
  if not db_key_name then
    return notifications.error('No database associated with this buffer')
  end
  
  local db = self.drawer.dbui.dbs[db_key_name]
  if db.save_path == '' then
    return notifications.error('No save path configured for this database')
  end
  
  local filename = utils.input('Enter query name: ', '')
  if filename == '' then
    return notifications.error('Query name cannot be empty')
  end
  
  -- Ensure directory exists
  if vim.fn.isdirectory(db.save_path) == 0 then
    vim.fn.mkdir(db.save_path, 'p')
  end
  
  local full_path = string.format('%s/%s.sql', db.save_path, filename)
  
  -- Check if file exists
  if vim.fn.filereadable(full_path) == 1 then
    local choice = vim.fn.confirm(
      string.format('File %s already exists. Overwrite?', filename),
      '&Yes\n&No'
    )
    if choice ~= 1 then
      return
    end
  end
  
  -- Save the file
  vim.cmd('write ' .. full_path)
  
  -- Add to saved queries if not already there
  local found = false
  for _, query in ipairs(db.saved_queries.list) do
    if query == full_path then
      found = true
      break
    end
  end
  
  if not found then
    table.insert(db.saved_queries.list, full_path)
  end
  
  notifications.success(string.format('Query saved as %s', filename))
  self.drawer:render()
end

function Query:get_last_query_info()
  return {
    last_query = self.last_query,
    last_query_time = query_info.last_query_time
  }
end

return M 