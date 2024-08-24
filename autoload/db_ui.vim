let s:dbui_instance = {}
let s:dbui = {}

function! db_ui#open(mods) abort
  call s:init()
  return s:dbui_instance.drawer.open(a:mods)
endfunction

function! db_ui#toggle() abort
  call s:init()
  return s:dbui_instance.drawer.toggle()
endfunction

function! db_ui#close() abort
  call s:init()
  return s:dbui_instance.drawer.quit()
endfunction

function! db_ui#save_dbout(file) abort
  call s:init()
  return s:dbui_instance.save_dbout(a:file)
endfunction

function! db_ui#connections_list() abort
  call s:init()
  return map(copy(s:dbui_instance.dbs_list), {_,v-> {
        \ 'name': v.name,
        \ 'url': v.url,
        \ 'is_connected': !empty(s:dbui_instance.dbs[v.key_name].conn),
        \ 'source': v.source,
        \ }})
endfunction

function! db_ui#find_buffer() abort
  call s:init()
  if !len(s:dbui_instance.dbs_list)
    return db_ui#notifications#error('No database entries found in DBUI.')
  endif

  if !exists('b:dbui_db_key_name')
    let saved_query_db = s:dbui_instance.drawer.get_query().get_saved_query_db_name()
    let db = s:get_db(saved_query_db)
    if empty(db)
      return db_ui#notifications#error('No database entries selected or found.')
    endif
    call s:dbui_instance.connect(db)
    call db_ui#notifications#info('Assigned buffer to db '.db.name, {'delay': 10000 })
    let b:dbui_db_key_name = db.key_name
    let b:db = db.conn
  endif

  if !exists('b:dbui_db_key_name')
    return db_ui#notifications#error('Unable to find in DBUI. Not a valid dbui query buffer.')
  endif

  let db = b:dbui_db_key_name
  let bufname = bufname('%')

  call s:dbui_instance.drawer.get_query().setup_buffer(s:dbui_instance.dbs[db], { 'existing_buffer': 1 }, bufname, 0)
  if exists('*vim_dadbod_completion#fetch')
    call vim_dadbod_completion#fetch(bufnr(''))
  endif
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
  call s:dbui_instance.drawer.render({ 'db_key_name': db, 'queries': 1 })
  wincmd p
endfunction

function! db_ui#rename_buffer() abort
  call s:init()
  return s:dbui_instance.drawer.rename_buffer(bufname('%'), get(b:, 'dbui_db_key_name'), 0)
endfunction

function! db_ui#get_conn_info(db_key_name) abort
  if empty(s:dbui_instance)
    return {}
  endif
  if !has_key(s:dbui_instance.dbs, a:db_key_name)
    return {}
  endif
  let db = s:dbui_instance.dbs[a:db_key_name]
  call s:dbui_instance.connect(db)
  return {
        \ 'url': db.url,
        \ 'conn': db.conn,
        \ 'tables': db.tables.list,
        \ 'schemas': db.schemas.list,
        \ 'scheme': db.scheme,
        \ 'connected': !empty(db.conn),
        \ }
endfunction

function! db_ui#query(query) abort
  if empty(b:db)
    throw 'Cannot find valid connection for a buffer.'
  endif

  let parsed = db#url#parse(b:db)
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    throw 'Unsupported scheme '.parsed.scheme
  endif

  let result = db_ui#schemas#query(b:db, scheme, a:query)

  return scheme.parse_results(result, 0)
endfunction

function! db_ui#print_last_query_info() abort
  call s:init()
  let info = s:dbui_instance.drawer.get_query().get_last_query_info()
  if empty(info.last_query)
    return db_ui#notifications#info('No queries ran.')
  endif

  let content = ['Last query:'] + info.last_query
  let content += ['' + 'Time: '.info.last_query_time.' sec.']

  return db_ui#notifications#info(content, {'echo': 1})
endfunction

