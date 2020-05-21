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

function! s:drawer.open(...) abort
  if self.is_opened()
    silent! exe bufwinnr('dbui').'wincmd w'
    return
  endif
  let mods = get(a:, 1, '')
  if !empty(mods)
    silent! exe mods.' new dbui'
  else
    let win_pos = g:dbui_win_position ==? 'left' ? 'topleft' : 'botright'
    silent! exe 'vertical '.win_pos.' new dbui'
    silent! exe 'vertical '.win_pos.' resize '.g:dbui_winwidth
  endif
  setlocal filetype=dbui buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nomodifiable winfixwidth

  call self.render()
  nnoremap <silent><buffer> <Plug>(DBUI_SelectLine) :call <sid>method('toggle_line', 'edit')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_DeleteLine) :call <sid>method('delete_line')<CR>
  let query_win_pos = g:dbui_win_position ==? 'left' ? 'botright' : 'topleft'
  silent! exe "nnoremap <silent><buffer> <Plug>(DBUI_SelectLineVsplit) :call <sid>method('toggle_line', 'vertical ".query_win_pos." split')<CR>"
  nnoremap <silent><buffer> <Plug>(DBUI_Redraw) :call <sid>method('render', { 'dbs': 1, 'queries': 1 })<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_AddConnection) :call <sid>method('add_connection')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_ToggleDetails) :call <sid>method('toggle_details')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_RenameLine) :call <sid>method('rename_line')<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_Quit) :call <sid>method('quit')<CR>
  nnoremap <silent><buffer> ? :call <sid>method('toggle_help')<CR>
  augroup db_ui
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:method('render')
  augroup END
  silent! doautocmd User DBUIOpened
endfunction

function! s:drawer.is_opened() abort
  return bufwinnr('dbui') > -1
endfunction

function! s:drawer.toggle() abort
  if self.is_opened()
    return self.quit()
  endif
  return self.open()
endfunction

function! s:drawer.quit() abort
  if self.is_opened()
    silent! exe 'bd'.bufnr('dbui')
  endif
endfunction

function! s:method(method_name, ...) abort
  if a:0 > 0
    return s:drawer_instance[a:method_name](a:1)
  endif

  return s:drawer_instance[a:method_name]()
endfunction

function s:drawer.get_current_item() abort
  return self.content[line('.') - 1]
endfunction

function! s:drawer.rename_buffer(bufnr, db_key_name, is_saved_query) abort
  let buffer = bufname(a:bufnr)
  let current_win = winnr()
  let current_ft = &filetype

  if !filereadable(buffer)
    return db_ui#utils#echo_err('Only written queries can be renamed.')
  endif

  if empty(a:db_key_name)
    return db_ui#utils#echo_err('Buffer not attached to any database')
  endif

  let is_saved = a:is_saved_query || (a:bufnr > -1 && getbufvar(a:bufnr, 'dbui_is_tmp') ==? 0)
  let bufwin = bufwinnr(a:bufnr)
  let db = self.dbui.dbs[a:db_key_name]
  let db_slug = db_ui#utils#slug(db.name)

  if is_saved
    let old_name = fnamemodify(buffer, ':t')
  else
    let old_name = substitute(fnamemodify(buffer, ':e'), '^'.db_slug.'-', '', '')
  endif

  let new_name = db_ui#utils#input('Enter new name: ', old_name)

  if empty(new_name)
    return db_ui#utils#echo_err('Valid name must be provided.')
  endif

  if is_saved
    let new = printf('%s/%s', fnamemodify(buffer, ':p:h'), new_name)
  else
    let new = printf('%s.%s', fnamemodify(buffer, ':r'), db_slug.'-'.new_name)
  endif

  call rename(buffer, new)
  let new_bufnr = -1

  if bufwin > -1
    call self.get_query().open_buffer(db, new, 'edit', { 'is_tmp': !is_saved })
    let new_bufnr = bufnr('%')
  elseif a:bufnr > -1
    exe 'badd '.new
    let new_bufnr = bufnr(new)
    call add(db.buffers.list, new)
  endif

  if new_bufnr > - 1
    call setbufvar(new_bufnr, 'dbui_is_tmp', !is_saved)
    call setbufvar(new_bufnr, 'dbui_db_key_name', db.key_name)
    call setbufvar(new_bufnr, 'db', db.conn)
    call setbufvar(new_bufnr, 'dbui_db_table_name', getbufvar(buffer, 'dbui_db_table_name'))
    call setbufvar(new_bufnr, 'dbui_bind_params', getbufvar(buffer, 'dbui_bind_params'))
  endif

  silent! exe 'bw! '.buffer
  if winnr() !=? current_win
    wincmd p
  endif

  return self.render({ 'queries': 1 })
endfunction

