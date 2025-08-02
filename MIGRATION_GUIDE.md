# Migration Guide: Vimscript to Lua

This guide will help you migrate from the original vim-dadbod-ui (Vimscript) to the new Lua rewrite.

## Quick Migration Checklist

- [ ] Update plugin installation in your package manager
- [ ] Replace Vimscript configuration with Lua setup
- [ ] Migrate custom functions to Lua
- [ ] Test all existing workflows
- [ ] Update any automation/scripts that depend on the plugin

## Step-by-Step Migration

### 1. Update Plugin Installation

#### Before (Vimscript version)
```lua
-- lazy.nvim
{
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
  },
  cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
  end,
}
```

#### After (Lua version)
```lua
-- lazy.nvim  
{
  'your-username/vim-dadbod-ui-lua',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
  },
  cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
  config = function()
    require('db_ui').setup({
      use_nerd_fonts = true,
    })
  end,
}
```

### 2. Configuration Migration

#### Global Variables → Lua Setup

The Lua version supports both approaches, but the new Lua configuration is recommended:

| Vimscript Global Variable | Lua Configuration Key | Notes |
|---------------------------|----------------------|--------|
| `g:db_ui_use_nerd_fonts` | `use_nerd_fonts` | Boolean value |
| `g:db_ui_winwidth` | `winwidth` | Number value |
| `g:db_ui_win_position` | `win_position` | String: 'left' or 'right' |
| `g:db_ui_save_location` | `save_location` | String path |
| `g:db_ui_tmp_query_location` | `tmp_query_location` | String path |
| `g:db_ui_default_query` | `default_query` | String template |
| `g:db_ui_execute_on_save` | `execute_on_save` | Boolean value |
| `g:db_ui_auto_execute_table_helpers` | `auto_execute_table_helpers` | Boolean value |
| `g:db_ui_use_nvim_notify` | `use_nvim_notify` | Boolean value |
| `g:db_ui_disable_mappings` | `disable_mappings` | Boolean value |
| `g:db_ui_table_helpers` | `table_helpers` | Table/dictionary |

#### Example Migration

**Before:**
```vim
" In your init.vim or vimrc
let g:db_ui_use_nerd_fonts = 1
let g:db_ui_winwidth = 50
let g:db_ui_save_location = '~/my-queries'
let g:db_ui_execute_on_save = 0
let g:db_ui_table_helpers = {
\   'postgresql': {
\     'Count': 'SELECT COUNT(*) FROM {table}',
\     'Explain': 'EXPLAIN ANALYZE {last_query}'
\   }
\ }
```

**After:**
```lua
-- In your init.lua
require('db_ui').setup({
  use_nerd_fonts = true,
  winwidth = 50,
  save_location = '~/my-queries',
  execute_on_save = false,
  table_helpers = {
    postgresql = {
      Count = 'SELECT COUNT(*) FROM {table}',
      Explain = 'EXPLAIN ANALYZE {last_query}'
    }
  }
})
```

### 3. Database Connection Migration

Your existing database connections will work without changes:

#### Global Variables (Continue Working)
```lua
-- These continue to work as before
vim.g.db = 'postgresql://user:pass@localhost/mydb'

vim.g.dbs = {
  dev = 'postgresql://user:pass@localhost/dev',
  prod = 'postgresql://user:pass@prod-host/prod'
}
```

#### Environment Variables (Continue Working)
```bash
# These continue to work as before
export DBUI_URL="postgresql://user:pass@localhost/mydb"
export DB_UI_DEV="postgresql://user:pass@localhost/dev"
```

### 4. Custom Function Migration

#### Buffer Name Generator

**Before:**
```vim
function! MyBufferNameGenerator(opts)
  return strftime('%Y%m%d') . '-' . a:opts.table
endfunction
let g:Db_ui_buffer_name_generator = function('MyBufferNameGenerator')
```

**After:**
```lua
require('db_ui').setup({
  buffer_name_generator = function(opts)
    return os.date('%Y%m%d') .. '-' .. opts.table
  end
})
```

#### Table Name Sorter

**Before:**
```vim
function! MyTableSorter(tables)
  return sort(a:tables, 'i')  " Case-insensitive sort
endfunction
let g:Db_ui_table_name_sorter = function('MyTableSorter')
```

**After:**
```lua
require('db_ui').setup({
  table_name_sorter = function(tables)
    table.sort(tables, function(a, b) 
      return string.lower(a) < string.lower(b) 
    end)
    return tables
  end
})
```

### 5. Custom Mappings Migration

#### Disable Default Mappings

**Before:**
```vim
let g:db_ui_disable_mappings = 1
let g:db_ui_disable_mappings_sql = 1
```

**After:**
```lua
require('db_ui').setup({
  disable_mappings = true,
  disable_mappings_sql = true,
})
```

#### Custom Mappings

