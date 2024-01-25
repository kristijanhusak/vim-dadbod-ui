let s:connections_instance = {}
let s:connections = {}

function! db_ui#connections#new(drawer)
  let s:connections_instance = s:connections.new(a:drawer)
  return s:connections_instance
endfunction

function! db_ui#connections#add() abort
  if empty(s:connections_instance)
    let s:connections_instance = s:connections.new({})
  endif

  return s:connections_instance.add()
endfunction

function! s:connections.new(drawer) abort
  let instance = copy(self)
  let instance.drawer = a:drawer
  let s:connections_instance = instance

  return s:connections_instance
endfunction

function! s:connections.add() abort
  if empty(g:db_ui_save_location)
    return db_ui#notifications#error('Please set up valid save location via g:db_ui_save_location')
  endif

  return self.add_full_url()
endfunction

function! s:connections.delete(db) abort
  let confirm_delete = confirm(printf('Are you sure you want to delete connection %s?', a:db.name), "&Yes\n&No\n&Cancel")
  if confirm_delete !=? 1
    return
  endif

  let file = self.read()
  call filter(file, {i, conn -> !(conn.name ==? a:db.name && db_ui#resolve(conn.url) ==? db_ui#resolve(a:db.url) )})
  return self.write(file)
endfunction

function! s:connections.add_full_url() abort
  let url = ''

  try
    let url = db_ui#resolve(db_ui#utils#input('Enter connection url: ', url))
    call db#url#parse(url)
  catch /.*/
    return db_ui#notifications#error(v:exception)
  endtry

  try
    let name = self.enter_db_name(url)
  catch /.*/
    return db_ui#notifications#error(v:exception)
  endtry

  return self.save(name, url)
endfunction

function! s:connections.rename(db) abort
  if a:db.source !=? 'file'
    return db_ui#notifications#error('Cannot edit connections added via variables.')
  endif

  let connections = copy(self.read())
  let idx = 0
  let entry = {}
  for conn in connections
    if conn.name ==? a:db.name && db_ui#resolve(conn.url) ==? a:db.url
      let entry = conn
      break
    endif
    let idx += 1
  endfor

  let url = entry.url
  try
    let url = db_ui#resolve(db_ui#utils#input('Edit connection url for "'.entry.name.'": ', url))
    call db#url#parse(url)
  catch /.*/
    return db_ui#notifications#error(v:exception)
  endtry

  let name = ''

  try
    let name = db_ui#utils#input('Edit connection name: ', entry.name)
    if empty(trim(name))
      throw 'Please enter valid name.'
    endif
  catch /.*/
    return db_ui#notifications#error(v:exception)
  endtry

  call remove(connections, idx)
  let connections = insert(connections, {'name': name, 'url': url }, idx)
  return self.write(connections)
endfunction

function! s:connections.enter_db_name(url) abort
  let name = db_ui#utils#input('Enter name: ', split(a:url, '/')[-1])

  if empty(trim(name))
    throw 'Please enter valid name.'
  endif

  return name
endfunction

function! s:connections.get_file() abort
  let save_folder = substitute(fnamemodify(g:db_ui_save_location, ':p'), '\/$', '', '')
  return printf('%s/%s', save_folder, 'connections.json')
endfunction

function s:connections.save(name, url) abort
  let file = self.get_file()
  let dir = fnamemodify(file, ':p:h')

  if !isdirectory(dir)
    call mkdir(dir, 'p')
  endif

  if !filereadable(file)
    call writefile(['[]'], file)
  endif

  let file = self.read()
  let existing_connection = filter(copy(file), 'v:val.name ==? a:name')
  if !empty(existing_connection)
    call db_ui#notifications#error('Connection with that name already exists. Please enter different name.')
    return 0
  endif
  call add(file, {'name': a:name, 'url': a:url})
  return self.write(file)
endfunction

function! s:connections.read() abort
  return db_ui#utils#readfile(self.get_file())
endfunction

function! s:connections.write(file) abort
  call writefile([json_encode(a:file)], self.get_file())
  if !empty(self.drawer)
    call self.drawer.render({ 'dbs': 1 })
  endif
  return 1
endfunction
