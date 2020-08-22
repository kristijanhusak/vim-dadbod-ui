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

function! db_ui#utils#readfile(file) abort
  try
    let content = readfile(a:file)
    let content = json_decode(join(content, "\n"))
    if type(content) !=? type([])
      throw 'Connections file not a valid array'
    endif
    return content
  catch /.*/
    call db_ui#utils#echo_warning(printf("Error reading connections file.\nValidate that content of file %s is valid json array.\nIf it's empty, feel free to delete it.", a:file))
    return []
  endtry
endfunction

function! db_ui#utils#quote_query_value(val) abort
  if a:val =~? "^'.*'$" || a:val =~? '^[0-9]*$' || a:val =~? '^\(true\|false\)$'
    return a:val
  endif

  return "'".a:val."'"
endfunction

function! db_ui#utils#set_mapping(key, plug, ...)
  let mode = a:0 > 0 ? a:1 : 'n'

  if hasmapto(a:plug, mode)
    return
  endif

  let keys = a:key
  if type(a:key) ==? type('')
    let keys = [a:key]
  endif

  for key in keys
    silent! exe mode.'map <buffer><nowait> '.key.' '.a:plug
  endfor
endfunction

function! db_ui#utils#print_debug(msg) abort
  if !g:dbui_debug
    return
  endif

  echom '[DBUI Debug] '.string(a:msg)
endfunction
