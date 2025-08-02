local config = require('db_ui.config')
local utils = require('db_ui.utils')
local notifications = require('db_ui.notifications')

local M = {}

-- Drawer class
local Drawer = {}
Drawer.__index = Drawer

function M:new(dbui)
  local instance = setmetatable({}, Drawer)
  
  instance.dbui = dbui
  instance.show_details = false
  instance.show_help = false
  instance.show_dbout_list = false
  instance.content = {}
  instance.query = nil
  instance.connections = nil
  
  return instance
end

function Drawer:open(mods)
  if self:is_opened() then
    local winnr = self:get_winnr()
    if winnr > 0 then
      vim.cmd(winnr .. 'wincmd w')
    end
    return
  end
  
  mods = mods or ''
  if mods ~= '' then
    vim.cmd(mods .. ' new dbui')
  else
    local win_pos = config.win_position == 'left' and 'topleft' or 'botright'
    vim.cmd('vertical ' .. win_pos .. ' new dbui')
    vim.cmd('vertical ' .. win_pos .. ' resize ' .. config.winwidth)
  end
  
  -- Set buffer options
  vim.bo.filetype = 'dbui'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.buflisted = false
  vim.bo.swapfile = false
  vim.bo.modifiable = false
  
  -- Set window options
  vim.wo.wrap = false
  vim.wo.spell = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.winfixwidth = true
  
  self:render()
  self:setup_mappings()
  self:setup_autocmds()
  
  -- Trigger user autocommand
  vim.cmd('silent! doautocmd User DBUIOpened')
end

function Drawer:setup_mappings()
  local opts = { buffer = true, silent = true }
  
  -- Selection mappings
  vim.keymap.set('n', '<Plug>(DBUI_SelectLine)', function() self:toggle_line('edit') end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_SelectLineVsplit)', function() self:toggle_line(self:get_split_command()) end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_DeleteLine)', function() self:delete_line() end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_Redraw)', function() self:redraw() end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_AddConnection)', function() self:add_connection() end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_ToggleDetails)', function() self:toggle_details() end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_RenameLine)', function() self:rename_line() end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_Quit)', function() self:quit() end, opts)
  
  -- Navigation mappings
  vim.keymap.set('n', '<Plug>(DBUI_GotoFirstSibling)', function() self:goto_sibling('first') end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_GotoNextSibling)', function() self:goto_sibling('next') end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_GotoPrevSibling)', function() self:goto_sibling('prev') end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_GotoLastSibling)', function() self:goto_sibling('last') end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_GotoParentNode)', function() self:goto_node('parent') end, opts)
  vim.keymap.set('n', '<Plug>(DBUI_GotoChildNode)', function() self:goto_node('child') end, opts)
  
  -- Help toggle
  vim.keymap.set('n', '?', function() self:toggle_help() end, opts)
end

function Drawer:setup_autocmds()
  local bufnr = vim.api.nvim_get_current_buf()
  
  vim.api.nvim_create_autocmd('BufEnter', {
    buffer = bufnr,
    callback = function() self:render() end,
    group = vim.api.nvim_create_augroup('db_ui', { clear = false })
  })
end

function Drawer:get_split_command()
  local query_win_pos = config.win_position == 'left' and 'botright' or 'topleft'
  return 'vertical ' .. query_win_pos .. ' split'
end

function Drawer:is_opened()
  return self:get_winnr() > 0
end

function Drawer:get_winnr()
  for i = 1, vim.fn.winnr('$') do
    if vim.fn.getwinvar(i, '&filetype') == 'dbui' then
      return i
    end
  end
  return 0
end

function Drawer:toggle()
  if self:is_opened() then
    return self:quit()
  else
    return self:open()
  end
end

function Drawer:quit()
  if self:is_opened() then
    local winnr = self:get_winnr()
    local bufnr = vim.fn.winbufnr(winnr)
    vim.cmd('bd' .. bufnr)
  end
end

