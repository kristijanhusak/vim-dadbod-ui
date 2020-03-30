let g:db_ui_drawer = {
      \ 'content': [],
      \ 'dbs': {},
      \ 'dbs_list': [],
      \ 'save_path': '',
      \ 'buffers': {},
      \ 'initialized': 0,
      \ 'show_details': 0,
      \ 'show_help': 0,
      \ }

if !empty(g:dbui_save_location)
  let g:db_ui_drawer.save_path = substitute(fnamemodify(g:dbui_save_location, ':p'), '\/$', '', '')
endif

function! db_ui#open() abort
  if !g:db_ui_drawer.initialized
    call s:populate_dbs()
  endif

  " TODO:
  " 1. Update readme
  " 2. Update error message
  " 3. Better handle of conflicts
  if empty(g:db_ui_drawer.dbs_list)
    return db_ui#utils#echo_err(
          \ printf('No databases found.
          \ Define the g:dbs variable, a $DBUI_URL env variable or
          \ use the prefix %s in your .env file.', g:dbui_dotenv_variable_prefix)
          \ )
  endif
  let g:db_ui_drawer.initialized = 1
  return db_ui#drawer#open()
endfunction

function! s:populate_dbs() abort
  let db_list = []
  call s:populate_from_dotenv(db_list)
  call s:populate_from_env(db_list)
  call s:populate_from_global_variable(db_list)
  call s:populate_from_connections_file(db_list)
  let g:db_ui_drawer.dbs_list = db_list

  for db in g:db_ui_drawer.dbs_list
    let key_name = printf('%s_%s', db.name, db.source)
    if !has_key(g:db_ui_drawer.dbs, key_name)
      let g:db_ui_drawer.dbs[key_name] = s:generate_new_db_entry(db)
    else
      let g:db_ui_drawer.dbs[key_name] = db_ui#drawer#populate_tables(g:db_ui_drawer.dbs[key_name])
    endif
  endfor
endfunction

function! s:generate_new_db_entry(db) abort
  let scheme = get(s:parse_url(a:db.url), 'scheme', '')
  let save_path = ''
  if !empty(g:db_ui_drawer.save_path)
    let save_path = printf('%s/%s', g:db_ui_drawer.save_path, a:db.name)
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

function! s:populate_from_global_variable(db_list) abort
  if !exists('g:dbs') || empty(g:dbs)
    return a:db_list
  endif

  if type(g:dbs) ==? type({})
    for [db_name, db_url] in items(g:dbs)
      call s:add_if_not_exists(a:db_list, db_name, db_url, 'g:dbs')
    endfor
    return a:db_list
  endif

  for db in g:dbs
    call s:add_if_not_exists(a:db_list, db.name, db.url, 'g:dbs')
  endfor

  return a:db_list
endfunction

function! s:populate_from_dotenv(db_list) abort
  let prefix = g:dbui_dotenv_variable_prefix
  for [name, url] in items(exists('*DotenvGet') ? DotenvGet() : {})
    if stridx(name, prefix) != -1
      let db_name = tolower(join(split(name, prefix)))
      call s:add_if_not_exists(a:db_list, db_name, url, 'dotenv')
    endif
  endfor
endfunction

function! s:env(var) abort
  return exists('*DotenvGet') ? DotenvGet(a:var) : eval('$'.a:var)
endfunction

function! s:populate_from_env(db_list) abort
  let env_url = s:env(g:dbui_env_variable_url)
  if empty(env_url)
    return a:db_list
  endif
  let env_name = s:env(g:dbui_env_variable_name)
  if empty(env_name)
    let env_name = get(split(env_url, '/'), -1, '')
  endif

  if empty(env_name)
    return db_ui#utils#echo_err(
          \ printf('Found %s variable for db url, but unable to parse the name. Please provide name via %s', g:db_ui_env_variable_url, g:db_ui_env_variable_name))
  endif

  call s:add_if_not_exists(a:db_list, env_name, env_url, 'env')
endfunction

function! s:parse_url(url) abort
  try
    return db#url#parse(a:url)
  catch /.*/
    call db_ui#utils#echo_err(v:exception)
    return {}
  endtry
endfunction

function! s:populate_from_connections_file(db_list) abort
  if empty(g:db_ui_drawer.save_path)
    return a:db_list
  endif

  let config_path = printf('%s/%s', g:db_ui_drawer.save_path, 'connections.json')

  if !filereadable(config_path)
    return a:db_list
  endif

  let file = json_decode(join(readfile(config_path), "\n"))

  for conn in file
    call s:add_if_not_exists(a:db_list, conn.name, conn.url, 'file')
  endfor

  return a:db_list
endfunction

function s:add_if_not_exists(db_list, name, url, source) abort
  let existing = get(filter(copy(a:db_list), 'v:val.name ==? a:name && v:val.source ==? a:source'), 0, {})
  if !empty(existing)
    return db_ui#utils#echo_warning(printf('Warning: Failed to add connection "%s" from source "%s" that already exists in source "%s"', a:name, a:source, existing.source))
  endif
  return add(a:db_list, {'name': a:name, 'url': a:url, 'source': a:source })
endfunction

function! db_ui#reset_state() abort
  let g:db_ui_drawer.content = []
  let g:db_ui_drawer.dbs = {}
  let g:db_ui_drawer.dbs_list = []
  let g:db_ui_drawer.buffers = {}
  let g:db_ui_drawer.initialized = 0
endfunction
