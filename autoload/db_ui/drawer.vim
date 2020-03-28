function! db_ui#drawer#open() abort
  let dbui_winnr = bufwinnr('dbui')
  if dbui_winnr > -1
    silent! exe dbui_winnr.'wincmd w'
    return
  endif
  silent! exe 'vertical topleft new dbui'
  silent! exe 'vertical topleft resize '.g:db_ui_winwidth
  setlocal filetype=dbui buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nomodifiable winfixwidth

  call g:db_ui_drawer.render()
  nnoremap <silent><buffer> <Plug>(DBUI_SelectLine) :call <sid>toggle_line('edit')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_DeleteLine) :call <sid>delete_line()<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_SelectLineVsplit) :call <sid>toggle_line('vertical botright split')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_Redraw) :call g:db_ui_drawer.render(1)<CR>
  augroup db_ui
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call g:db_ui_drawer.render()
  augroup END
  silent! doautocmd User DBUIOpened
endfunction

function! g:db_ui_drawer.render(...) abort
  let redraw = a:0 > 0

  if redraw
    let g:db_ui_drawer.initialized = 0
    call db_ui#open()
  endif

  let view = winsaveview()
  let self.content = []

  for db in self.dbs_list
    call self.add_db(db.name, self.dbs[db.name])
  endfor

  let content = map(copy(self.content), 'repeat(" ", shiftwidth() * v:val.level).v:val.icon.(!empty(v:val.icon) ? " " : "").v:val.label')

  setlocal modifiable
  silent 1,$delete _
  call setline(1, content)
  setlocal nomodifiable
  call winrestview(view)
endfunction

function! g:db_ui_drawer.add(label, action, type, icon, db_name, level, ...)
  let opts = extend({'label': a:label, 'action': a:action, 'type': a:type, 'icon': a:icon, 'db_name': a:db_name, 'level': a:level }, get(a:, '1', {}))
  call add(self.content, opts)
endfunction

function! g:db_ui_drawer.add_db(db_name, db) abort
  call self.add(a:db.name, 'toggle', 'db', s:get_icon(a:db), a:db_name, 0)
  if !a:db.expanded
    return a:db
  endif

  call self.add('New query', 'open', 'query', g:db_ui_icons.new_query, a:db_name, 1)
  if !empty(a:db.buffers.list)
    call self.add('Buffers ('.len(a:db.buffers.list).')', 'toggle', 'buffers', s:get_icon(a:db.buffers), a:db_name, 1)
    if a:db.buffers.expanded
      for buf in a:db.buffers.list
        let buflabel = buf
        if buf =~? '^'.a:db.save_path
          let buflabel = fnamemodify(buf, ':t')
        else
          let buflabel = substitute(fnamemodify(buf, ':e'), '^'.a:db_name.'-', '', '').' *'
        endif
        call self.add(buflabel, 'open', 'buffer', g:db_ui_icons.buffers, a:db_name, 2, { 'file_path': buf })
      endfor
    endif
  endif
  call self.add('Saved sql ('.len(a:db.saved_sql.list).')', 'toggle', 'saved_sql', s:get_icon(a:db.saved_sql), a:db_name, 1)
  if a:db.saved_sql.expanded
    for saved_sql in a:db.saved_sql.list
      call self.add(fnamemodify(saved_sql, ':t'), 'open', 'buffer', g:db_ui_icons.saved_sql, a:db_name, 2, { 'file_path': saved_sql, 'saved': 1 })
    endfor
  endif

  call self.add('Tables ('.len(a:db.tables.items).')', 'toggle', 'tables', s:get_icon(a:db.tables), a:db_name, 1)
  if a:db.tables.expanded
    for table in a:db.tables.list
      call self.add(table, 'toggle', 'tables.items.'.table, s:get_icon(a:db.tables.items[table]), a:db_name, 2)
      if a:db.tables.items[table].expanded
        for [helper_name, helper] in items(a:db.table_helpers)
          call self.add(helper_name, 'open', 'table', g:db_ui_icons.tables, a:db_name, 3, {'table': table, 'content': helper })
        endfor
      endif
    endfor
  endif
endfunction

function! s:toggle_line(edit_action) abort
  let item = g:db_ui_drawer.content[line('.') - 1]
  let db = g:db_ui_drawer.dbs[item.db_name]
  if item.action ==? 'toggle'
    if item.type ==? 'db'
      let db.expanded = !db.expanded
      call s:toggle_db(db)
    else
      let i = s:get_nested(db, item.type)
      let i.expanded = !i.expanded
    endif
    return g:db_ui_drawer.render()
  endif

  return db_ui#query#open(item, a:edit_action)
endfunction

function! s:delete_line() abort
  let item = g:db_ui_drawer.content[line('.') - 1]
  if item.action !=? 'open' || item.type !=? 'buffer'
    return
  endif

  let db = g:db_ui_drawer.dbs[item.db_name]

  if has_key(item, 'saved')
    let choice = confirm('Are you sure you want to delete this saved sql?', "&Yes\n&No")
    if choice ==? 1
      call delete(item.file_path)
      call remove(db.saved_sql.list, index(db.saved_sql.list, item.file_path))
      call db_ui#utils#echo_msg('Deleted.')
    endif
  endif

  silent! exe 'bw!'.bufnr(item.file_path)
  call g:db_ui_drawer.render()
endfunction

function! s:toggle_db(db) abort
  if !a:db.expanded
    return a:db
  endif

  if !empty(a:db.save_path)
    let a:db.saved_sql.list = split(glob(printf('%s/*', a:db.save_path)), "\n")
  endif

  if !empty(a:db.conn)
    return a:db
  endif

  try
    call db_ui#utils#echo_msg('Connecting to db '.a:db.name.'...')
    let a:db.conn = db#connect(a:db.url)
    call db_ui#utils#echo_msg('Connected.')
    call db_ui#drawer#populate_tables(a:db)
  catch /.*/
    return db_ui#utils#echo_err('Error connecting to db '.a:db.name.': '.v:exception)
  endtry
endfunction

function! db_ui#drawer#populate_tables(db) abort
  let a:db.tables.list = []
  if empty(a:db.conn)
    return a:db
  endif

  let a:db.tables.list = db#adapter#call(a:db.conn, 'tables', [a:db.conn], [])
  for table in a:db.tables.list
    if !has_key(a:db.tables.items, table)
      let a:db.tables.items[table] = {'expanded': 0 }
    endif
  endfor
  return a:db
endfunction

function! s:get_icon(item) abort
  if a:item.expanded
    return g:db_ui_icons.expanded
  endif

  return g:db_ui_icons.collapsed
endfunction

function! s:get_nested(obj, val, ...) abort
  let default = get(a:, '1', 0)
  let items = split(a:val, '\.')
  let result = copy(a:obj)

  for item in items
    if !has_key(result, item)
      let result = default
      break
    endif
    let result = result[item]
  endfor

  return result
endfunction
