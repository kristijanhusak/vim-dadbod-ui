function! db_ui#utils#echo_err(text) abort
  echohl Error
  call db_ui#utils#echo_msg(a:text)
  echohl None
endfunction

function! db_ui#utils#echo_msg(text) abort
  redraw!
  echo a:text
endfunction
