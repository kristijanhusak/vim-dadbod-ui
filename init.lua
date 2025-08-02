-- vim-dadbod-ui Lua rewrite
-- Main setup function for users

local M = {}

-- Setup function that users can call to configure the plugin
function M.setup(user_config)
  user_config = user_config or {}
  
  -- Load and setup configuration
  local config = require('db_ui.config')
  config.setup(user_config)
  
  -- The plugin will be initialized when commands are first used
  -- This lazy loading approach is better for startup performance
end

-- Export main functions for direct use
function M.open(mods)
  return require('db_ui').open(mods)
end

function M.toggle()
  return require('db_ui').toggle()
end

function M.close()
  return require('db_ui').close()
end

function M.find_buffer()
  return require('db_ui').find_buffer()
end

function M.connections_list()
  return require('db_ui').connections_list()
end

function M.reset_state()
  return require('db_ui').reset_state()
end

-- Utility functions
function M.add_connection()
  local connections = require('db_ui.connections')
  return connections:new():add()
end

function M.export_connections(filepath)
  local connections = require('db_ui.connections')
  return connections:new():export_to_file(filepath)
end

function M.import_connections(filepath)
  local connections = require('db_ui.connections')
  return connections:new():import_from_file(filepath)
end

return M 