function Drawer:redraw()
  local item = self:get_current_item()
  if item.level == 0 then
    return self:render({ dbs = true, queries = true })
  else
    return self:render({ db_key_name = item.dbui_db_key_name, queries = true })
  end
end

function Drawer:focus()
  if vim.bo.filetype == 'dbui' then
    return false
  end
  
  local winnr = self:get_winnr()
  if winnr > 0 then
    vim.cmd(winnr .. 'wincmd w')
    return true
  end
  return false
end

function Drawer:render(opts)
  opts = opts or {}
  local restore_win = self:focus()
  
  if vim.bo.filetype ~= 'dbui' then
    return
  end
  
  if opts.dbs then
    local start_time = vim.loop.hrtime()
    notifications.info('Refreshing all databases...')
    self.dbui:populate_dbs()
    local elapsed = (vim.loop.hrtime() - start_time) / 1e9
    notifications.info(string.format('Refreshed all databases after %.2f sec.', elapsed))
  end
  
  if opts.db_key_name then
    local db = self.dbui.dbs[opts.db_key_name]
    notifications.info('Refreshing database ' .. db.name .. '...')
    local start_time = vim.loop.hrtime()
    self.dbui.dbs[opts.db_key_name] = self:populate(db)
    local elapsed = (vim.loop.hrtime() - start_time) / 1e9
    notifications.info(string.format('Refreshed database %s after %.2f sec.', db.name, elapsed))
  end
  
  vim.cmd('redraw!')
  local view = vim.fn.winsaveview()
  self.content = {}
  
  self:render_help()
  
  for _, db in ipairs(self.dbui.dbs_list) do
    if opts.queries then
      self:load_saved_queries(self.dbui.dbs[db.key_name])
    end
    self:add_db(self.dbui.dbs[db.key_name])
  end
  
  if #self.dbui.dbs_list == 0 then
    self:add('" No connections', 'noaction', 'help', '', '', 0)
    self:add('Add connection', 'call_method', 'add_connection', config.icons.add_connection, '', 0)
  end
  
  -- Render dbout list if enabled
  if not vim.tbl_isempty(self.dbui.dbout_list) then
    self:add_dbout_list()
  end
  
  -- Update buffer content
  vim.bo.modifiable = true
  local lines = {}
  for _, item in ipairs(self.content) do
    table.insert(lines, item.label)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modifiable = false
  
  vim.fn.winrestview(view)
  
  if restore_win then
    vim.cmd('wincmd p')
  end
end

function Drawer:render_help()
  if not self.show_help then
    return
  end
  
  self:add('" Help', 'noaction', 'help', '', '', 0)
  self:add('" o/Enter/<2-LeftMouse> : Open/Toggle', 'noaction', 'help', '', '', 0)
  self:add('" S : Open in split', 'noaction', 'help', '', '', 0)
  self:add('" d : Delete', 'noaction', 'help', '', '', 0)
  self:add('" R : Redraw', 'noaction', 'help', '', '', 0)
  self:add('" A : Add connection', 'noaction', 'help', '', '', 0)
  self:add('" H : Toggle details', 'noaction', 'help', '', '', 0)
  self:add('" r : Rename', 'noaction', 'help', '', '', 0)
  self:add('" q : Close', 'noaction', 'help', '', '', 0)
  self:add('', 'noaction', 'help', '', '', 0)
end

function Drawer:add(label, action, type, icon, dbui_db_key_name, level, extra)
  extra = extra or {}
  
  local item = {
    label = label,
    action = action,
    type = type,
    icon = icon,
    dbui_db_key_name = dbui_db_key_name,
    level = level,
  }
  
  -- Add extra fields
  for k, v in pairs(extra) do
    item[k] = v
  end
  
  table.insert(self.content, item)
end

