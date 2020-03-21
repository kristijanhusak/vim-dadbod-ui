if exists('g:loaded_dbui')
  finish
endif
let g:loaded_dbui = 1

let g:db_ui_winwidth = get(g:, 'db_ui_winwidth', 40)

command! DBUI call db_ui#open()

augroup dbui
  autocmd!
  autocmd FileType __dbui__ nmap <buffer> o <Plug>(DBUI_SelectLine)
  autocmd FileType __dbui__ nmap <buffer> R <Plug>(DBUI_Redraw)
augroup END
