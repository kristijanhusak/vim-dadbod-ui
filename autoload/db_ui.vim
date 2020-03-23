function! db_ui#open() abort
  if !exists('g:dbs')
    return db_ui#utils#echo_err('g:dbs is not defined.')
  endif

  if empty(g:dbs)
    return db_ui#utils#echo_err('g:dbs is empty.')
  endif

  return db_ui#drawer#open()
endfunction