function! s:drawer.rename_line() abort
  let item = self.get_current_item()
  if item.type !=? 'buffer'
    return
  endif

  return self.rename_buffer(bufnr(item.file_path), item.dbui_db_key_name, get(item, 'saved', 0))
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
  let opts = get(a:, 1, {})
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

  if get(opts, 'dbs', 0)
    let query_time = reltime()
    call db_ui#utils#echo_msg('Refreshing all databases...')
    call self.dbui.populate_dbs()
    call db_ui#utils#echo_msg('Refreshing all databases...Done after '.split(reltimestr(reltime(query_time)))[0].' sec.')
  endif

  let view = winsaveview()
  let self.content = []

  call self.render_help()

  for db in self.dbui.dbs_list
    if get(opts, 'queries', 0)
      call self.load_saved_queries(self.dbui.dbs[db.key_name])
    endif
    call self.add_db(self.dbui.dbs[db.key_name])
  endfor

  if empty(self.dbui.dbs_list)
    call self.add('" No connections', 'noaction', 'help', '', '', 0)
    call self.add('Add connection', 'call_method', 'add_connection', g:dbui_icons.add_connection, '', 0)
  endif

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
    call self.add('" r - Rename buffer/saved query', 'noaction', 'help', '', '', 0)
    call self.add('" q - Close drawer', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>W - (sql) Save currently opened query', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>E - (sql) Edit bind parameters in opened query', 'noaction', 'help', '', '', 0)
    call self.add('" <Leader>S - (sql) Execute query in visual or normal mode', 'noaction', 'help', '', '', 0)
    call self.add('" <C-]> - (.dbout) Go to entry from foreign key cell', 'noaction', 'help', '', '', 0)
    call self.add('" yic - (.dbout) Yank cell value', 'noaction', 'help', '', '', 0)
    call self.add('', 'noaction', 'help', '', '', 0)
  endif
endfunction

function! s:drawer.add(label, action, type, icon, dbui_db_key_name, level, ...)
  let opts = extend({'label': a:label, 'action': a:action, 'type': a:type, 'icon': a:icon, 'dbui_db_key_name': a:dbui_db_key_name, 'level': a:level }, get(a:, '1', {}))
  call add(self.content, opts)
endfunction