function! db_ui#statusline(...)
  let db_key_name = get(b:, 'dbui_db_key_name', '')
  let dbout = get(b:, 'db', '')
  if empty(s:dbui_instance) || (&filetype !=? 'dbout' && empty(db_key_name))
    return ''
  end
  if &filetype ==? 'dbout'
    let last_query_info = s:dbui_instance.drawer.get_query().get_last_query_info()
    let last_query_time = last_query_info.last_query_time
    if !empty(last_query_time)
      return 'Last query time: '.last_query_time.' sec.'
    endif
    return ''
  endif
  let opts = get(a:, 1, {})
  let prefix = get(opts, 'prefix', 'DBUI: ')
  let separator = get(opts, 'separator', ' -> ')
  let show = get(opts, 'show', ['db_name', 'schema', 'table'])
  let db_table = get(b:, 'dbui_table_name', '')
  let db_schema = get(b:, 'dbui_schema_name', '')
  let db = s:dbui_instance.dbs[db_key_name]
  let data = { 'db_name': db.name, 'schema': db_schema, 'table': db_table }
  let content = []
  for item in show
    let entry = get(data, item, '')
    if !empty(entry)
      call add(content, entry)
    endif
  endfor
  return prefix.join(content, separator)
endfunction

function! s:dbui.new() abort
  let instance = copy(self)
  let instance.dbs = {}
  let instance.dbs_list = []
  let instance.save_path = ''
  let instance.connections_path = ''
  let instance.tmp_location = ''
  let instance.drawer = {}
  let instance.old_buffers = []
  let instance.dbout_list = {}

  if !empty(g:db_ui_save_location)
    let instance.save_path = substitute(fnamemodify(g:db_ui_save_location, ':p'), '\/$', '', '')
    let instance.connections_path = printf('%s/%s', instance.save_path, 'connections.json')
  endif

  if !empty(g:db_ui_tmp_query_location)
    let tmp_loc = substitute(fnamemodify(g:db_ui_tmp_query_location, ':p'), '\/$', '', '')
    if !isdirectory(tmp_loc)
      call mkdir(tmp_loc, 'p')
    endif
    let instance.tmp_location = tmp_loc
    let instance.old_buffers = glob(tmp_loc.'/*', 1, 1)
  endif

  call instance.populate_dbs()
  let instance.drawer = db_ui#drawer#new(instance)
  return instance
endfunction

function! s:dbui.save_dbout(file) abort
  let db_input = ''
  let content = ''
  if has_key(self.dbout_list, a:file) && !empty(self.dbout_list[a:file])
    return
  endif
  let db_input = get(getbufvar(a:file, 'db', {}), 'input')
  if !empty(db_input) && filereadable(db_input)
    let content = get(readfile(db_input, 1), 0)
    if len(content) > 30
      let content = printf('%s...', content[0:30])
    endif
  endif
  let self.dbout_list[a:file] = content
  call self.drawer.render()
endfunction

function! s:dbui.populate_dbs() abort
  let self.dbs_list = []
  call self.populate_from_dotenv()
  call self.populate_from_env()
  call self.populate_from_global_variable()
  call self.populate_from_connections_file()

  for db in self.dbs_list
    let key_name = printf('%s_%s', db.name, db.source)
    if !has_key(self.dbs, key_name) || db.url !=? self.dbs[key_name].url
      let new_entry = self.generate_new_db_entry(db)
      if !empty(new_entry)
        let self.dbs[key_name] = new_entry
      endif
    else
      let self.dbs[key_name] = self.drawer.populate(self.dbs[key_name])
    endif
  endfor
endfunction

