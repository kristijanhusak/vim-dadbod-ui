local config = require('db_ui.config')
local drawer = require('db_ui.drawer')
local connections = require('db_ui.connections')
local utils = require('db_ui.utils')
local notifications = require('db_ui.notifications')

local M = {}

-- Global instance to maintain state
local dbui_instance = nil

-- Main DBUI class
local DBUI = {}
DBUI.__index = DBUI

function DBUI:new()
  local instance = setmetatable({}, self)
  
  instance.dbs = {}
  instance.dbs_list = {}
  instance.save_path = ""
  instance.connections_path = ""
  instance.tmp_location = ""
  instance.drawer = nil
  instance.old_buffers = {}
  instance.dbout_list = {}
  
  instance:setup_paths()
  instance:populate_dbs()
  instance.drawer = drawer:new(instance)
  
  return instance
end

function DBUI:setup_paths()
  if config.save_location ~= "" then
    self.save_path = vim.fn.fnamemodify(config.save_location, ':p'):gsub('/$', '')
    self.connections_path = string.format('%s/connections.json', self.save_path)
  end
  
  if config.tmp_query_location ~= "" then
    local tmp_loc = vim.fn.fnamemodify(config.tmp_query_location, ':p'):gsub('/$', '')
    if vim.fn.isdirectory(tmp_loc) == 0 then
      vim.fn.mkdir(tmp_loc, 'p')
    end
    self.tmp_location = tmp_loc
    self.old_buffers = vim.fn.glob(tmp_loc .. '/*', true, true)
  end
end

function DBUI:populate_dbs()
  self.dbs_list = {}
  self:populate_from_dotenv()
  self:populate_from_env()
  self:populate_from_global_variable()
  self:populate_from_connections_file()
  
  for _, db in ipairs(self.dbs_list) do
    local key_name = string.format('%s_%s', db.name, db.source)
    if not self.dbs[key_name] or db.url ~= self.dbs[key_name].url then
      local new_entry = self:generate_new_db_entry(db)
      if new_entry then
        self.dbs[key_name] = new_entry
      end
    else
      self.dbs[key_name] = self.drawer:populate(self.dbs[key_name])
    end
  end
end

