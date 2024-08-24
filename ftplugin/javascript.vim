if get(g:, 'db_ui_disable_mappings', 0) || get(g:, 'db_ui_disable_mappings_javascript', 0) || get(b:, 'dbui_db_key_name', '') == ''
  finish
endif

call db_ui#utils#set_mapping('<Leader>W', '<Plug>(DBUI_SaveQuery)')
call db_ui#utils#set_mapping('<Leader>E', '<Plug>(DBUI_EditBindParameters)')
call db_ui#utils#set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)')
call db_ui#utils#set_mapping('<Leader>S', '<Plug>(DBUI_ExecuteQuery)', 'v')
