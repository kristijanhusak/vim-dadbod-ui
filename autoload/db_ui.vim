let g:db_ui_drawer = {
      \ 'content': [],
      \ 'dbs': {},
      \ 'dbs_list': [],
      \ 'save_path': '',
      \ 'buffers': {},
      \ 'initialized': 0
      \ }

function! db_ui#open() abort
  if !empty(g:db_ui_save_location)
    let g:db_ui_drawer.save_path = substitute(fnamemodify(g:db_ui_save_location, ':p'), '\/$', '', '')
  endif

  if !g:db_ui_drawer.initialized
    call s:populate_dbs()
  endif

  if empty(g:db_ui_drawer.dbs_list)
    return db_ui#utils#echo_err(
          \ 'No databases found. Define g:dbs variable or provide DBUI_URL env variable.'
          \ )
  endif
  let g:db_ui_drawer.initialized = 1
  return db_ui#drawer#open()
endfunction

function! s:populate_dbs() abort
  let db_list = []
  call s:populate_from_dotenv(db_list)
  call s:populate_from_global_variable(db_list)
  let g:db_ui_drawer.dbs_list = db_list

  for db in g:db_ui_drawer.dbs_list
    if !has_key(g:db_ui_drawer.dbs, db.name)
      let g:db_ui_drawer.dbs[db.name] = s:generate_new_db_entry(db)
    else
      let g:db_ui_drawer.dbs[db.name] = db_ui#drawer#populate_tables(g:db_ui_drawer.dbs[db.name])
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
        \ 'scheme': scheme,
        \ 'table_helpers': db_ui#table_helpers#get(scheme),
        \ 'expanded': 0,
        \ 'tables': {'expanded': 0 , 'items': {}, 'list': [] },
        \ 'saved_sql': { 'expanded': 0, 'list': [] },
        \ 'buffers': { 'expanded': 0, 'list': [] },
        \ 'save_path': save_path,
        \ 'name': a:db.name,
        \ }
endfunction

function! s:populate_from_global_variable(db_list) abort
  if !exists('g:dbs') || empty(g:dbs)
    return a:db_list
  endif

  if type(g:dbs) ==? type({})
    for [db_name, db_url] in items(g:dbs)
      call add(a:db_list, {'name': db_name, 'url': db_url })
    endfor
    return a:db_list
  endif

  for db in g:dbs
    call add(a:db_list, copy(db))
  endfor

  return a:db_list
endfunction

function! s:populate_from_dotenv(db_list) abort
  let env_url = s:env(g:db_ui_env_variable_url)
  if empty(env_url)
    return a:db_list
  endif
  let env_name = s:env(g:db_ui_env_variable_name)
  if empty(env_name)
    let env_name = get(split(env_url, '/'), -1, '')
  endif

  if empty(env_name)
    return db_ui#utils#echo_err(
          \ printf('Found %s variable for db url, but unable to parse the name. Please provide name via %s', g:db_ui_env_variable_url, g:db_ui_env_variable_name))
  endif

  call add(a:db_list, {'name': env_name, 'url': env_url })
endfunction

function! s:env(var) abort
  return exists('*DotenvGet') ? DotenvGet(a:var) : eval('$'.a:var)
endfunction

function! s:parse_url(url) abort
  try
    return db#url#parse(a:url)
  catch /.*/
    call db_ui#utils#echo_err(v:exception)
    return {}
  endtry
endfunction

function! db_ui#reset_state() abort
  let g:db_ui_drawer.content = []
  let g:db_ui_drawer.dbs = {}
  let g:db_ui_drawer.dbs_list = []
  let g:db_ui_drawer.save_path = ''
  let g:db_ui_drawer.buffers = {}
  let g:db_ui_drawer.initialized = 0
endfunction
