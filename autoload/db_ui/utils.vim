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
    call db_ui#notifications#warning([
          \ 'Error reading connections file.',
          \ printf('Validate that content of file %s is valid json array.', a:file),
          \ "If it's empty, feel free to delete it."
          \ ])
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
    silent! exe mode.'map <silent><buffer><nowait> '.key.' '.a:plug
  endfor
endfunction

function! db_ui#utils#print_debug(msg) abort
  if !g:db_ui_debug
    return
  endif

  echom '[DBUI Debug] '.string(a:msg)
endfunction

function! db_ui#utils#is_query_mutation(query) abort
  let blocked_keywords = [
        \ 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER',
        \ 'TRUNCATE', 'REPLACE', 'MERGE',
        \ 'GRANT', 'REVOKE', 'RENAME',
        \ 'CREATE TABLE', 'CREATE INDEX', 'CREATE DATABASE',
        \ 'CREATE SCHEMA', 'CREATE VIEW', 'CREATE FUNCTION',
        \ 'CREATE PROCEDURE', 'CREATE TRIGGER'
        \ ]

  let upper_query = toupper(trim(a:query))

  " Remove single line comments
  let upper_query = substitute(upper_query, '--[^\n]*', '', 'g')
  " Remove multi-line comments
  let upper_query = substitute(upper_query, '/\*\_.\{-}\*/', '', 'g')
  " Remove string literals to avoid false positives
  let upper_query = substitute(upper_query, '''[^'']*''', '''''', 'g')
  let upper_query = substitute(upper_query, '"[^"]*"', '""', 'g')
  let upper_query = trim(upper_query)

  " Split by semicolons to check each statement
  let statements = split(upper_query, ';')
  
  for statement in statements
    let statement = trim(statement)
    if empty(statement)
      continue
    endif
    
    " Check for blocked mutation keywords at the start of each statement
    for blocked_keyword in blocked_keywords
      if statement =~# '^\s*' . blocked_keyword . '\>'
        return 1
      endif

      " Check for WITH clause followed by mutation
      if statement =~# '^\s*WITH\s\+.\{-}\s\+' . blocked_keyword . '\>'
        return 1
      endif
    endfor
  endfor

  return 0
endfunction

function! db_ui#utils#validate_query_for_read_only(query) abort
  if db_ui#utils#is_query_mutation(a:query)
    return 'Mutation queries are not allowed in read-only mode'
  endif
  return ''
endfunction
