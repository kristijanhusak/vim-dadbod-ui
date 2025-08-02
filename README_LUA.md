# vim-dadbod-ui Lua Rewrite

A complete Lua rewrite of the popular vim-dadbod-ui plugin for Neovim. This version provides all the functionality of the original Vimscript version with improved performance, better integration with modern Neovim features, and enhanced extensibility.

## Features

- 🔥 **Complete Lua rewrite** - Native Neovim Lua implementation
- 🚀 **Improved Performance** - Faster startup and query execution  
- 🎨 **Modern UI** - Better integration with Neovim's UI capabilities
- 🔧 **Enhanced Configuration** - More flexible and extensible configuration system
- 📱 **nvim-notify Integration** - Beautiful notifications with nvim-notify support
- 🌙 **Lazy Loading** - Optimized startup with lazy loading
- 🔒 **Type Safety** - Better error handling and validation
- 🎯 **Backwards Compatible** - Easy migration from Vimscript version

## Installation

### lazy.nvim

```lua
{
  'your-username/vim-dadbod-ui-lua',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  cmd = {
    'DBUI',
    'DBUIToggle', 
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  config = function()
    require('db_ui').setup({
      use_nerd_fonts = true,
      use_nvim_notify = true,
      save_location = '~/.local/share/db_ui',
      -- Add your configuration here
    })
  end,
}
```

### packer.nvim

```lua
use {
  'your-username/vim-dadbod-ui-lua',
  requires = {
    'tpope/vim-dadbod',
    'kristijanhusak/vim-dadbod-completion', -- Optional
  },
  config = function()
    require('db_ui').setup({
      use_nerd_fonts = true,
      use_nvim_notify = true,
    })
  end
}
```

## Configuration

The Lua version provides a modern configuration system that supports both the new Lua configuration format and backwards compatibility with existing Vimscript global variables.

### Basic Setup

```lua
require('db_ui').setup({
  -- UI Configuration
  use_nerd_fonts = true,
  use_nvim_notify = true,
  winwidth = 40,
  win_position = 'left', -- 'left' or 'right'
  
  -- Database Configuration
  save_location = '~/.local/share/db_ui',
  tmp_query_location = '',
  default_query = 'SELECT * from "{table}" LIMIT 200;',
  
  -- Execution Configuration
  execute_on_save = true,
  auto_execute_table_helpers = false,
  
  -- Notification Configuration
  notification_width = 40,
  disable_info_notifications = false,
  force_echo_notifications = false,
  
  -- Environment Configuration
  dotenv_variable_prefix = 'DB_UI_',
  env_variable_url = 'DBUI_URL',
  env_variable_name = 'DBUI_NAME',
  
  -- Mapping Configuration
  disable_mappings = false,
  disable_mappings_dbui = false,
  disable_mappings_dbout = false,
  disable_mappings_sql = false,
  
  -- Advanced Configuration
  table_helpers = {},
  hide_schemas = {},
  bind_param_pattern = [[\w\+]],
  debug = false,
  
  -- Custom Functions
  buffer_name_generator = nil, -- function(opts) -> string
  table_name_sorter = nil,     -- function(tables) -> sorted_tables
  
  -- Icons Configuration
  icons = {
    expanded = '▾',
    collapsed = '▸',
    saved_query = '*',
    new_query = '+',
    tables = '~',
    buffers = '»',
    add_connection = '[+]',
    connection_ok = '✓',
    connection_error = '✕',
  }
})
```

### Database Connections

The plugin supports multiple ways to define database connections:

#### 1. Global Variables (Backwards Compatible)

```lua
-- Single connection
vim.g.db = 'postgresql://user:password@localhost/mydb'

-- Multiple connections (dictionary format)
vim.g.dbs = {
  dev = 'postgresql://user:password@localhost/dev_db',
  staging = 'mysql://user:password@staging-host/staging_db',
  prod = 'postgresql://user:password@prod-host/prod_db',
}

-- Multiple connections (array format)
vim.g.dbs = {
  { name = 'dev', url = 'postgresql://user:password@localhost/dev_db' },
  { name = 'staging', url = 'mysql://user:password@staging-host/staging_db' },
}
```

#### 2. Environment Variables

```bash
export DBUI_URL="postgresql://user:password@localhost/mydb"
export DBUI_NAME="my_database"

# Or with custom prefix
export DB_UI_DEV="postgresql://user:password@localhost/dev_db"
export DB_UI_PROD="postgresql://user:password@prod-host/prod_db"
```

#### 3. Dotenv Integration

Create a `.env` file in your project:

```bash
DB_UI_DEV=postgresql://user:password@localhost/dev_db
DB_UI_STAGING=mysql://user:password@staging-host/staging_db
DB_UI_PROD=postgresql://user:password@prod-host/prod_db
```

#### 4. Interactive Connection Management

```lua
-- Add connection via command
:DBUIAddConnection

-- Or programmatically
require('db_ui').add_connection()

-- Import/Export connections
require('db_ui').import_connections('path/to/connections.json')
require('db_ui').export_connections('path/to/backup.json')
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:DBUI` | Open the database drawer |
| `:DBUIToggle` | Toggle the database drawer |
| `:DBUIClose` | Close the database drawer |
| `:DBUIAddConnection` | Add a new database connection |
| `:DBUIFindBuffer` | Find current buffer in DBUI |

