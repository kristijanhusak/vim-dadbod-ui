if exists('g:loaded_dbui')
  finish
endif
let g:loaded_dbui = 1

command! DBUI call db_ui#open()

augroup dbui
  autocmd!
  autocmd FileType sql nmap <buffer> <Leader>e <Plug>(DBUI_Execute)
  autocmd FileType __dbui__ nmap <buffer> o <Plug>(DBUI_Toggle)
  autocmd FileType __dbui__ nmap <buffer> R <Plug>(DBUI_Redraw)
augroup END
