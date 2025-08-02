local config = require('db_ui.config')
local utils = require('db_ui.utils')
local notifications = require('db_ui.notifications')

local M = {}

-- Connections class
local Connections = {}
Connections.__index = Connections

function M:new(drawer)
  local instance = setmetatable({}, Connections)
  instance.drawer = drawer
  return instance
end

function Connections:add()
  if config.save_location == '' then
    return notifications.error('Please set up valid save location via save_location config')
  end
  
  return self:add_full_url()
end

function Connections:add_full_url()
  local url = ''
  
  -- Get URL from user
  local success, result = pcall(function()
    url = utils.input('Enter connection url: ', url)
    if url == '' then
      error('URL cannot be empty')
    end
    
    -- Validate URL using vim-dadbod
    vim.fn['db#url#parse'](url)
    return url
  end)
  
  if not success then
    return notifications.error(result)
  end
  
  url = result
  
  -- Get name from user
  local success2, name = pcall(function()
    return self:enter_db_name(url)
  end)
  
  if not success2 then
    return notifications.error(name)
  end
  
  return self:save(name, url)
end

function Connections:enter_db_name(url)
  local parsed_url = vim.fn['db#url#parse'](url)
  local suggested_name = ''
  
  if parsed_url and parsed_url.path then
    suggested_name = parsed_url.path:gsub('^/', '')
  end
  
  if suggested_name == '' and parsed_url and parsed_url.host then
    suggested_name = parsed_url.host
  end
  
  local name = utils.input('Enter connection name: ', suggested_name)
  if name == '' then
    error('Connection name cannot be empty')
  end
  
  -- Check for duplicates
  local connections = self:read()
  for _, conn in ipairs(connections) do
    if conn.name == name then
      local choice = vim.fn.confirm(
        string.format('Connection with name "%s" already exists. Overwrite?', name),
        '&Yes\n&No'
      )
      if choice ~= 1 then
        error('Connection not saved')
      end
      break
    end
  end
  
  return name
end

function Connections:save(name, url)
  local connections = self:read()
  local found = false
  
  -- Update existing or add new
  for i, conn in ipairs(connections) do
    if conn.name == name then
      connections[i] = { name = name, url = url }
      found = true
      break
    end
  end
  
  if not found then
    table.insert(connections, { name = name, url = url })
  end
  
  if self:write(connections) then
    notifications.success(string.format('Connection "%s" saved successfully', name))
    if self.drawer then
      self.drawer:render({ dbs = true })
    end
    return true
  else
    notifications.error('Failed to save connection')
    return false
  end
end

function Connections:delete(db)
  local confirm_delete = vim.fn.confirm(
    string.format('Are you sure you want to delete connection %s?', db.name),
    '&Yes\n&No\n&Cancel'
  )
  
  if confirm_delete ~= 1 then
    return
  end
  
  local connections = self:read()
  local new_connections = {}
  
  for _, conn in ipairs(connections) do
    if not (conn.name == db.name and conn.url == db.url) then
      table.insert(new_connections, conn)
    end
  end
  
  if self:write(new_connections) then
    notifications.success(string.format('Connection "%s" deleted successfully', db.name))
    if self.drawer then
      self.drawer:render({ dbs = true })
    end
    return true
  else
    notifications.error('Failed to delete connection')
    return false
  end
end

function Connections:edit(db)
  if db.source ~= 'file' then
    return notifications.error('Cannot edit connections added via variables.')
  end
  
  local connections = self:read()
  local target_index = nil
  
  for i, conn in ipairs(connections) do
    if conn.name == db.name and conn.url == db.url then
      target_index = i
      break
    end
  end
  
  if not target_index then
    return notifications.error('Connection not found in file.')
  end
  
  local current_conn = connections[target_index]
  
  -- Edit URL
  local new_url = utils.input('Enter new connection url: ', current_conn.url)
  if new_url == '' then
    return notifications.error('URL cannot be empty')
  end
  
  -- Validate URL
  local success, result = pcall(vim.fn['db#url#parse'], new_url)
  if not success then
    return notifications.error('Invalid URL: ' .. result)
  end
  
  -- Edit name
  local new_name = utils.input('Enter new connection name: ', current_conn.name)
  if new_name == '' then
    return notifications.error('Name cannot be empty')
  end
  
  -- Check for name conflicts (excluding current connection)
  for i, conn in ipairs(connections) do
    if i ~= target_index and conn.name == new_name then
      local choice = vim.fn.confirm(
        string.format('Connection with name "%s" already exists. Overwrite?', new_name),
        '&Yes\n&No'
      )
      if choice ~= 1 then
        return
      end
      -- Remove the conflicting connection
      table.remove(connections, i)
      if i < target_index then
        target_index = target_index - 1
      end
      break
    end
  end
  
  -- Update connection
  connections[target_index] = { name = new_name, url = new_url }
  
  if self:write(connections) then
    notifications.success(string.format('Connection updated successfully'))
    if self.drawer then
      self.drawer:render({ dbs = true })
    end
    return true
  else
    notifications.error('Failed to update connection')
    return false
  end
