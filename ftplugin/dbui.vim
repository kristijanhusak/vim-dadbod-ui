if get(g:, 'db_ui_disable_mappings', 0) || get(g:, 'db_ui_disable_mappings_dbui', 0)
  finish
endif

call db_ui#utils#set_mapping(['o', '<CR>', '<2-LeftMouse>'], '<Plug>(DBUI_SelectLine)')
call db_ui#utils#set_mapping('S', '<Plug>(DBUI_SelectLineVsplit)')
call db_ui#utils#set_mapping('R', '<Plug>(DBUI_Redraw)')
call db_ui#utils#set_mapping('d', '<Plug>(DBUI_DeleteLine)')
call db_ui#utils#set_mapping('A', '<Plug>(DBUI_AddConnection)')
call db_ui#utils#set_mapping('H', '<Plug>(DBUI_ToggleDetails)')
call db_ui#utils#set_mapping('r', '<Plug>(DBUI_RenameLine)')
call db_ui#utils#set_mapping('q', '<Plug>(DBUI_Quit)')
call db_ui#utils#set_mapping('<c-k>', '<Plug>(DBUI_GotoFirstSibling)')
call db_ui#utils#set_mapping('<c-j>', '<Plug>(DBUI_GotoLastSibling)')
call db_ui#utils#set_mapping('<C-p>', '<Plug>(DBUI_GotoParentNode)')
call db_ui#utils#set_mapping('<C-n>', '<Plug>(DBUI_GotoChildNode)')
call db_ui#utils#set_mapping('K', '<Plug>(DBUI_GotoPrevSibling)')
call db_ui#utils#set_mapping('J', '<Plug>(DBUI_GotoNextSibling)')
