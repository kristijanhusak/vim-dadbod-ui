let s:drawer_instance = {}
let s:drawer = {}

function db_ui#drawer#new(dbui)
  let s:drawer_instance = s:drawer.new(a:dbui)
  return s:drawer_instance
endfunction

function! s:drawer.new(dbui) abort
  let instance = copy(self)
  let instance.dbui = a:dbui
  let instance.show_details = 0
  let instance.show_help = 0
  let instance.content = []
  let instance.query = {}
  let instance.connections = {}

  return instance
endfunction

function! s:drawer.open() abort
  let dbui_winnr = bufwinnr('dbui')
  if dbui_winnr > -1
    silent! exe dbui_winnr.'wincmd w'
    return
  endif
  silent! exe 'vertical topleft new dbui'
  silent! exe 'vertical topleft resize '.g:dbui_winwidth
  setlocal filetype=dbui buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nomodifiable winfixwidth

  call self.render()
  nnoremap <silent><buffer> <Plug>(DBUI_SelectLine) :call <sid>method('toggle_line', 'edit')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_DeleteLine) :call <sid>method('delete_line')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_SelectLineVsplit) :call <sid>method('toggle_line', 'vertical botright split')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_Redraw) :call <sid>method('render', 1)<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_AddConnection) :call <sid>method('add_connection')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_ToggleDetails) :call <sid>method('toggle_details')<CR>
  nnoremap <silent><buffer> ? :call <sid>method('toggle_help')<CR>
  augroup db_ui
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:method('render')
  augroup END
  silent! doautocmd User DBUIOpened
endfunction

function! s:method(method_name, ...) abort
  if a:0 > 0
    return s:drawer_instance[a:method_name](a:1)
  endif

  return s:drawer_instance[a:method_name]()
endfunction

function! s:drawer.add_connection() abort
  if empty(self.connections)
    let self.connections = db_ui#connections#new(self)
  endif

  return self.connections.add()
endfunction

function! s:drawer.delete_connection(db) abort
  if empty(self.connections)
    let self.connections = db_ui#connections#new(self)
  endif

  return self.connections.delete(a:db)
endfunction

function! s:drawer.toggle_help() abort
  let self.show_help = !self.show_help
  return self.render()
endfunction

function! s:drawer.toggle_details() abort
  let self.show_details = !self.show_details
  return self.render()
endfunction

function! s:drawer.render(...) abort
  let restore_win = 0
  if &filetype !=? 'dbui'
    let winnr = bufwinnr('dbui')
    if winnr > -1
      let restore_win = 1
      exe winnr.'wincmd w'
    endif
  endif

  if &filetype !=? 'dbui'
    return
  endif

  let redraw = a:0 > 0

  if redraw
    let query_time = reltime()
    call db_ui#utils#echo_msg('Refreshing all databases...')
    call self.dbui.populate_dbs()
    call db_ui#utils#echo_msg('Refreshing all databases...Done after '.split(reltimestr(reltime(query_time)))[0].' sec.')
  endif

  let view = winsaveview()
  let self.content = []

  call self.render_help()

  for db in self.dbui.dbs_list
    call self.add_db(self.dbui.dbs[db.key_name])
  endfor

  let content = map(copy(self.content), 'repeat(" ", shiftwidth() * v:val.level).v:val.icon.(!empty(v:val.icon) ? " " : "").v:val.label')

  setlocal modifiable
  silent 1,$delete _
  call setline(1, content)
  setlocal nomodifiable
  call winrestview(view)

  if restore_win
    wincmd p
  endif
endfunction

function! s:drawer.render_help() abort
  if g:dbui_show_help
    call self.add('" Press ? for help', 'noaction', 'help', '', '', 0)
    call self.add('', 'noaction', 'help', '', '', 0)
  endif

  if self.show_help
    call self.add('" o - Open/Toggle selected item', 'noaction', 'help', '', '', 0)
    call self.add('" S - Open/Toggle selected item in vertical split', 'noaction', 'help', '', '', 0)
    call self.add('" d - Delete selected item', 'noaction', 'help', '', '', 0)
    call self.add('" R - Redraw', 'noaction', 'help', '', '', 0)
    call self.add('" A - Add connection', 'noaction', 'help', '', '', 0)
    call self.add('" H - Toggle database details', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>W - Save currently opened query', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>E - Edit bind parameters in opened query', 'noaction', 'help', '', '', 0)
    call self.add('', 'noaction', 'help', '', '', 0)
  endif
endfunction

function! s:drawer.add(label, action, type, icon, db_key_name, level, ...)
  let opts = extend({'label': a:label, 'action': a:action, 'type': a:type, 'icon': a:icon, 'db_key_name': a:db_key_name, 'level': a:level }, get(a:, '1', {}))
  call add(self.content, opts)
endfunction