function Drawer:add_db(db)
  local icon = self:get_toggle_icon('db', db)
  local connection_status = ''
  
  if db.conn_tried then
    if db.conn == '' then
      connection_status = ' ' .. config.icons.connection_error
    else
      connection_status = ' ' .. config.icons.connection_ok
    end
  end
  
  self:add(
    db.name .. connection_status,
    'toggle',
    'db',
    icon,
    db.key_name,
    0,
    { expanded = db.expanded }
  )
  
  if not db.expanded then
    return
  end
  
  -- Add saved queries
  self:add(
    'Saved Queries (' .. #db.saved_queries.list .. ')',
    'toggle',
    'saved_queries',
    self:get_toggle_icon('saved_queries', db.saved_queries),
    db.key_name,
    1,
    { expanded = db.saved_queries.expanded }
  )
  
  if db.saved_queries.expanded then
    for _, query_file in ipairs(db.saved_queries.list) do
      local filename = vim.fn.fnamemodify(query_file, ':t')
      self:add(
        filename,
        'open',
        'buffer',
        config.icons.saved_query,
        db.key_name,
        2,
        { file_path = query_file, saved = true }
      )
    end
    
    self:add(
      'New query',
      'open',
      'query',
      config.icons.new_query,
      db.key_name,
      2
    )
  end
  
  -- Add buffers
  if not vim.tbl_isempty(db.buffers.list) then
    self:add(
      'Buffers (' .. #db.buffers.list .. ')',
      'toggle',
      'buffers',
      self:get_toggle_icon('buffers', db.buffers),
      db.key_name,
      1,
      { expanded = db.buffers.expanded }
    )
    
    if db.buffers.expanded then
      for _, buf in ipairs(db.buffers.list) do
        local filename = vim.fn.fnamemodify(buf, ':t')
        self:add(
          filename,
          'open',
          'buffer',
          config.icons.buffers,
          db.key_name,
          2,
          { file_path = buf }
        )
      end
    end
  end
  
  -- Add schemas or tables
  if db.schema_support then
    self:add_schemas(db)
  else
    self:add_tables(db)
  end
end

function Drawer:add_schemas(db)
  self:add(
    'Schemas (' .. #db.schemas.list .. ')',
    'toggle',
    'schemas',
    self:get_toggle_icon('schemas', db.schemas),
    db.key_name,
    1,
    { expanded = db.schemas.expanded }
  )
  
  if not db.schemas.expanded then
    return
  end
  
  for _, schema in ipairs(db.schemas.list) do
    local schema_item = db.schemas.items[schema]
    local tables = schema_item.tables
    
    self:add(
      schema .. ' (' .. #tables.list .. ')',
      'toggle',
      'schemas->items->' .. schema,
      self:get_toggle_icon('schema', schema_item),
      db.key_name,
      2,
      { expanded = schema_item.expanded }
    )
    
    if schema_item.expanded then
      self:render_tables(tables, db, 'schemas->items->' .. schema .. '->tables->items', 3, schema)
    end
  end
end

function Drawer:add_tables(db)
  self:add(
    'Tables (' .. #db.tables.list .. ')',
    'toggle',
    'tables',
    self:get_toggle_icon('tables', db.tables),
    db.key_name,
    1,
    { expanded = db.tables.expanded }
  )
  
  self:render_tables(db.tables, db, 'tables->items', 2, '')
end

function Drawer:render_tables(tables, db, path, level, schema)
  if not tables.expanded then
    return
  end
  
  local tables_list = tables.list
  if config.table_name_sorter and type(config.table_name_sorter) == 'function' then
    tables_list = config.table_name_sorter(tables.list)
  end
  
  for _, table in ipairs(tables_list) do
    self:add(
      table,
      'toggle',
      path .. '->' .. table,
      self:get_toggle_icon('table', tables.items[table]),
      db.key_name,
      level,
      { expanded = tables.items[table].expanded }
    )
    
    if tables.items[table].expanded then
      for helper_name, helper in pairs(db.table_helpers) do
        self:add(
          helper_name,
          'open',
          'table',
          config.icons.tables,
          db.key_name,
          level + 1,
          {
            table = table,
            content = helper,
            schema = schema,
            label = helper_name
          }
        )
      end
    end
  end
end

