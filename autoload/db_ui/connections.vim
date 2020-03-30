function! db_ui#connections#add() abort
  if empty(g:dbui_save_location)
    return db_ui#utils#echo_err('Please set up valid save location via g:db_ui_save_location')
  endif

  return s:add_full_url()
endfunction

function! db_ui#connections#delete(db) abort
  let confirm_delete = confirm(printf('Are you sure you want to delete connection %s?', a:db.name), "&Yes\n&No\n&Cancel")
  if confirm_delete !=? 1
    return
  endif

  let file = s:read()
  call filter(file, {i, conn -> !(conn.name ==? a:db.name && conn.url ==? a:db.url )})
  return s:write(file)
endfunction

function! s:add_full_url() abort
  let url = db_ui#utils#input('Enter connection url: ', '')

  try
    let valid_url = db#url#parse(url)
  catch /.*/
    return db_ui#utils#echo_err(v:exception)
  endtry

  let saved = 0

  while !saved
    let name = s:enter_db_name(url)
    if !empty(name)
      let saved = s:save(name, url)
    endif
  endwhile

  return saved
endfunction

function! s:enter_db_name(url) abort
  let name = db_ui#utils#input('Enter name: ', split(a:url, '/')[-1])

  if empty(name)
    call db_ui#utils#echo_err('Please enter valid name.')
    return 0
  endif

  return name
endfunction

function! s:get_file() abort
  let save_folder = substitute(fnamemodify(g:dbui_save_location, ':p'), '\/$', '', '')
  return printf('%s/%s', save_folder, 'connections.json')
endfunction

function s:save(name, url) abort
  let file = s:get_file()
  if !filereadable(file)
    call writefile(['[]'], file)
  endif

  let file = s:read()
  let existing_connection = filter(copy(file), 'v:val.name ==? a:name')
  if !empty(existing_connection)
    call db_ui#utils#echo_err('Connection with that name already exists. Please enter different name.')
    return 0
  endif
  call add(file, {'name': a:name, 'url': a:url})
  return s:write(file)
endfunction

function! s:read() abort
  return json_decode(join(readfile(s:get_file()), "\n"))
endfunction

function! s:write(file) abort
  call writefile([json_encode(a:file)], s:get_file())
  if exists('g:db_ui_drawer') && has_key(g:db_ui_drawer, 'render')
    call g:db_ui_drawer.render(1)
  endif
  return 1
endfunction
