let s:dbui_instance = {}
let s:dbui = {}

function! db_ui#open(mods) abort
  if empty(s:dbui_instance)
    let s:dbui_instance = s:dbui.new()
  endif

  return s:dbui_instance.drawer.open(a:mods)
endfunction

function! db_ui#toggle() abort
  if empty(s:dbui_instance)
    let s:dbui_instance = s:dbui.new()
  endif

  return s:dbui_instance.drawer.toggle()
endfunction

function! db_ui#find_buffer() abort
  if empty(s:dbui_instance)
    let s:dbui_instance = s:dbui.new()
  endif

  if !len(s:dbui_instance.dbs_list)
    return db_ui#utils#echo_err('No database entries found in DBUI.')
  endif

  if !exists('b:dbui_db_key_name')
    if len(s:dbui_instance.dbs_list) ==? 1
      let db = values(s:dbui_instance.dbs)[0]
      let b:dbui_db_key_name = db.key_name
      let b:db = db.conn
      call db_ui#utils#echo_msg('Assigned buffer to db '.db.name)
    else
      let options = map(copy(s:dbui_instance.dbs_list), '(v:key + 1).") ".v:val.name')
      let selection = db_ui#utils#inputlist(['Select db to assign this buffer to:'] + options)
      if selection < 1 || selection > len(options)
        return db_ui#utils#echo_err('Wrong selection.')
      endif
      let selected_db = s:dbui_instance.dbs_list[selection - 1]
      let selected_db = s:dbui_instance.dbs[selected_db.key_name]
      let b:dbui_db_key_name = selected_db.key_name
      let b:db = selected_db.conn
      call db_ui#utils#echo_msg('Assigned buffer to db '.selected_db.name)
    endif
  endif

  if !exists('b:dbui_db_key_name')
    return db_ui#utils#echo_err('Unable to find in DBUI. Not a valid dbui query buffer.')
  endif

  let db = b:dbui_db_key_name
  let bufname = bufname('%')

  let is_tmp = get(b: ,'dbui_is_tmp', 0)
  call s:dbui_instance.drawer.get_query().setup_buffer(s:dbui_instance.dbs[db], { 'is_tmp': is_tmp }, bufname, 0)
  let s:dbui_instance.dbs[db].expanded = 1
  let s:dbui_instance.dbs[db].buffers.expanded = 1
  call s:dbui_instance.drawer.open()
  let row = 1
  for line in s:dbui_instance.drawer.content
    if line.dbui_db_key_name ==? db && line.type ==? 'buffer' && line.file_path ==? bufname
      break
    endif
    let row += 1
  endfor
  call cursor(row, 0)
endfunction

function! db_ui#rename_buffer() abort
  if empty(s:dbui_instance)
    let s:dbui_instance = s:dbui.new()
  endif

  return s:dbui_instance.drawer.rename_buffer(bufnr('%'), get(b:, 'dbui_db_key_name'), 0)
endfunction

function! db_ui#get_conn_info(db_key_name) abort
  if empty(s:dbui_instance)
    return {}
  endif
  if !has_key(s:dbui_instance.dbs, a:db_key_name)
    return {}
  endif
  let db = s:dbui_instance.dbs[a:db_key_name]
  return {
        \ 'url': db.url,
        \ 'conn': db.conn,
        \ 'tables': db.tables.list,
        \ 'scheme': db.scheme,
        \ 'connected': !empty(db.conn),
        \ }
endfunction

function! s:dbui.new() abort
  let instance = copy(self)
  let instance.dbs = {}
  let instance.dbs_list = []
  let instance.save_path = ''
  let instance.drawer = {}

  if !empty(g:dbui_save_location)
    let instance.save_path = substitute(fnamemodify(g:dbui_save_location, ':p'), '\/$', '', '')
  endif

  call instance.populate_dbs()
  let instance.drawer = db_ui#drawer#new(instance)
  return instance
endfunction

function! s:dbui.populate_dbs() abort
  let self.dbs_list = []
  call self.populate_from_dotenv()
  call self.populate_from_env()
  call self.populate_from_global_variable()
  call self.populate_from_connections_file()

  for db in self.dbs_list
    let key_name = printf('%s_%s', db.name, db.source)
    if !has_key(self.dbs, key_name)
      let self.dbs[key_name] = self.generate_new_db_entry(db)
    else
      let self.dbs[key_name] = self.drawer.populate(self.dbs[key_name])
    endif
  endfor