function Drawer:add_dbout_list()
  if not self.show_dbout_list then
    return
  end
  
  self:add('DB Out', 'toggle', 'dbout_list', '', '', 0)
  
  for file_path, content in pairs(self.dbui.dbout_list) do
    local filename = vim.fn.fnamemodify(file_path, ':t')
    local display = filename
    if content and content ~= '' then
      display = filename .. ' (' .. content .. ')'
    end
    
    self:add(
      display,
      'open',
      'dbout',
      '',
      '',
      1,
      { file_path = file_path }
    )
  end
end

function Drawer:get_toggle_icon(type, item)
  local expanded = item and item.expanded or false
  local icon_set = expanded and config.icons.expanded or config.icons.collapsed
  return icon_set[type] or (expanded and '▾' or '▸')
end

function Drawer:get_current_item()
  local line = vim.fn.line('.')
  return self.content[line] or {}
end

function Drawer:toggle_line(edit_action)
  local item = self:get_current_item()
  
  if item.action == 'noaction' then
    return
  end
  
  if item.action == 'call_method' then
    return self[item.type](self)
  end
  
  if item.type == 'dbout' then
    if self:get_query() then
      self:get_query():focus_window()
      vim.cmd('pedit ' .. item.file_path)
    end
    return
  end
  
  if item.action == 'open' then
    return self:get_query():open(item, edit_action)
  end
  
  local db = self.dbui.dbs[item.dbui_db_key_name]
  local tree = db
  
  if item.type ~= 'db' then
    tree = self:get_nested(db, item.type)
  end
  
  tree.expanded = not tree.expanded
  
  if item.type == 'db' then
    self:toggle_db(db)
  end
  
  return self:render()
end

function Drawer:get_nested(db, path)
  local parts = vim.split(path, '->')
  local current = db
  
  for _, part in ipairs(parts) do
    if current[part] then
      current = current[part]
    end
  end
  
  return current
end

function Drawer:toggle_db(db)
  if not db.expanded then
    return db
  end
  
  self:load_saved_queries(db)
  self.dbui:connect(db)
  
  if db.conn ~= '' then
    self:populate(db)
  end
end

function Drawer:load_saved_queries(db)
  if db.save_path ~= '' then
    db.saved_queries.list = vim.fn.glob(db.save_path .. '/*', true, true)
  end
end

function Drawer:populate(db)
  if db.conn == '' and db.conn_tried then
    self.dbui:connect(db)
  end
  
  if db.schema_support then
    return self:populate_schemas(db)
  else
    return self:populate_tables(db)
  end
end

function Drawer:populate_tables(db)
  db.tables.list = {}
  
  if db.conn == '' then
    return db
  end
  
  -- This would use vim-dadbod to get tables
  local success, tables = pcall(vim.fn['db#adapter#call'], db.conn, 'tables', {db.conn}, {})
  
  if success then
    db.tables.list = tables
    self:populate_table_items(db.tables)
  end
  
  return db
end

function Drawer:populate_schemas(db)
  -- This would be implemented with schema support
  return db
end

function Drawer:populate_table_items(tables_obj)
  for _, table in ipairs(tables_obj.list) do
    if not tables_obj.items[table] then
      tables_obj.items[table] = { expanded = false }
    end
  end
end