function! s:drawer.add_db(db) abort
  let db_name = a:db.name
  if !empty(a:db.conn_error)
    let db_name .= ' '.g:dbui_icons.connection_error
  elseif !empty(a:db.conn)
    let db_name .= ' '.g:dbui_icons.connection_ok
  endif
  if self.show_details
    let db_name .= ' ('.a:db.scheme.' - '.a:db.source.')'
  endif
  call self.add(db_name, 'toggle', 'db', self.get_toggle_icon('db', a:db), a:db.key_name, 0)
  if !a:db.expanded
    return a:db
  endif

  call self.add('New query', 'open', 'query', g:dbui_icons.new_query, a:db.key_name, 1)
  if !empty(a:db.buffers.list)
    call self.add('Buffers ('.len(a:db.buffers.list).')', 'toggle', 'buffers', self.get_toggle_icon('buffers', a:db.buffers), a:db.key_name, 1)
    if a:db.buffers.expanded
      for buf in a:db.buffers.list
        let buflabel = buf
        if buf =~? '^'.a:db.save_path || empty(getbufvar(buf, 'dbui_is_tmp'))
          let buflabel = fnamemodify(buf, ':t')
        else
          let buflabel = substitute(fnamemodify(buf, ':e'), '^'.db_ui#utils#slug(a:db.name).'-', '', '').' *'
        endif
        call self.add(buflabel, 'open', 'buffer', g:dbui_icons.buffers, a:db.key_name, 2, { 'file_path': buf })
      endfor
    endif
  endif
  call self.add('Saved queries ('.len(a:db.saved_queries.list).')', 'toggle', 'saved_queries', self.get_toggle_icon('saved_queries', a:db.saved_queries), a:db.key_name, 1)
  if a:db.saved_queries.expanded
    for saved_query in a:db.saved_queries.list
      call self.add(fnamemodify(saved_query, ':t'), 'open', 'buffer', g:dbui_icons.saved_query, a:db.key_name, 2, { 'file_path': saved_query, 'saved': 1 })
    endfor
  endif

  if a:db.schema_support
    call self.add('Schemas ('.len(a:db.schemas.items).')', 'toggle', 'schemas', self.get_toggle_icon('schemas', a:db.schemas), a:db.key_name, 1)
    if a:db.schemas.expanded
      for schema in a:db.schemas.list
        let schema_item = a:db.schemas.items[schema]
        let tables = schema_item.tables
        call self.add(schema.' ('.len(tables.items).')', 'toggle', 'schemas->items->'.schema, self.get_toggle_icon('schema', schema_item), a:db.key_name, 2)
        if schema_item.expanded
          call self.render_tables(tables, a:db,'schemas->items->'.schema.'->tables->items', 3, schema)
        endif
      endfor
    endif
  else
    call self.add('Tables ('.len(a:db.tables.items).')', 'toggle', 'tables', self.get_toggle_icon('tables', a:db.tables), a:db.key_name, 1)
    call self.render_tables(a:db.tables, a:db, 'tables->items', 2, '')
  endif
endfunction

function! s:drawer.render_tables(tables, db, path, level, schema) abort
  if !a:tables.expanded
    return
  endif
  for table in a:tables.list
    call self.add(table, 'toggle', a:path.'->'.table, self.get_toggle_icon('table', a:tables.items[table]), a:db.key_name, a:level)
    if a:tables.items[table].expanded
      for [helper_name, helper] in items(a:db.table_helpers)
        call self.add(helper_name, 'open', 'table', g:dbui_icons.tables, a:db.key_name, a:level + 1, {'table': table, 'content': helper, 'schema': a:schema })
      endfor
    endif
  endfor
endfunction

function! s:drawer.toggle_line(edit_action) abort
  let item = self.get_current_item()
  if item.action ==? 'noaction'
    return
  endif

  if item.action ==? 'call_method'
    return s:method(item.type)
  endif

  if item.action ==? 'open'
    return self.get_query().open(item, a:edit_action)
  endif

  let db = self.dbui.dbs[item.dbui_db_key_name]

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

function! s:drawer.get_query() abort
  if empty(self.query)
    let self.query = db_ui#query#new(self)
  endif
  return self.query
endfunction

function! s:drawer.delete_line() abort
  let item = self.get_current_item()

  if item.action ==? 'noaction'
    return
  endif

  if item.action ==? 'toggle' && item.type ==? 'db'
    let db = self.dbui.dbs[item.dbui_db_key_name]
    if db.source !=? 'file'
      return db_ui#utils#echo_err('Cannot delete this connection.')
    endif
    return self.delete_connection(db)
  endif

  if item.action !=? 'open' || item.type !=? 'buffer'
    return
  endif

  let db = self.dbui.dbs[item.dbui_db_key_name]

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
    let a:db.conn_error = ''
    call self.populate(a:db)
    if v:shell_error ==? 0
      call db_ui#utils#echo_msg('Connecting to db '.a:db.name.'...Connected after '.split(reltimestr(reltime(query_time)))[0].' sec.')
    endif
  catch /.*/
    let a:db.conn_error = v:exception
    return db_ui#utils#echo_err('Error connecting to db '.a:db.name.': '.v:exception)
  endtry
endfunction

function! s:drawer.populate(db) abort
  if a:db.schema_support
    return self.populate_schemas(a:db)
  endif
  return self.populate_tables(a:db)
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

  let tables = db#adapter#call(a:db.conn, 'tables', [a:db.conn], [])
  if v:shell_error !=? 0
    return db_ui#utils#echo_err(printf('Error loading tables. Reason: %s', get(tables, 0, 'Unknown')), 1)
  endif

  let a:db.tables.list = tables
  " Fix issue with sqlite tables listing as strings with spaces
  if a:db.scheme =~? '^sqlite' && len(a:db.tables.list) >=? 0
    let temp_table_list = []

    for table_index in a:db.tables.list
      let temp_table_list += map(split(copy(table_index)), 'trim(v:val)')
    endfor

    let a:db.tables.list = temp_table_list
  endif

  call self.populate_table_items(a:db.tables)
  return a:db
endfunction

function! s:drawer.populate_table_items(tables) abort
  for table in a:tables.list
    if !has_key(a:tables.items, table)
      let a:tables.items[table] = {'expanded': 0 }
    endif
  endfor
endfunction

function! s:drawer.populate_schemas(db) abort
  let a:db.schemas.list = []
  if empty(a:db.conn)
    return a:db
  endif
  let scheme = db_ui#schemas#get(a:db.scheme)
  let schemas = scheme.parse_results(db_ui#schemas#query(a:db, scheme.schemes_query), 1)
  let tables = scheme.parse_results(db_ui#schemas#query(a:db, scheme.schemes_tables_query), 2)
  let tables_by_schema = {}
  for [scheme_name, table] in tables
    if !has_key(tables_by_schema, scheme_name)
      let tables_by_schema[scheme_name] = []
    endif
    call add(tables_by_schema[scheme_name], table)
    call add(a:db.tables.list, table)
  endfor
  let a:db.schemas.list = schemas
  for schema in schemas
    if !has_key(a:db.schemas.items, schema)
      let a:db.schemas.items[schema] = {
            \ 'expanded': 0,
            \ 'tables': {
            \   'expanded': 1,
            \   'list': [],
            \   'items': {},
            \ },
            \ }

    endif
    let a:db.schemas.items[schema].tables.list = sort(get(tables_by_schema, schema, []))
    call self.populate_table_items(a:db.schemas.items[schema].tables)
  endfor
  return a:db
endfunction

function! s:drawer.get_toggle_icon(type, item) abort
  if a:item.expanded
    return g:dbui_icons.expanded[a:type]
  endif

  return g:dbui_icons.collapsed[a:type]
endfunction

function! s:drawer.get_nested(obj, val, ...) abort
  let default = get(a:, '1', 0)
  let items = split(a:val, '->')
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
