if exists('g:loaded_dbui')
  finish
endif
let g:loaded_dbui = 1

let g:db_ui_winwidth = get(g:, 'db_ui_winwidth', 40)
let g:db_ui_default_query = get(g:, 'db_ui_default_query', 'SELECT * from "{table}" LIMIT 200;')
let g:db_ui_icons = extend({
      \ 'db_collapsed': '[+]',
      \ 'db_expanded': '[-]',
      \ 'table': '>',
      \ 'buffer': '*',
      \ }, get(g:, 'db_ui_icons', {}))

command! DBUI call db_ui#open()

augroup dbui
  autocmd!
  autocmd FileType dbui nmap <buffer> o <Plug>(DBUI_SelectLine)
  autocmd FileType dbui nmap <buffer> R <Plug>(DBUI_Redraw)
augroup END