function Drawer:delete_line()
  local item = self:get_current_item()
  
  if item.action == 'noaction' then
    return
  end
  
  if item.action == 'toggle' and item.type == 'db' then
    local db = self.dbui.dbs[item.dbui_db_key_name]
    if db.source ~= 'file' then
      return notifications.error('Cannot delete this connection.')
    end
    return self:delete_connection(db)
  end
  
  if item.action ~= 'open' or item.type ~= 'buffer' then
    return
  end
  
  local db = self.dbui.dbs[item.dbui_db_key_name]
  
  if item.saved then
    local choice = vim.fn.confirm('Are you sure you want to delete this saved query?', '&Yes\n&No')
    if choice ~= 1 then
      return
    end
    
    vim.fn.delete(item.file_path)
    
    -- Remove from saved queries list
    for i, query in ipairs(db.saved_queries.list) do
      if query == item.file_path then
        table.remove(db.saved_queries.list, i)
        break
      end
    end
    
    -- Remove from buffers list
    for i, buf in ipairs(db.buffers.list) do
      if buf == item.file_path then
        table.remove(db.buffers.list, i)
        break
      end
    end
    
    notifications.info('Deleted.')
  end
  
  if self.dbui:is_tmp_location_buffer(db, item.file_path) then
    local choice = vim.fn.confirm('Are you sure you want to delete query?', '&Yes\n&No')
    if choice ~= 1 then
      return
    end
    
    vim.fn.delete(item.file_path)
    
    -- Remove from buffers list
    for i, buf in ipairs(db.buffers.list) do
      if buf == item.file_path then
        table.remove(db.buffers.list, i)
        break
      end
    end
    
    notifications.info('Deleted.')
  end
  
  -- Close buffer if open
  local bufnr = vim.fn.bufnr(item.file_path)
  if bufnr ~= -1 then
    local winnr = vim.fn.bufwinnr(bufnr)
    if winnr > 0 then
      vim.cmd(winnr .. 'wincmd w')
      vim.cmd('b#')
    end
    vim.cmd('bw! ' .. bufnr)
  end
  
  self:focus()
  self:render()
end

function Drawer:toggle_help()
  self.show_help = not self.show_help
  return self:render()
end

function Drawer:toggle_details()
  self.show_details = not self.show_details
  return self:render()
end

function Drawer:add_connection()
  if not self.connections then
    self.connections = require('db_ui.connections'):new(self)
  end
  return self.connections:add()
end

function Drawer:delete_connection(db)
  if not self.connections then
    self.connections = require('db_ui.connections'):new(self)
  end
  return self.connections:delete(db)
end

function Drawer:get_query()
  if not self.query then
    self.query = require('db_ui.query'):new(self)
  end
  return self.query
end

-- Navigation functions
function Drawer:goto_sibling(direction)
  -- Implementation for sibling navigation
  local current_line = vim.fn.line('.')
  local item = self.content[current_line]
  
  if not item then
    return
  end
  
  local current_level = item.level
  local target_line = current_line
  
  if direction == 'next' then
    for i = current_line + 1, #self.content do
      local next_item = self.content[i]
      if next_item.level == current_level then
        target_line = i
        break
      elseif next_item.level < current_level then
        break
      end
    end
  elseif direction == 'prev' then
    for i = current_line - 1, 1, -1 do
      local prev_item = self.content[i]
      if prev_item.level == current_level then
        target_line = i
        break
      elseif prev_item.level < current_level then
        break
      end
    end
  elseif direction == 'first' then
    for i = 1, current_line - 1 do
      local first_item = self.content[i]
      if first_item.level == current_level then
        target_line = i
        break
      end
    end
  elseif direction == 'last' then
    for i = #self.content, current_line + 1, -1 do
      local last_item = self.content[i]
      if last_item.level == current_level then
        target_line = i
        break
      end
    end
  end
  
  vim.fn.cursor(target_line, vim.fn.col('.'))
end

function Drawer:goto_node(direction)
  local current_line = vim.fn.line('.')
  local item = self.content[current_line]
  
  if not item then
    return
  end
  
  local current_level = item.level
  local target_line = current_line
  
  if direction == 'parent' then
    for i = current_line - 1, 1, -1 do
      local parent_item = self.content[i]
      if parent_item.level < current_level then
        target_line = i
        break
      end
    end
  elseif direction == 'child' then
    if current_line < #self.content then
      local child_item = self.content[current_line + 1]
      if child_item and child_item.level > current_level then
        target_line = current_line + 1
      end
    end
  end
  
  vim.fn.cursor(target_line, vim.fn.col('.'))
end

function Drawer:rename_line()
  -- Implementation for renaming
  notifications.info('Rename functionality to be implemented')
end

return M 