end

function Connections:rename(db)
  if db.source ~= 'file' then
    return notifications.error('Cannot edit connections added via variables.')
  end
  
  local connections = self:read()
  local target_index = nil
  
  for i, conn in ipairs(connections) do
    if conn.name == db.name and conn.url == db.url then
      target_index = i
      break
    end
  end
  
  if not target_index then
    return notifications.error('Connection not found in file.')
  end
  
  local current_conn = connections[target_index]
  local new_name = utils.input('Enter new connection name: ', current_conn.name)
  
  if new_name == '' then
    return notifications.error('Name cannot be empty')
  end
  
  if new_name == current_conn.name then
    return notifications.info('Name unchanged')
  end
  
  -- Check for name conflicts
  for _, conn in ipairs(connections) do
    if conn.name == new_name then
      return notifications.error(string.format('Connection with name "%s" already exists', new_name))
    end
  end
  
  -- Update name
  connections[target_index].name = new_name
  
  if self:write(connections) then
    notifications.success(string.format('Connection renamed to "%s"', new_name))
    if self.drawer then
      self.drawer:render({ dbs = true })
    end
    return true
  else
    notifications.error('Failed to rename connection')
    return false
  end
end

function Connections:list()
  return self:read()
end

function Connections:read()
  if self.drawer and self.drawer.dbui.connections_path ~= '' then
    return utils.readfile(self.drawer.dbui.connections_path)
  else
    local connections_path = vim.fn.fnamemodify(config.save_location, ':p'):gsub('/$', '') .. '/connections.json'
    return utils.readfile(connections_path)
  end
end

function Connections:write(data)
  local connections_path
  if self.drawer and self.drawer.dbui.connections_path ~= '' then
    connections_path = self.drawer.dbui.connections_path
  else
    connections_path = vim.fn.fnamemodify(config.save_location, ':p'):gsub('/$', '') .. '/connections.json'
  end
  
  return utils.writefile(connections_path, data)
end

function Connections:get_save_location()
  if self.drawer and self.drawer.dbui.save_path ~= '' then
    return self.drawer.dbui.save_path
  else
    return vim.fn.fnamemodify(config.save_location, ':p'):gsub('/$', '')
  end
end

-- Validate connection by testing connectivity
function Connections:validate(url)
  local success, result = pcall(function()
    local parsed = vim.fn['db#url#parse'](url)
    if not parsed then
      error('Failed to parse URL')
    end
    
    -- Try to connect (this might take time)
    local conn = vim.fn['db#connect'](url)
    if conn == '' then
      error('Failed to connect to database')
    end
    
    return true
  end)
  
  return success, result
end

-- Import connections from a file
function Connections:import_from_file(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return notifications.error('File not readable: ' .. filepath)
  end
  
  local imported_data = utils.readfile(filepath)
  if vim.tbl_isempty(imported_data) then
    return notifications.error('No valid connections found in file')
  end
  
  local current_connections = self:read()
  local imported_count = 0
  local skipped_count = 0
  
  for _, conn in ipairs(imported_data) do
    if conn.name and conn.url then
      -- Check for duplicates
      local exists = false
      for _, existing in ipairs(current_connections) do
        if existing.name == conn.name then
          exists = true
          break
        end
      end
      
      if not exists then
        table.insert(current_connections, conn)
        imported_count = imported_count + 1
      else
        skipped_count = skipped_count + 1
      end
    end
  end
  
  if imported_count > 0 then
    if self:write(current_connections) then
      notifications.success(string.format(
        'Imported %d connections, skipped %d duplicates',
        imported_count, skipped_count
      ))
      if self.drawer then
        self.drawer:render({ dbs = true })
      end
    else
      notifications.error('Failed to save imported connections')
    end
  else
    notifications.info('No new connections to import')
  end
end

-- Export connections to a file
function Connections:export_to_file(filepath)
  local connections = self:read()
  if vim.tbl_isempty(connections) then
    return notifications.error('No connections to export')
  end
  
  if utils.writefile(filepath, connections) then
    notifications.success(string.format('Exported %d connections to %s', #connections, filepath))
  else
    notifications.error('Failed to export connections')
  end
end

return M 