### Key Mappings

#### DBUI Drawer Mappings

| Key | Action |
|-----|--------|
| `o`, `<CR>`, `<2-LeftMouse>` | Open/Toggle item |
| `S` | Open in vertical split |
| `d` | Delete connection/query |
| `R` | Redraw/Refresh |
| `A` | Add new connection |
| `H` | Toggle details |
| `r` | Rename |
| `q` | Close drawer |
| `?` | Toggle help |

#### Navigation Mappings

| Key | Action |
|-----|--------|
| `<C-j>` | Go to last sibling |
| `<C-k>` | Go to first sibling |
| `J` | Go to next sibling |
| `K` | Go to previous sibling |
| `<C-n>` | Go to child node |
| `<C-p>` | Go to parent node |

#### SQL Buffer Mappings

| Key | Action |
|-----|--------|
| `<Leader>S` | Execute query |
| `<Leader>W` | Save query |
| `<Leader>E` | Edit bind parameters |

### Programmatic API

```lua
local db_ui = require('db_ui')

-- Core functions
db_ui.open()           -- Open drawer
db_ui.toggle()         -- Toggle drawer
db_ui.close()          -- Close drawer
db_ui.find_buffer()    -- Find buffer in DBUI

-- Connection management
db_ui.add_connection()
db_ui.export_connections('backup.json')
db_ui.import_connections('restore.json')
db_ui.connections_list()

-- State management
db_ui.reset_state()    -- Reset all state
```

## Migration from Vimscript Version

The Lua version is designed to be mostly backwards compatible. Here's how to migrate:

### 1. Installation

Replace your existing vim-dadbod-ui installation with the Lua version in your plugin manager.

### 2. Configuration Migration

Your existing global variables will continue to work, but you can optionally migrate to the new Lua configuration:

**Before (Vimscript):**
```vim
let g:db_ui_use_nerd_fonts = 1
let g:db_ui_winwidth = 40
let g:db_ui_save_location = '~/.local/share/db_ui'
```

**After (Lua):**
```lua
require('db_ui').setup({
  use_nerd_fonts = true,
  winwidth = 40,
  save_location = '~/.local/share/db_ui',
})
```

### 3. Custom Functions

If you have custom functions, convert them to Lua:

**Before:**
```vim
function! MyCustomBufferNameGenerator(opts)
  return a:opts.table . '-custom'
endfunction
let g:Db_ui_buffer_name_generator = function('MyCustomBufferNameGenerator')
```

**After:**
```lua
require('db_ui').setup({
  buffer_name_generator = function(opts)
    return opts.table .. '-custom'
  end
})
```

## Advanced Features

### Custom Table Helpers

```lua
require('db_ui').setup({
  table_helpers = {
    postgresql = {
      List = 'SELECT * FROM {table} LIMIT 200',
      Count = 'SELECT COUNT(*) FROM {table}',
      Describe = '\\d+ {table}',
      Indexes = 'SELECT * FROM pg_indexes WHERE tablename = \'{table}\'',
    },
    mysql = {
      List = 'SELECT * FROM {table} LIMIT 200',
      Describe = 'DESCRIBE {table}',
    }
  }
})
```

### Custom Icons

```lua
require('db_ui').setup({
  icons = {
    expanded = {
      db = '📊 ',
      table = '📋 ',
      schema = '📁 ',
    },
    collapsed = {
      db = '📊▶',
      table = '📋▶',
      schema = '📁▶',
    },
    saved_query = '💾',
    new_query = '✨',
  }
})
```

### Bind Parameters

The plugin supports bind parameters in your queries:

```sql
SELECT * FROM users WHERE age > :min_age AND city = :city;
```

When executed, you'll be prompted to enter values for `:min_age` and `:city`.

### Integration with nvim-notify

Beautiful notifications with progress indicators:

```lua
require('db_ui').setup({
  use_nvim_notify = true,
  notification_width = 50,
})
```

## Troubleshooting

### Common Issues

1. **Commands not found**: Make sure the plugin is properly loaded and `require('db_ui').setup()` is called.

2. **Connection issues**: Verify your database URLs and ensure vim-dadbod is installed.

3. **Mapping conflicts**: Use the disable options to prevent conflicts:
   ```lua
   require('db_ui').setup({
     disable_mappings_sql = true, -- If you have conflicting SQL mappings
   })
   ```

4. **Performance issues**: Enable debug mode to see what's happening:
   ```lua
   require('db_ui').setup({
     debug = true,
   })
   ```

### Debug Mode

Enable debug mode to see detailed logging:

```lua
require('db_ui').setup({
  debug = true,
})
```

This will show detailed information about:
- Connection attempts
- Query execution
- Buffer management
- UI rendering

## Contributing

Contributions are welcome! Please see the original vim-dadbod-ui repository for guidelines.

## License

Same as the original vim-dadbod-ui plugin.

## Acknowledgments

- [tpope](https://github.com/tpope) for the amazing vim-dadbod plugin
- [kristijanhusak](https://github.com/kristijanhusak) for the original vim-dadbod-ui plugin
- The Neovim community for the excellent Lua API 