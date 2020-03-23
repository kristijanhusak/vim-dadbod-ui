let s:buffer_counter = {}

function! db_ui#query#open_table(drawer, item) abort
  let db = a:drawer.dbs[a:item.db_name]
  let table = a:item.text
  let buffer_basename = printf('[%s] %s', db.name, table)
  if has_key(s:buffer_counter, buffer_basename)
    let new_name = buffer_basename.'-'.s:buffer_counter[buffer_basename]
    let s:buffer_counter[buffer_basename] += 1
    let buffer_basename = new_name
  else
    let s:buffer_counter[buffer_basename] = 1
  endif
  let buffer_name = printf('%s.%s', tempname(), buffer_basename)
  call db_ui#query#open_buffer(a:drawer, buffer_name, table)

  let b:db_ui_table = table
  let b:db_ui = db
  augroup db_ui_query
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> silent! exe '%DB '.b:db_ui.url
    autocmd BufDelete,BufWipeout <buffer> silent! call remove(a:drawer.buffers, str2nr(expand('<abuf>')))
  augroup END
endfunction

function! s:focus_window() abort
  if winnr('$') ==? 1
    vertical new
    return
  endif

  let found = 0
  for win in range(1, winnr('$'))
    let buf = winbufnr(win)
    if !empty(getbufvar(buf, 'db_ui_table'))
      let found = 1
      exe win.'wincmd w'
      break
    endif
  endfor

  if !found
    2wincmd w
  endif
endfunction

function db_ui#query#open_buffer(drawer, buffer_name, table)
  call s:focus_window()
  let bufnr = bufnr(a:buffer_name)
  if bufnr > -1
    silent! exe 'b '.bufnr
    return
  endif

  silent! exe 'edit '.a:buffer_name
  let a:drawer.buffers[bufnr(a:buffer_name)] = a:buffer_name
  let content = substitute(g:db_ui_default_query, '{table}', a:table, 'g')
  setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
  silent 1,$delete _
  call setline(1, content)
endfunction