function DBUI:populate_from_global_variable()
  if vim.g.db and vim.g.db ~= "" then
    local url = self:resolve_url_global_variable(vim.g.db)
    local gdb_name = vim.split(url, '/')
    gdb_name = gdb_name[#gdb_name]
    self:add_if_not_exists(gdb_name, url, 'g:dbs')
  end
  
  if not vim.g.dbs or vim.tbl_isempty(vim.g.dbs) then
    return
  end
  
  if type(vim.g.dbs) == 'table' then
    for db_name, db_url in pairs(vim.g.dbs) do
      if type(db_url) == 'table' then
        -- Handle array format [{name = "...", url = "..."}]
        for _, db in ipairs(vim.g.dbs) do
          self:add_if_not_exists(db.name, self:resolve_url_global_variable(db.url), 'g:dbs')
        end
        break
      else
        -- Handle dictionary format {name = "url"}
        self:add_if_not_exists(db_name, self:resolve_url_global_variable(db_url), 'g:dbs')
      end
    end
  end
end

function DBUI:populate_from_dotenv()
  local prefix = config.dotenv_variable_prefix
  local all_envs = vim.fn.environ and vim.fn.environ() or {}
  
  -- Add dotenv support if available
  if vim.fn.exists('*DotenvGet') == 1 then
    local dotenv_vars = vim.fn.DotenvGet()
    all_envs = vim.tbl_extend('force', all_envs, dotenv_vars)
  end
  
  for name, url in pairs(all_envs) do
    if string.find(name, prefix, 1, true) then
      local db_name = string.lower(name:gsub(prefix, ''))
      self:add_if_not_exists(db_name, url, 'dotenv')
    end
  end
end

function DBUI:populate_from_env()
  local env_url = self:env(config.env_variable_url)
  if env_url == "" then
    return
  end
  
  local env_name = self:env(config.env_variable_name)
  if env_name == "" then
    local url_parts = vim.split(env_url, '/')
    env_name = url_parts[#url_parts] or ""
  end
  
  if env_name == "" then
    notifications.error(string.format(
      'Found %s variable for db url, but unable to parse the name. Please provide name via %s',
      config.env_variable_url, config.env_variable_name
    ))
    return
  end
  
  self:add_if_not_exists(env_name, env_url, 'env')
end

function DBUI:populate_from_connections_file()
  if self.connections_path == "" or vim.fn.filereadable(self.connections_path) == 0 then
    return
  end
  
  local file_content = utils.readfile(self.connections_path)
  for _, conn in ipairs(file_content) do
    self:add_if_not_exists(conn.name, conn.url, 'file')
  end
end

function DBUI:resolve_url_global_variable(value)
  if type(value) == 'string' then
    return value
  elseif type(value) == 'function' then
    return value()
  else
    error('Invalid type for global variable database url: ' .. type(value))
  end
end

function DBUI:env(var)
  if vim.fn.exists('*DotenvGet') == 1 then
    return vim.fn.DotenvGet(var) or ""
  else
    return vim.env[var] or ""
  end
end

function DBUI:add_if_not_exists(name, url, source)
  for _, existing in ipairs(self.dbs_list) do
    if existing.name == name and existing.source == source then
      notifications.warning(string.format(
        'Warning: Duplicate connection name "%s" in "%s" source. First one added has precedence.',
        name, source
      ))
      return
    end
  end
  
  table.insert(self.dbs_list, {
    name = name,
    url = self:resolve_url(url),
    source = source,
    key_name = string.format('%s_%s', name, source)
  })
end

function DBUI:resolve_url(url)
  -- This will need vim-dadbod integration
  -- For now, return as-is
  return url
end

function DBUI:generate_new_db_entry(db)
  -- Parse URL using vim-dadbod
  local parsed_url = self:parse_url(db.url)
  if vim.tbl_isempty(parsed_url) then
    return nil
  end
  
  local db_name = (parsed_url.path or ""):gsub('^/', '')
  local save_path = ""
  if self.save_path ~= "" then
    save_path = string.format('%s/%s', self.save_path, db.name)
  end
  
  local buffers = {}
  for _, buf in ipairs(self.old_buffers) do
    local filename = vim.fn.fnamemodify(buf, ':t')
    if filename:match('^' .. db.name .. '%-') then
      table.insert(buffers, buf)
    end
  end
  
  local entry = {
    url = db.url,
    conn = "",
    conn_error = "",
    conn_tried = false,
    source = db.source,
    scheme = "",
    table_helpers = {},
    expanded = false,
    tables = { expanded = false, items = {}, list = {} },
    schemas = { expanded = false, items = {}, list = {} },
    saved_queries = { expanded = false, list = {} },
    buffers = { expanded = false, list = buffers, tmp = {} },
    save_path = save_path,
    db_name = db_name ~= "" and db_name or db.name,
    name = db.name,
    key_name = string.format('%s_%s', db.name, db.source),
    schema_support = false,
    quote = false,
    default_scheme = "",
    filetype = ""
  }
  
  self:populate_schema_info(entry)
  return entry
end

function DBUI:parse_url(url)
  -- This needs vim-dadbod integration
  local success, result = pcall(vim.fn['db#url#parse'], url)
  if success then
    return result
  else
    notifications.error(result)
    return {}
  end
end

function DBUI:populate_schema_info(db)
  -- This will be implemented with schema support
  db.scheme = ""
  db.table_helpers = {}
  db.schema_support = false
  db.quote = false
  db.default_scheme = ""
  db.filetype = "sql"
end

function DBUI:connect(db)
  if db.conn ~= "" then
    return db
  end
  
  local success, result = pcall(function()
    local start_time = vim.loop.hrtime()
    notifications.info('Connecting to db ' .. db.name .. '...')
    
    -- This needs vim-dadbod integration
    db.conn = vim.fn['db#connect'](db.url)
    db.conn_error = ""
    self:populate_schema_info(db)
    
    local elapsed = (vim.loop.hrtime() - start_time) / 1e9
    notifications.info(string.format('Connected to db %s after %.2f sec.', db.name, elapsed))
  end)
  
  if not success then
    db.conn_error = result
    db.conn = ""
    notifications.error('Error connecting to db ' .. db.name .. ': ' .. result, { width = 80 })
  end
  
  vim.cmd('redraw!')
  db.conn_tried = true
  return db
end

function DBUI:get_instance()
  if not dbui_instance then
    dbui_instance = self:new()
  end
  return dbui_instance
end

-- Public API functions
function M.open(mods)
  local instance = DBUI:get_instance()
  return instance.drawer:open(mods)
end

function M.toggle()
  local instance = DBUI:get_instance()
  return instance.drawer:toggle()
end

function M.close()
  local instance = DBUI:get_instance()
  return instance.drawer:quit()
end

function M.find_buffer()
  local instance = DBUI:get_instance()
  if #instance.dbs_list == 0 then
    return notifications.error('No database entries found in DBUI.')
  end
  
  -- Implementation details for buffer finding
  -- This needs more logic from the original
end

function M.connections_list()
  local instance = DBUI:get_instance()
  local result = {}
  for _, db in ipairs(instance.dbs_list) do
    table.insert(result, {
      name = db.name,
      url = db.url,
      is_connected = instance.dbs[db.key_name].conn ~= "",
      source = db.source
    })
  end
  return result
end

function M.reset_state()
  dbui_instance = nil
end

return M 