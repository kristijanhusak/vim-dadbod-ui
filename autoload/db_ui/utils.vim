function! db_ui#utils#echo_err(text) abort
  echohl Error
  echo a:text
  echohl None
endfunction
