local M = {}

-- Default configuration values
local defaults = {
  disable_progress_bar = false,
  use_postgres_views = true,
  notification_width = 40,
  winwidth = 40,
  win_position = 'left',
  default_query = 'SELECT * from "{table}" LIMIT 200;',
  save_location = '~/.local/share/db_ui',
  tmp_query_location = '',
  dotenv_variable_prefix = 'DB_UI_',
  env_variable_url = 'DBUI_URL',
  env_variable_name = 'DBUI_NAME',
  disable_mappings = false,
  disable_mappings_dbui = false,
  disable_mappings_dbout = false,
  disable_mappings_sql = false,
  disable_mappings_javascript = false,
  table_helpers = {},
  auto_execute_table_helpers = false,
  show_help = true,
  use_nerd_fonts = false,
  execute_on_save = true,
  force_echo_notifications = false,
  disable_info_notifications = false,
  use_nvim_notify = false,
  buffer_name_generator = nil,
  table_name_sorter = nil,
  debug = false,
  hide_schemas = {},
  bind_param_pattern = [[\w\+]],
  is_oracle_legacy = false,
  icons = {}
}

-- Initialize configuration
function M.setup(user_config)
  user_config = user_config or {}
  
  -- Merge user config with defaults
  for key, default_value in pairs(defaults) do
    local global_var = 'db_ui_' .. key
    local vim_global = vim.g[global_var]
    
    if user_config[key] ~= nil then
      M[key] = user_config[key]
    elseif vim_global ~= nil then
      M[key] = vim_global
    else
      M[key] = default_value
    end
  end
  
  -- Special handling for function references
  if type(M.buffer_name_generator) == 'string' and M.buffer_name_generator ~= '' then
    M.buffer_name_generator = vim.fn[M.buffer_name_generator]
  end
  
  if type(M.table_name_sorter) == 'string' and M.table_name_sorter ~= '' then
    M.table_name_sorter = vim.fn[M.table_name_sorter]
  end
  
  -- Setup icons
  M:setup_icons()
end

function M:setup_icons()
  local user_icons = self.icons
  local expanded_icon = user_icons.expanded or '▾'
  local collapsed_icon = user_icons.collapsed or '▸'
  
  -- Handle custom icon structures
  local expanded_icons = {}
  local collapsed_icons = {}
  
  if type(expanded_icon) == 'table' then
    expanded_icons = expanded_icon
    expanded_icon = '▾'
  end
  
  if type(collapsed_icon) == 'table' then
    collapsed_icons = collapsed_icon
    collapsed_icon = '▸'
  end
  
  -- Default icon set
  self.icons = {
    expanded = {
      db = expanded_icon,
      buffers = expanded_icon,
      saved_queries = expanded_icon,
      schemas = expanded_icon,
      schema = expanded_icon,
      tables = expanded_icon,
      table = expanded_icon,
    },
    collapsed = {
      db = collapsed_icon,
      buffers = collapsed_icon,
      saved_queries = collapsed_icon,
      schemas = collapsed_icon,
      schema = collapsed_icon,
      tables = collapsed_icon,
      table = collapsed_icon,
    },
    saved_query = '*',
    new_query = '+',
    tables = '~',
    buffers = '»',
    add_connection = '[+]',
    connection_ok = '✓',
    connection_error = '✕',
  }
  
  -- Nerd font icons
  if self.use_nerd_fonts then
    self.icons = {
      expanded = {
        db = expanded_icon .. ' 󰆼',
        buffers = expanded_icon .. ' ',
        saved_queries = expanded_icon .. ' ',
        schemas = expanded_icon .. ' ',
        schema = expanded_icon .. ' 󰙅',
        tables = expanded_icon .. ' 󰓱',
        table = expanded_icon .. ' ',
      },
      collapsed = {
        db = collapsed_icon .. ' 󰆼',
        buffers = collapsed_icon .. ' ',
        saved_queries = collapsed_icon .. ' ',
        schemas = collapsed_icon .. ' ',
        schema = collapsed_icon .. ' 󰙅',
        tables = collapsed_icon .. ' 󰓱',
        table = collapsed_icon .. ' ',
      },
      saved_query = '  ',
      new_query = '  󰓰',
      tables = '  󰓫',
      buffers = '  ',
      add_connection = '  󰆺',
      connection_ok = '✓',
      connection_error = '✕',
    }
  end
  
  -- Extend with custom icons
  self.icons.expanded = vim.tbl_extend('force', self.icons.expanded, expanded_icons)
  self.icons.collapsed = vim.tbl_extend('force', self.icons.collapsed, collapsed_icons)
  
  -- Remove processed icons from user_icons and extend with remaining
  local remaining_icons = vim.deepcopy(user_icons)
  remaining_icons.expanded = nil
  remaining_icons.collapsed = nil
  self.icons = vim.tbl_extend('force', self.icons, remaining_icons)
end

-- Initialize with defaults on first load
M.setup()

return M 