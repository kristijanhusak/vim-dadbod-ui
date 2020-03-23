let s:buffer_counter = {}

function! db_ui#query#open_table(item) abort
  let db = g:db_ui_drawer.dbs[a:item.db_name]
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
  call db_ui#query#open_buffer(buffer_name, table)
  let b:db_ui_database = db
  nnoremap <silent><Plug>(DBUI_SaveQuery) :call <sid>save_query()<CR>
endfunction

function! s:execute_query() abort
  if exists('b:db_ui_database')
    silent! exe '%DB '.b:db_ui_database.url
    return
  endif
  if filereadable(bufname())
    let db_name = get(matchlist(fnamemodify(bufname(), ':t'), '^\[\([^\]]*\)].*$'), 1)
    if has_key(g:db_ui_drawer.dbs, db_name)
      let b:db_ui_database = g:db_ui_drawer.dbs[db_name]
      silent! exe '%DB '.b:db_ui_database.url
      return
    endif
  endif

  silent! exe 'redraw!'
  let opts = ['Cannot detect which database to use. Please select one from list:']
  let opts += map(copy(keys(g:db_ui_drawer.dbs)), {i,v -> printf('%d) %s', i + 1, v)})
  call inputsave()
  let selection = inputlist(opts)
  call inputrestore()

  if empty(get(keys(g:db_ui_drawer.dbs), selection - 1))
    return db_ui#utils#echo_err('Wrong selection.')
  endif

  let db = keys(g:db_ui_drawer.dbs)[selection - 1]
  let b:db_ui_database = g:db_ui_drawer.dbs[db]
  silent! exe '%DB '.b:db_ui_database.url
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

function db_ui#query#open_buffer(buffer_name, ...)
  call s:focus_window()
  let table = get(a:, 1, '')
  let bufnr = bufnr(a:buffer_name)
  if bufnr > -1
    silent! exe 'b '.bufnr
    return
  endif

  silent! exe 'edit '.a:buffer_name
  let g:db_ui_drawer.buffers[bufnr(a:buffer_name)] = a:buffer_name
  setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
  augroup db_ui_query
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> call s:execute_query()
    autocmd BufDelete,BufWipeout <buffer> silent! call remove(g:db_ui_drawer.buffers, str2nr(expand('<abuf>')))
  augroup END

  if empty(table)
    return
  endif

  let content = substitute(g:db_ui_default_query, '{table}', table, 'g')
  silent 1,$delete _
  call setline(1, content)
endfunction

function! s:save_query() abort
  if empty(g:db_ui_save_location)
    return db_ui#utils#echo_err('You must provide valid save location.')
  endif

  if !isdirectory(g:db_ui_save_location)
    call mkdir(g:db_ui_save_location, 'p')
  endif

  call inputsave()
  let name = input('Save as: ')
  call inputrestore()

  let full_name = printf('%s/[%s]%s.sql', g:db_ui_save_location, b:db_ui_database.name, name)
  if filereadable(full_name)
    return db_ui#utils#echo_err('That file already exists. Please choose another name.')
  endif

  exe 'write '.full_name
endfunction
