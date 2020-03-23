let s:drawer = { 'line': 1, 'content': [], 'dbs': {}, 'buffers': {} }


function! s:drawer.add(text, type, icon, ...) abort
  let extra_opts = a:0 > 0 ? a:1 : {}
  call add(self.content, extend({'text': a:text, 'icon': a:icon, 'type': a:type }, extra_opts))
endfunction

function! s:drawer.render() abort
  let view = winsaveview()
  let self.content = []
  if !empty(self.buffers)
    call self.add('Buffers:', 'noaction', '')
    for [bufnr, bufname] in items(self.buffers)
      call self.add(substitute(bufname, '^[^\[]*', '', ''), 'buffer', g:db_ui_icons.buffer, { 'bufname': bufname })
    endfor
    call self.add('', 'noaction', '')
  endif
  call self.add('Databases:', 'noaction', '')
  for [db_name, db] in items(self.dbs)
    let icon = db.expanded ? g:db_ui_icons.db_expanded : g:db_ui_icons.db_collapsed
    call self.add(db_name, 'db', icon)
    if db.expanded
      for table in db.tables
        call self.add(table, 'table', repeat(' ', shiftwidth()).g:db_ui_icons.table, {'db_name': db_name })
      endfor
    endif
  endfor

  let content = map(copy(self.content), 'v:val.icon.(!empty(v:val.icon) ? " " : "").v:val.text')

  setlocal modifiable
  silent 1,$delete _
  call setline(1, content)
  setlocal nomodifiable
  call winrestview(view)
endfunction

function! db_ui#drawer#open() abort
  let buffer = bufnr('dbui')
  if buffer > -1
    silent! exe 'b'.buffer
    return
  endif
  silent! exe 'vertical topleft new dbui'
  silent! exe 'vertical topleft resize '.g:db_ui_winwidth
  setlocal filetype=dbui buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nomodifiable winfixwidth

  let db_names = keys(g:dbs)
  for db_name in db_names
    if !has_key(s:drawer.dbs, db_name)
      let s:drawer.dbs[db_name] = {
            \ 'url': g:dbs[db_name],
            \ 'conn': '',
            \ 'expanded': 0,
            \ 'tables': [],
            \ 'name': db_name
            \ }
    endif
  endfor

  call s:drawer.render()
  nnoremap <silent><buffer> <Plug>(DBUI_SelectLine) :call <sid>toggle_line()<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_Redraw) :call <sid>render()<CR>
  augroup db_ui
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:drawer.render()
  augroup END
  silent! doautocmd User DBUIOpened
  return s:drawer
endfunction

function! s:render() abort
  return s:drawer.render()
endfunction

function! s:toggle_line() abort
  let item = s:drawer.content[line('.') - 1]
  if item.type ==? 'db'
    call s:toggle_db(item)
    return s:drawer.render()
  endif

  if item.type ==? 'table'
    return db_ui#query#open_table(s:drawer, item)
  endif

  if item.type ==? 'buffer'
    return db_ui#query#open_buffer(s:drawer, item.bufname, '')
  endif

  if item.type ==? 'noaction'
    return
  endif

  return db_ui#utils#echo_err('Unknown line.')
endfunction

function! s:toggle_db(item) abort
  let db = s:drawer.dbs[a:item.text]
  let db.expanded = !db.expanded

  if !empty(db.conn) || !db.expanded
    return db
  endif

  try
    let db.conn = db#connect(db.url)
    let db.tables = db#adapter#call(db.conn, 'tables', [db.conn], [])
  catch /.*/
    let db.expanded = 0
    return db_ui#utils#echo_err('Error connecting to db '.db.name.': '.v:exception)
  endtry
endfunction

function! db_ui#drawer#get_state() abort
  return s:drawer
endfunction
