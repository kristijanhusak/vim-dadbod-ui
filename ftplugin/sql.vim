if get(g:, 'dbui_disable_mappings', 0)
  finish
endif

call db_ui#utils#set_mapping('<Leader>W', '<Plug>(DBUI_SaveQuery)')
call db_ui#utils#set_mapping('<Leader>E', '<Plug>(DBUI_EditBindParameters)')
call db_ui#utils#set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)')
call db_ui#utils#set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)', 'v')
