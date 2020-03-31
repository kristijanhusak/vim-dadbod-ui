let s:dbui_instance = {}
let s:dbui = {}

function! db_ui#open() abort
  if !empty(s:dbui_instance)
    return s:dbui_instance.open()
  endif

  let s:dbui_instance = s:dbui.new()

  if !empty(s:dbui_instance)
    return s:dbui_instance.open()
  endif
endfunction

function! db_ui#get_instance() abort
  return s:dbui_instance
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
  if empty(instance.dbs_list)
    call db_ui#utils#echo_err(printf('No databases found.
          \ use :DBUIAddConnection command to add a new connection
          \ or define the g:dbs variable, a $DBUI_URL env variable or
          \ use the prefix %s in your .env file.', g:dbui_dotenv_variable_prefix
          \ ))
    return {}
  endif
  let instance.drawer = db_ui#drawer#new(instance)
  return instance
endfunction

function! s:dbui.open() abort
  if !empty(self.drawer)
    return self.drawer.open()
  endif
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
      let self.dbs[key_name] = self.drawer.populate_tables(self.dbs[key_name])
    endif
  endfor
endfunction

function! s:dbui.generate_new_db_entry(db) abort
  let scheme = get(self.parse_url(a:db.url), 'scheme', '')
  let save_path = ''
  if !empty(self.save_path)
    let save_path = printf('%s/%s', self.save_path, a:db.name)
  endif
  return {
        \ 'url': a:db.url,
        \ 'conn': '',
        \ 'source': a:db.source,
        \ 'scheme': scheme,
        \ 'table_helpers': db_ui#table_helpers#get(scheme),
        \ 'expanded': 0,
        \ 'tables': {'expanded': 0 , 'items': {}, 'list': [] },
        \ 'saved_sql': { 'expanded': 0, 'list': [] },
        \ 'buffers': { 'expanded': 0, 'list': [] },
        \ 'save_path': save_path,
        \ 'name': a:db.name,
        \ 'key_name': printf('%s_%s', a:db.name, a:db.source),
        \ }
endfunction

function! s:dbui.populate_from_global_variable() abort
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

  let file = json_decode(join(readfile(config_path), "\n"))

  for conn in file
    call self.add_if_not_exists(conn.name, conn.url, 'file')
  endfor

  return self
endfunction

function s:dbui.add_if_not_exists(name, url, source) abort
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
