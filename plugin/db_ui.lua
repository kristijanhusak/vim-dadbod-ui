-- Prevent loading multiple times
if vim.g.loaded_db_ui_lua then
  return
end
vim.g.loaded_db_ui_lua = true

-- Load the main module
local db_ui = require('db_ui')
local config = require('db_ui.config')

-- Set up autocommands for dbout files
local augroup = vim.api.nvim_create_augroup('db_ui_lua', { clear = true })

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = augroup,
  pattern = '*.dbout',
  callback = function()
    vim.bo.filetype = 'dbout'
  end
})

vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup,
  pattern = '*.dbout',
  callback = function()
    vim.cmd('silent! call db_ui#save_dbout(expand("<afile>"))')
  end
})

vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'dbout',
  callback = function()
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'db_ui#dbout#foldexpr(v:lnum)'
    vim.cmd('silent! normal!zo')
  end
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  group = augroup,
  pattern = '*',
  callback = function()
    if vim.bo.filetype == 'dbout' or vim.bo.filetype == 'dbui' then
      vim.cmd('stopinsert')
    end
  end
})

-- Define user commands
vim.api.nvim_create_user_command('DBUI', function(opts)
  db_ui.open(opts.mods)
end, { desc = 'Open DBUI drawer' })

vim.api.nvim_create_user_command('DBUIToggle', function()
  db_ui.toggle()
end, { desc = 'Toggle DBUI drawer' })

vim.api.nvim_create_user_command('DBUIClose', function()
  db_ui.close()
end, { desc = 'Close DBUI drawer' })

vim.api.nvim_create_user_command('DBUIAddConnection', function()
  local connections = require('db_ui.connections')
  connections:new():add()
end, { desc = 'Add a new database connection' })

vim.api.nvim_create_user_command('DBUIFindBuffer', function()
  db_ui.find_buffer()
end, { desc = 'Find current buffer in DBUI' })

vim.api.nvim_create_user_command('DBUIRenameBuffer', function()
  -- This will be implemented
  vim.notify('DBUIRenameBuffer not yet implemented', vim.log.levels.WARN)
end, { desc = 'Rename current buffer' })

vim.api.nvim_create_user_command('DBUILastQueryInfo', function()
  -- This will be implemented
  vim.notify('DBUILastQueryInfo not yet implemented', vim.log.levels.WARN)
end, { desc = 'Show last query information' })

-- Load filetype plugins if not disabled
if not config.disable_mappings and not config.disable_mappings_dbui then
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'dbui',
    callback = function()
      local utils = require('db_ui.utils')
      utils.set_mapping({ 'o', '<CR>', '<2-LeftMouse>' }, '<Plug>(DBUI_SelectLine)')
      utils.set_mapping('S', '<Plug>(DBUI_SelectLineVsplit)')
      utils.set_mapping('R', '<Plug>(DBUI_Redraw)')
      utils.set_mapping('d', '<Plug>(DBUI_DeleteLine)')
      utils.set_mapping('A', '<Plug>(DBUI_AddConnection)')
      utils.set_mapping('H', '<Plug>(DBUI_ToggleDetails)')
      utils.set_mapping('r', '<Plug>(DBUI_RenameLine)')
      utils.set_mapping('q', '<Plug>(DBUI_Quit)')
      utils.set_mapping('<c-k>', '<Plug>(DBUI_GotoFirstSibling)')
      utils.set_mapping('<c-j>', '<Plug>(DBUI_GotoLastSibling)')
      utils.set_mapping('<C-p>', '<Plug>(DBUI_GotoParentNode)')
      utils.set_mapping('<C-n>', '<Plug>(DBUI_GotoChildNode)')
      utils.set_mapping('K', '<Plug>(DBUI_GotoPrevSibling)')
      utils.set_mapping('J', '<Plug>(DBUI_GotoNextSibling)')
    end
  })
end

if not config.disable_mappings and not config.disable_mappings_sql then
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'sql',
    callback = function()
      local utils = require('db_ui.utils')
      utils.set_mapping('<Leader>W', '<Plug>(DBUI_SaveQuery)')
      utils.set_mapping('<Leader>E', '<Plug>(DBUI_EditBindParameters)')
      utils.set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)')
      utils.set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)', 'v')
    end
  })
end

-- Setup with any existing configuration
config.setup() 