endfunction

function! s:dbui.generate_new_db_entry(db) abort
  let scheme = get(self.parse_url(a:db.url), 'scheme', '')
  let save_path = ''
  if !empty(self.save_path)
    let save_path = printf('%s/%s', self.save_path, a:db.name)
  endif
  let scheme_info = db_ui#schemas#get(scheme)
  return {
        \ 'url': a:db.url,
        \ 'conn': '',
        \ 'conn_error': '',
        \ 'source': a:db.source,
        \ 'scheme': scheme,
        \ 'table_helpers': db_ui#table_helpers#get(scheme),
        \ 'expanded': 0,
        \ 'tables': {'expanded': 0 , 'items': {}, 'list': [] },
        \ 'schemas': {'expanded': 0, 'items': {}, 'list': [] },
        \ 'saved_queries': { 'expanded': 0, 'list': [] },
        \ 'buffers': { 'expanded': 0, 'list': [] },
        \ 'save_path': save_path,
        \ 'name': a:db.name,
        \ 'key_name': printf('%s_%s', a:db.name, a:db.source),
        \ 'schema_support': !empty(get(scheme_info, 'schemes_query', 0)),
        \ 'quote': get(scheme_info, 'quote', 0),
        \ 'default_scheme': get(scheme_info, 'default_scheme', '')
        \ }
endfunction

function! s:dbui.populate_from_global_variable() abort
  if exists('g:db') && !empty(g:db)
    let gdb_name = split(g:db, '/')[-1]
    call self.add_if_not_exists(gdb_name, g:db, 'g:dbs')
  endif

  if !exists('g:dbs') || empty(g:dbs)
    return self
  endif

  if type(g:dbs) ==? type({})
    for [db_name, db_url] in items(g:dbs)
      call self.add_if_not_exists(db_name, db_url, 'g:dbs')
    endfor
    return self
  endif

  for db in g:dbs
    call self.add_if_not_exists(db.name, db.url, 'g:dbs')
  endfor

  return self
endfunction

function! s:dbui.populate_from_dotenv() abort
  let prefix = g:dbui_dotenv_variable_prefix
  for [name, url] in items(exists('*DotenvGet') ? DotenvGet() : {})
    if stridx(name, prefix) != -1
      let db_name = tolower(join(split(name, prefix)))
      call self.add_if_not_exists(db_name, url, 'dotenv')
    endif
  endfor
endfunction

function! s:dbui.env(var) abort
  return exists('*DotenvGet') ? DotenvGet(a:var) : eval('$'.a:var)
endfunction

function! s:dbui.populate_from_env() abort
  let env_url = self.env(g:dbui_env_variable_url)
  if empty(env_url)
    return self
  endif
  let env_name = self.env(g:dbui_env_variable_name)
  if empty(env_name)
    let env_name = get(split(env_url, '/'), -1, '')
  endif

  if empty(env_name)
    return db_ui#utils#echo_err(
          \ printf('Found %s variable for db url, but unable to parse the name. Please provide name via %s', g:db_ui_env_variable_url, g:db_ui_env_variable_name))
  endif

  call self.add_if_not_exists(env_name, env_url, 'env')
  return self
endfunction

function! s:dbui.parse_url(url) abort
  try
    return db#url#parse(a:url)
  catch /.*/
    call db_ui#utils#echo_err(v:exception)
    return {}
  endtry
endfunction

function! s:dbui.populate_from_connections_file() abort
  if empty(self.save_path)
    return self
  endif

  let config_path = printf('%s/%s', self.save_path, 'connections.json')

  if !filereadable(config_path)
    return self
  endif

  let file = db_ui#utils#readfile(config_path)

  for conn in file
    call self.add_if_not_exists(conn.name, conn.url, 'file')
  endfor

  return self
endfunction

function! s:dbui.add_if_not_exists(name, url, source) abort
  let existing = get(filter(copy(self.dbs_list), 'v:val.name ==? a:name && v:val.source ==? a:source'), 0, {})
  if !empty(existing)
    return db_ui#utils#echo_warning(printf('Warning: Duplicate connection name "%s" in "%s" source. First one added has precedence.', a:name, a:source))
  endif
  return add(self.dbs_list, {
        \ 'name': a:name, 'url': a:url, 'source': a:source, 'key_name': printf('%s_%s', a:name, a:source)
        \ })
endfunction

function! db_ui#reset_state() abort
  let s:dbui_instance = {}
endfunction
