function! db_ui#utils#echo_err(text, ...) abort
  echohl Error
  call db_ui#utils#echo_msg(a:text, a:0 > 0)
  echohl None
endfunction

function! db_ui#utils#echo_warning(text, ...) abort
  echohl WarningMsg
  call db_ui#utils#echo_msg(a:text, a:0 > 0)
  echohl None
endfunction

function! db_ui#utils#echo_msg(text, ...) abort
  let permanent = a:0 > 0 && a:1
  redraw!
  if permanent
    let message = type(a:text) !=? type('') ? string(a:text) : a:text
    let message = split(message, "\n")
    echom '[DBUI] '.message[0]
    for msg in message[1:]
      echom msg
    endfor
  else
    echo '[DBUI] '.a:text
  endif
endfunction

function! db_ui#utils#slug(str) abort
  return substitute(a:str, '[^A-Za-z0-9_\-]', '', 'g')
endfunction

function! db_ui#utils#input(name, default) abort
  return input(a:name, a:default)
endfunction

function! db_ui#utils#inputlist(list) abort
  return inputlist(a:list)
endfunction
