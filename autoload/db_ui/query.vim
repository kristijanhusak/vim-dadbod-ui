let s:buffer_counter = {}

function! db_ui#query#open(item) abort
  let db = g:db_ui_drawer.dbs[a:item.db_name]
  if a:item.type ==? 'buffer'
    return s:open_buffer(db, a:item.file_path)
  endif
  let suffix = 'query'
  let table = ''
  if a:item.type !=? 'query'
    let suffix = a:item.label
    let table = a:item.label
  endif

  let buffer_basename = printf('[%s] %s', db.name, suffix)
  if has_key(s:buffer_counter, buffer_basename)
    let new_name = buffer_basename.'-'.s:buffer_counter[buffer_basename]
    let s:buffer_counter[buffer_basename] += 1
    let buffer_basename = new_name
  else
    let s:buffer_counter[buffer_basename] = 1
  endif
  let buffer_name = printf('%s.%s', tempname(), buffer_basename)
  call s:open_buffer(db, buffer_name, table)
  nnoremap <silent><Plug>(DBUI_SaveQuery) :call <sid>save_query()<CR>
endfunction

function! s:focus_window() abort
  if winnr('$') ==? 1
    vertical new
    return
  endif

  let found = 0
  for win in range(1, winnr('$'))
    let buf = winbufnr(win)
    if !empty(getbufvar(buf, 'db_ui_database'))
      let found = 1
      exe win.'wincmd w'
      break
    endif
  endfor

  if !found
    2wincmd w
  endif
endfunction

function s:open_buffer(db, buffer_name, ...)
  call s:focus_window()
  let table = get(a:, 1, '')
  let bufnr = bufnr(a:buffer_name)
  if bufnr > -1
    silent! exe 'b '.bufnr
    return
  endif

  silent! exe 'edit '.a:buffer_name
  let b:db_ui_database = {'name': a:db.name, 'url': a:db.url, 'save_path': a:db.save_path }
  let db_buffers = g:db_ui_drawer.dbs[a:db.name].buffers

  if index(db_buffers.list, a:buffer_name) ==? -1
    if empty(db_buffers.list)
      let db_buffers.expanded = 1
    endif
    call add(db_buffers.list, a:buffer_name)
  endif
  setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
  augroup db_ui_query
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> silent! exe '%DB '.b:db_ui_database.url
    autocmd BufDelete,BufWipeout <buffer> silent! call remove(g:db_ui_drawer[b:db_ui_database.name].buffers.list, bufname(str2nr(expand('<abuf>'))))
  augroup END

  if empty(table)
    return
  endif

  let content = substitute(g:db_ui_default_query, '{table}', table, 'g')
  silent 1,$delete _
  call setline(1, content)
endfunction

function! s:save_query() abort
  if !isdirectory(b:db_ui_database.save_path)
    call mkdir(dir, 'p')
  endif

  call inputsave()
  let name = input('Save as: ')
  call inputrestore()

  let full_name = printf('%s/%s', b:db_ui_database.save_path, name)
  if filereadable(full_name)
    return db_ui#utils#echo_err('That file already exists. Please choose another name.')
  endif

  exe 'write '.full_name
endfunction