**Before:**
```vim
" After disabling defaults, set your own
autocmd FileType dbui nnoremap <buffer> <leader>o <Plug>(DBUI_SelectLine)
autocmd FileType sql nnoremap <buffer> <leader>r <Plug>(DBUI_ExecuteQuery)
```

**After:**
```lua
-- After disabling defaults in setup()
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'dbui',
  callback = function()
    vim.keymap.set('n', '<leader>o', '<Plug>(DBUI_SelectLine)', { buffer = true })
  end
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'sql', 
  callback = function()
    vim.keymap.set('n', '<leader>r', '<Plug>(DBUI_ExecuteQuery)', { buffer = true })
  end
})
```

### 6. Icon Customization Migration

**Before:**
```vim
let g:db_ui_icons = {
\   'expanded': {
\     'db': '📊 ',
\     'table': '📋 '
\   },
\   'collapsed': {
\     'db': '📊▶',
\     'table': '📋▶'
\   }
\ }
```

**After:**
```lua
require('db_ui').setup({
  icons = {
    expanded = {
      db = '📊 ',
      table = '📋 '
    },
    collapsed = {
      db = '📊▶',
      table = '📋▶'  
    }
  }
})
```

## New Features in Lua Version

### Enhanced Notifications

```lua
require('db_ui').setup({
  use_nvim_notify = true,  -- Use nvim-notify if available
  notification_width = 50,
  disable_info_notifications = false,
})
```

### Better Debugging

```lua
require('db_ui').setup({
  debug = true,  -- Detailed logging for troubleshooting
})
```

### Programmatic API

```lua
local db_ui = require('db_ui')

-- New functions not available in Vimscript version
db_ui.export_connections('backup.json')
db_ui.import_connections('restore.json')
db_ui.add_connection()  -- Programmatic connection adding
```

## Testing Your Migration

### 1. Verify Basic Functionality
1. Open DBUI: `:DBUI`
2. Check that all your connections appear
3. Test opening tables and running queries
4. Verify saved queries load correctly

### 2. Test Custom Configuration
1. Check that your custom icons appear
2. Test custom table helpers
3. Verify custom mappings work
4. Test custom functions (buffer name generator, etc.)

### 3. Test Advanced Features
1. Test bind parameters in queries
2. Verify query saving/loading
3. Check connection management
4. Test all key mappings

## Common Migration Issues

### Issue: Commands Not Found
**Problem:** `:DBUI` command not available after migration

**Solution:** Ensure you're calling `require('db_ui').setup()` in your config:
```lua
require('db_ui').setup()
```

### Issue: Connections Not Loading
**Problem:** Previously working connections don't appear

**Solutions:**
1. Check that vim-dadbod is still installed
2. Verify connection URLs are still valid
3. Check that `save_location` path is correct
4. Enable debug mode to see what's happening

### Issue: Custom Functions Not Working
**Problem:** Custom buffer name generator or table sorter not working

**Solution:** Migrate the function from Vimscript to Lua syntax:
```lua
-- Instead of vim function reference, use Lua function
buffer_name_generator = function(opts)
  -- Your logic here
end
```

### Issue: Mappings Conflict
**Problem:** Key mappings don't work or conflict with other plugins

**Solutions:**
1. Use the granular disable options:
   ```lua
   require('db_ui').setup({
     disable_mappings_sql = true,  -- Just disable SQL mappings
   })
   ```
2. Set your own mappings after disabling defaults

### Issue: Performance Problems
**Problem:** Lua version seems slower than Vimscript version

**Solutions:**
1. Enable debug mode to identify bottlenecks
2. Check if you have many connections/large schemas
3. Report the issue with debug output

## Rollback Plan

If you need to rollback to the Vimscript version:

1. **Update plugin installation** back to `kristijanhusak/vim-dadbod-ui`
2. **Remove Lua setup** and restore global variables:
   ```vim
   " Remove this line
   " require('db_ui').setup({...})
   
   " Restore global variables
   let g:db_ui_use_nerd_fonts = 1
   " ... other settings
   ```
3. **Convert custom Lua functions** back to Vimscript
4. **Restart Neovim** to ensure clean state

## Getting Help

If you encounter issues during migration:

1. **Enable debug mode** in the Lua version:
   ```lua
   require('db_ui').setup({ debug = true })
   ```

2. **Check the documentation:** `:help db-ui-lua`

3. **Compare configurations** side-by-side using this guide

4. **Open an issue** with:
   - Your old configuration
   - Your new configuration  
   - Debug output
   - Steps to reproduce the problem

## Benefits After Migration

Once migrated, you'll enjoy:

- ✅ **Better Performance** - Native Lua execution
- ✅ **Enhanced Notifications** - Beautiful nvim-notify integration  
- ✅ **Improved Error Handling** - Better error messages and validation
- ✅ **Modern API** - Programmatic access to all functionality
- ✅ **Better Debugging** - Detailed logging and troubleshooting
- ✅ **Future-Proof** - Built for modern Neovim features 