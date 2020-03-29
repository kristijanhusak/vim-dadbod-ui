if exists('g:loaded_dbui')
  finish
endif
let g:loaded_dbui = 1

let g:db_ui_winwidth = get(g:, 'db_ui_winwidth', 40)
let g:db_ui_default_query = get(g:, 'db_ui_default_query', 'SELECT * from "{table}" LIMIT 200;')
let g:db_ui_save_location = get(g:, 'db_ui_save_location', '~/.local/share/db_ui')
let g:db_ui_env_variable_prefix = get(g:, 'db_ui_env_variable_prefix', 'DBUI_')
let g:db_ui_disable_mappings = get(g:, 'db_ui_disable_mappings', 0)
let g:db_ui_table_helpers = get(g:, 'db_ui_table_helpers', {})
let g:db_ui_auto_execute_table_helpers = get(g:, 'db_ui_auto_execute_table_helpers', 0)
let g:db_ui_icons = extend({
      \ 'expanded': '▾',
      \ 'collapsed': '▸',
      \ 'saved_sql': '*',
      \ 'new_query': '+',
      \ 'tables': '~',
      \ 'buffers': '»'
      \ }, get(g:, 'db_ui_icons', {}))

function! s:set_mapping(key, plug) abort
  if g:db_ui_disable_mappings
    return
  endif

  if !hasmapto(a:plug)
    silent! exe 'nmap <buffer><nowait> '.a:key.' '.a:plug
  endif
endfunction

augroup dbui
  autocmd!
  autocmd FileType sql call s:set_mapping('<Leader>W', '<Plug>(DBUI_SaveQuery)')
  autocmd FileType dbui call s:set_mapping('o', '<Plug>(DBUI_SelectLine)')
  autocmd FileType dbui call s:set_mapping('S', '<Plug>(DBUI_SelectLineVsplit)')
  autocmd FileType dbui call s:set_mapping('R', '<Plug>(DBUI_Redraw)')
  autocmd FileType dbui call s:set_mapping('d', '<Plug>(DBUI_DeleteLine)')
augroup END

command! DBUI call db_ui#open()