function! s:dbui.generate_new_db_entry(db) abort
  let parsed_url = self.parse_url(a:db.url)
  if empty(parsed_url)
    return parsed_url
  endif
  let db_name = substitute(get(parsed_url, 'path', ''), '^\/', '', '')
  let save_path = ''
  if !empty(self.save_path)
    let save_path = printf('%s/%s', self.save_path, a:db.name)
  endif
  let buffers = filter(copy(self.old_buffers), 'fnamemodify(v:val, ":e") =~? "^".a:db.name."-" || fnamemodify(v:val, ":t") =~? "^".a:db.name."-"')

  let db = {
        \ 'url': a:db.url,
        \ 'conn': '',
        \ 'conn_error': '',
        \ 'conn_tried': 0,
        \ 'source': a:db.source,
        \ 'scheme': '',
        \ 'table_helpers': {},
        \ 'expanded': 0,
        \ 'tables': {'expanded': 0 , 'items': {}, 'list': [] },
        \ 'schemas': {'expanded': 0, 'items': {}, 'list': [] },
        \ 'saved_queries': { 'expanded': 0, 'list': [] },
        \ 'buffers': { 'expanded': 0, 'list': buffers, 'tmp': [] },
        \ 'save_path': save_path,
        \ 'db_name': !empty(db_name) ? db_name : a:db.name,
        \ 'name': a:db.name,
        \ 'key_name': printf('%s_%s', a:db.name, a:db.source),
        \ 'schema_support': 0,
        \ 'quote': 0,
        \ 'default_scheme': '',
        \ 'filetype': ''
        \ }

  call self.populate_schema_info(db)
  return db
endfunction

function! s:dbui.resolve_url_global_variable(Value) abort
  if type(a:Value) ==? type('')
    return a:Value
  endif

  if type(a:Value) ==? type(function('tr'))
    return call(a:Value, [])
  endif

  " if type(a:Value) ==? type(v:t_func)
  " endif
  "
  " echom string(type(a:Value))
  " echom string(a:Value)
  "
  throw 'Invalid type global variable database url:'..type(a:Value)
endfunction

function! s:dbui.populate_from_global_variable() abort
  if exists('g:db') && !empty(g:db)
    let url = self.resolve_url_global_variable(g:db)
    let gdb_name = split(url, '/')[-1]
    call self.add_if_not_exists(gdb_name, url, 'g:dbs')
  endif

  if !exists('g:dbs') || empty(g:dbs)
    return self
  endif

  if type(g:dbs) ==? type({})
    for [db_name, Db_url] in items(g:dbs)
      call self.add_if_not_exists(db_name, self.resolve_url_global_variable(Db_url), 'g:dbs')
    endfor
    return self
  endif

  for db in g:dbs
    call self.add_if_not_exists(db.name, self.resolve_url_global_variable(db.url), 'g:dbs')
  endfor

  return self
endfunction

function! s:dbui.populate_from_dotenv() abort
  let prefix = g:db_ui_dotenv_variable_prefix
  let all_envs = {}
  if exists('*environ')
    let all_envs = environ()
  else
    for item in systemlist('env')
      let env = split(item, '=')
      if len(env) > 1
        let all_envs[env[0]] = join(env[1:], '')
      endif
    endfor
  endif
  let all_envs = extend(all_envs, exists('*DotenvGet') ? DotenvGet() : {})
  for [name, url] in items(all_envs)
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
  let env_url = self.env(g:db_ui_env_variable_url)
  if empty(env_url)
    return self
  endif
  let env_name = self.env(g:db_ui_env_variable_name)
  if empty(env_name)
    let env_name = get(split(env_url, '/'), -1, '')
  endif

  if empty(env_name)
    return db_ui#notifications#error(
          \ printf('Found %s variable for db url, but unable to parse the name. Please provide name via %s', g:db_ui_env_variable_url, g:db_ui_env_variable_name))
  endif

  call self.add_if_not_exists(env_name, env_url, 'env')
  return self
endfunction

function! s:dbui.parse_url(url) abort
  try
    return db#url#parse(a:url)
  catch /.*/
    call db_ui#notifications#error(v:exception)
    return {}
  endtry
endfunction

function! s:dbui.populate_from_connections_file() abort
  if empty(self.connections_path) || !filereadable(self.connections_path)
    return
  endif

  let file = db_ui#utils#readfile(self.connections_path)

  for conn in file
    call self.add_if_not_exists(conn.name, conn.url, 'file')
  endfor

  return self
endfunction

