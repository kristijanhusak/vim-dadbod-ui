let s:state = {
      \ 'current_db': '',
      \ 'current_table': '',
      \ 'query_buffer': -1,
      \ 'dbs': {}
      \ }
let s:db_ui_bufname = '__dbui__'
let s:db_ui_query_bufname = '__dbuiquery__'

function! s:open_db_ui() abort
  let buffer = bufnr(s:db_ui_bufname)
  if buffer > -1
    silent! exe 'b'.buffer
    return
  endif
  silent! exe 'vertical topleft new '.s:db_ui_bufname
  silent! exe 'vertical topleft resize 40'
  setlocal filetype=__dbui__ buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nomodifiable winfixwidth

  let db_names = keys(g:dbs)
  for db_name in db_names
    if !has_key(s:state.dbs, db_name)
      let s:state.dbs[db_name] = {
            \ 'url': g:dbs[db_name], 'conn': '', 'expanded': 0, 'tables': []
            \ }
    endif
  endfor

  call s:render()
  nnoremap <buffer> o :call <sid>toggle_line()<CR>
endfunction

function! s:open_db_ui_query(db, table) abort
  if s:state.query_buffer > -1
    let win = bufwinnr(s:state.query_buffer)
    if win > -1
      silent! exe win.'wincmd w'
    endif

    if &filetype !=? '__dbui__'
      silent! exe 'b'.s:state.query_buffer
    endif
  else
    silent! exe 'vertical new '.tempname()
    let s:state.query_buffer = bufnr()
    setlocal filetype=sql buftype= bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell modifiable
  endif

  if get(b:, 'db_url') ==? a:db.url && s:state.current_table ==? a:table
    return
  endif

  silent 1,$delete _
  call setline(1, printf('select * from "%s" LIMIT 200;', a:table))
  let s:state.current_table = a:table
  let b:db_url = a:db.url
  augroup db_ui_query
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> exe '%DB '.b:db_url
  augroup END
endfunction

function! s:toggle_line() abort
  let line = getline('.')
  if has_key(s:state.dbs, line)
    call s:toggle_db(s:state.dbs[line])
    return s:render()
  endif

  if line =~? '^\s\s'
    call s:toggle_table(trim(line))
  endif
endfunction

function! s:toggle_db(db) abort
  if a:db.expanded
    let a:db.expanded = 0
    return a:db
  endif

  let a:db.expanded = 1
  if empty(a:db.conn)
    let a:db.conn = db#connect(a:db.url)
    let a:db.tables = db#adapter#call(a:db.conn, 'tables', [a:db.conn], [])
  endif
endfunction

function! s:toggle_table(table) abort
  let db = ''
  let line = line('.')
  while line > 0
    let l = getline(line)
    if has_key(s:state.dbs, l)
      let db = s:state.dbs[l]
      break
    endif
    let line -= 1
  endwhile

  if empty(db)
    throw 'DB for selected table not found.'
  endif
  call s:open_db_ui_query(db, a:table)
endfunction

function! db_ui#get_state() abort
  return s:state
endfunction

function s:render() abort
  let current_line = line('.')
  let content = []
  for [db_name, db] in items(s:state.dbs)
    call add(content, db_name)
    if db.expanded
      let content += map(copy(db.tables), '"  ".v:val')
    endif
  endfor

  setlocal modifiable
  silent 1,$delete _
  call setline(1, content)
  setlocal nomodifiable
  call cursor(current_line, 0)
endfunction

function! db_ui#open() abort
  if empty(g:dbs)
    throw 'g:dbs is not defined.'
  endif

  let buffer = bufnr(s:db_ui_bufname)
  if buffer <= -1
    call s:open_db_ui()
  else
    silent! exe 'b'.buffer
  endif
endfunction
