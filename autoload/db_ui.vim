let s:dbs = {}
let s:buffers = {}
let s:temp_tree = []
let s:temp_line = 1
let s:tree = []

function! s:open_db_ui() abort
  let buffer = bufnr('__dbui__')
  if buffer > -1
    silent! exe 'b'.buffer
    return
  endif
  silent! exe 'vertical topleft new __dbui__'
  silent! exe 'vertical topleft resize 40'
  setlocal filetype=__dbui__ buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nomodifiable winfixwidth

  let db_names = keys(g:dbs)
  for db_name in db_names
    if !has_key(s:dbs, db_name)
      let s:dbs[db_name] = {
            \ 'url': g:dbs[db_name], 'conn': '', 'expanded': 0, 'tables': [], 'name': db_name
            \ }
    endif
  endfor

  call s:render()
  nnoremap <buffer> o :call <sid>toggle_line()<CR>
  nnoremap <buffer> R :call <sid>render()<CR>
endfunction

function s:open_existing_buffer(buffer_name)
  for win in range(1, winnr('$'))
    let buf = winbufnr(win)
    if !empty(getbufvar(buf, 'db_ui_table'))
      exe win.'wincmd w'
      exe 'drop '.a:buffer_name
      break
    endif
  endfor
endfunction

function! s:open_db_ui_query(db, table) abort
  let buffer_name = printf('db_ui_%s_%s', a:db.name, a:table)
  if winnr('$') ==? 1 && bufnr(buffer_name) <= -1
    silent! exe 'vertical new '.buffer_name
  else
    call s:open_existing_buffer(buffer_name)
  endif

  if bufnr(buffer_name) <= -1
    silent! exe 'vertical new '.buffer_name
  endif
  let s:buffers[buffer_name] = {'bufnr': bufnr(buffer_name) }

  setlocal filetype=sql buftype=nofile bufhidden=unload nobuflisted nolist noswapfile nowrap cursorline nospell modifiable
  silent 1,$delete _
  call setline(1, printf('select * from "%s" LIMIT 200;', a:table))
  let b:db_ui_table = a:table
  let b:db_ui = a:db
  nnoremap <buffer><Leader>e :call <sid>execute_query()<CR>
endfunction

function! s:execute_query() abort
  let s:buffers[bufname()] = getline(1, '$')
  silent! exe '%DB '.b:db_ui.url
endfunction

function! s:toggle_line() abort
  let item = s:tree[line('.') - 1]
  if item.type ==? 'db'
    call s:toggle_db(item)
    return s:render()
  endif

  if item.type ==? 'table'
    return s:toggle_table(item)
  endif

  if item.type ==? 'buffer'
    call s:open_existing_buffer(item.text)
  endif

  if item.type ==? 'noaction'
    return
  endif

  throw 'Unknown line.'
endfunction

function! s:toggle_db(item) abort
  let db = s:dbs[a:item.text]

  if db.expanded
    let db.expanded = 0
    return db
  endif

  let db.expanded = 1
  if empty(db.conn)
    let db.conn = db#connect(db.url)
    let db.tables = db#adapter#call(db.conn, 'tables', [db.conn], [])
  endif
endfunction

function! s:toggle_table(item) abort
  let db = s:dbs[a:item.db_name]

  if empty(db)
    throw 'DB for selected table not found.'
  endif
  call s:open_db_ui_query(db, a:item.text)
endfunction

function s:add_to_tree(text, type, icon, ...)
  let extra_opts = a:0 > 0 ? a:1 : {}
  call add(s:temp_tree, extend({'line': s:temp_line, 'text': a:text, 'icon': a:icon, 'type': a:type }, extra_opts))
  let s:temp_line += 1
endfunction

function s:render() abort
  let s:temp_tree = []
  let s:temp_line = 1
  let current_line = line('.')
  if !empty(s:buffers)
    call s:add_to_tree('Buffers:', 'noaction', '')
    for buf in keys(s:buffers)
      call s:add_to_tree(buf, 'buffer', ' -')
    endfor
    call s:add_to_tree('', 'noaction', '')
  endif
  for [db_name, db] in items(s:dbs)
    call s:add_to_tree(db_name, 'db', '*')
    if db.expanded
      for table in db.tables
        call s:add_to_tree(table, 'table', ' >', {'db_name': db_name })
      endfor
    endif
  endfor

  let s:tree = s:temp_tree
  let content = map(copy(s:tree), 'v:val.icon." ".v:val.text')

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

  return s:open_db_ui()
endfunction