function! s:dbui.add_if_not_exists(name, url, source) abort
  let existing = get(filter(copy(self.dbs_list), 'v:val.name ==? a:name && v:val.source ==? a:source'), 0, {})
  if !empty(existing)
    return db_ui#notifications#warning(printf('Warning: Duplicate connection name "%s" in "%s" source. First one added has precedence.', a:name, a:source))
  endif
  return add(self.dbs_list, {
        \ 'name': a:name, 'url': db_ui#resolve(a:url), 'source': a:source, 'key_name': printf('%s_%s', a:name, a:source)
        \ })
endfunction

function! s:dbui.is_tmp_location_buffer(db, buf) abort
  if index(a:db.buffers.tmp, a:buf) > -1
    return 1
  endif
  return !empty(self.tmp_location) && a:buf =~? '^'.self.tmp_location
endfunction

function! s:dbui.connect(db) abort
  if !empty(a:db.conn)
    return a:db
  endif

  try
    let query_time = reltime()
    call db_ui#notifications#info('Connecting to db '.a:db.name.'...')
    let a:db.conn = db#connect(a:db.url)
    let a:db.conn_error = ''
    call self.populate_schema_info(a:db)
    call db_ui#notifications#info('Connected to db '.a:db.name.' after '.split(reltimestr(reltime(query_time)))[0].' sec.')
  catch /.*/
    let a:db.conn_error = v:exception
    let a:db.conn = ''
    call db_ui#notifications#error('Error connecting to db '.a:db.name.': '.v:exception, {'width': 80 })
  endtry

  redraw!
  let a:db.conn_tried = 1
  return a:db
endfunction

function! s:dbui.populate_schema_info(db) abort
  let url = !empty(a:db.conn) ? a:db.conn : a:db.url
  let parsed_url = self.parse_url(url)
  let scheme = get(parsed_url, 'scheme', '')
  let scheme_info = db_ui#schemas#get(scheme)
  let a:db.scheme = scheme
  let a:db.table_helpers = db_ui#table_helpers#get(scheme)
  let a:db.schema_support = db_ui#schemas#supports_schemes(scheme_info, parsed_url)
  let a:db.quote = get(scheme_info, 'quote', 0)
  let a:db.default_scheme = get(scheme_info, 'default_scheme', '')
  let a:db.filetype = get(scheme_info, 'filetype', db#adapter#call(url, 'input_extension', [], 'sql'))
  " Properly map mongodb js to javascript
  if a:db.filetype ==? 'js'
    let a:db.filetype = 'javascript'
  endif
endfunction

" Resolve only urls for DBs that are files
function db_ui#resolve(url) abort
  let parsed_url = db#url#parse(a:url)
  let resolve_schemes = ['sqlite', 'jq', 'duckdb', 'osquery']

  if index(resolve_schemes, get(parsed_url, 'scheme', '')) > -1
    return db#resolve(a:url)
  endif

  return a:url
endfunction

function! db_ui#reset_state() abort
  let s:dbui_instance = {}
endfunction

function! s:init() abort
  if empty(s:dbui_instance)
    let s:dbui_instance = s:dbui.new()
  endif

  return s:dbui_instance
endfunction

function! s:get_db(saved_query_db) abort
  if !len(s:dbui_instance.dbs_list)
    return {}
  endif

  if !empty(a:saved_query_db)
    let saved_db = get(filter(copy(s:dbui_instance.dbs_list), 'v:val.name ==? a:saved_query_db'), 0, {})
    if empty(saved_db)
      return {}
    endif
    return s:dbui_instance.dbs[saved_db.key_name]
  endif

  if len(s:dbui_instance.dbs_list) ==? 1
    return values(s:dbui_instance.dbs)[0]
  endif

  let options = map(copy(s:dbui_instance.dbs_list), '(v:key + 1).") ".v:val.name')
  let selection = db_ui#utils#inputlist(['Select db to assign this buffer to:'] + options)
  if selection < 1 || selection > len(options)
    call db_ui#notifications#error('Wrong selection.')
    return {}
  endif
  let selected_db = s:dbui_instance.dbs_list[selection - 1]
  let selected_db = s:dbui_instance.dbs[selected_db.key_name]
  return selected_db
endfunction