function! s:drawer.add_db(db) abort
  let db_name = a:db.name
  if self.show_details
    let db_name .= ' ('.a:db.source.')'
  endif
  call self.add(db_name, 'toggle', 'db', self.get_icon(a:db), a:db.key_name, 0)
  if !a:db.expanded
    return a:db
  endif

  call self.add('New query', 'open', 'query', g:dbui_icons.new_query, a:db.key_name, 1)
  if !empty(a:db.buffers.list)
    call self.add('Buffers ('.len(a:db.buffers.list).')', 'toggle', 'buffers', self.get_icon(a:db.buffers), a:db.key_name, 1)
    if a:db.buffers.expanded
      for buf in a:db.buffers.list
        let buflabel = buf
        if buf =~? '^'.a:db.save_path
          let buflabel = fnamemodify(buf, ':t')
        else
          let buflabel = substitute(fnamemodify(buf, ':e'), '^'.a:db.key_name.'-', '', '').' *'
        endif
        call self.add(buflabel, 'open', 'buffer', g:dbui_icons.buffers, a:db.key_name, 2, { 'file_path': buf })
      endfor
    endif
  endif
  call self.add('Saved queries ('.len(a:db.saved_queries.list).')', 'toggle', 'saved_queries', self.get_icon(a:db.saved_queries), a:db.key_name, 1)
  if a:db.saved_queries.expanded
    for saved_query in a:db.saved_queries.list
      call self.add(fnamemodify(saved_query, ':t'), 'open', 'buffer', g:dbui_icons.saved_query, a:db.key_name, 2, { 'file_path': saved_query, 'saved': 1 })
    endfor
  endif

  call self.add('Tables ('.len(a:db.tables.items).')', 'toggle', 'tables', self.get_icon(a:db.tables), a:db.key_name, 1)
  if a:db.tables.expanded
    for table in a:db.tables.list
      call self.add(table, 'toggle', 'tables.items.'.table, self.get_icon(a:db.tables.items[table]), a:db.key_name, 2)
      if a:db.tables.items[table].expanded
        for [helper_name, helper] in items(a:db.table_helpers)
          call self.add(helper_name, 'open', 'table', g:dbui_icons.tables, a:db.key_name, 3, {'table': table, 'content': helper })
        endfor
      endif
    endfor
  endif
endfunction

function! s:drawer.toggle_line(edit_action) abort
  let item = self.content[line('.') - 1]
  if item.action ==? 'noaction'
    return
  endif

  if item.action ==? 'open'
    return self.open_query(item, a:edit_action)
  endif

  let db = self.dbui.dbs[item.db_key_name]

  let tree = db
  if item.type !=? 'db'
    let tree = self.get_nested(db, item.type)
  endif

  let tree.expanded = !tree.expanded

  if item.type ==? 'db'
    call self.toggle_db(db)
  endif

  return self.render()
endfunction

function! s:drawer.open_query(item, edit_action)
  if empty(self.query)
    let self.query = db_ui#query#new(self)
  endif
  return self.query.open(a:item, a:edit_action)
endfunction

function! s:drawer.delete_line() abort
  let item = self.content[line('.') - 1]

  if item.action ==? 'noaction'
    return
  endif

  if item.action ==? 'toggle' && item.type ==? 'db'
    let db = self.dbui.dbs[item.db_key_name]
    if db.source !=? 'file'
      return db_ui#utils#echo_err('Cannot delete this connection.')
    endif
    return self.delete_connection(db)
  endif

  if item.action !=? 'open' || item.type !=? 'buffer'
    return
  endif

  let db = self.dbui.dbs[item.db_key_name]

  if has_key(item, 'saved')
    let choice = confirm('Are you sure you want to delete this saved query?', "&Yes\n&No")
    if choice !=? 1
      return
    endif

    call delete(item.file_path)
    call remove(db.saved_queries.list, index(db.saved_queries.list, item.file_path))
    call db_ui#utils#echo_msg('Deleted.')
  endif

  silent! exe 'bw!'.bufnr(item.file_path)
  call self.render()
endfunction

function! s:drawer.toggle_db(db) abort
  if !a:db.expanded
    return a:db
  endif

  call self.load_saved_queries(a:db)

  if !empty(a:db.conn)
    return a:db
  endif

  try
    let query_time = reltime()
    call db_ui#utils#echo_msg('Connecting to db '.a:db.name.'...')
    let a:db.conn = db#connect(a:db.url)
    call self.populate_tables(a:db)
    call db_ui#utils#echo_msg('Connecting to db '.a:db.name.'...Connected after '.split(reltimestr(reltime(query_time)))[0].' sec.')
  catch /.*/
    return db_ui#utils#echo_err('Error connecting to db '.a:db.name.': '.v:exception)
  endtry
endfunction

function! s:drawer.load_saved_queries(db) abort
  if !empty(a:db.save_path)
    let a:db.saved_queries.list = split(glob(printf('%s/*', a:db.save_path)), "\n")
  endif
endfunction

function! s:drawer.populate_tables(db) abort
  let a:db.tables.list = []
  if empty(a:db.conn)
    return a:db
  endif

  let a:db.tables.list = db#adapter#call(a:db.conn, 'tables', [a:db.conn], [])
  " Fix issue with sqlite tables listing as single string with spaces
  if a:db.scheme =~? '^sqlite' && len(a:db.tables.list) ==? 1
    let a:db.tables.list = map(split(copy(a:db.tables.list[0])), 'trim(v:val)')
  endif

  for table in a:db.tables.list
    if !has_key(a:db.tables.items, table)
      let a:db.tables.items[table] = {'expanded': 0 }
    endif
  endfor
  return a:db
endfunction

function! s:drawer.get_icon(item) abort
  if a:item.expanded
    return g:dbui_icons.expanded
  endif

  return g:dbui_icons.collapsed
endfunction

function! s:drawer.get_nested(obj, val, ...) abort
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
