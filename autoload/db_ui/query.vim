let s:query_instance = {}
let s:query = {}

function! db_ui#query#new(drawer) abort
  let s:query_instance = s:query.new(a:drawer)
  return s:query_instance
endfunction

function! s:query.new(drawer) abort
  let instance = copy(self)
  let instance.drawer = a:drawer
  let instance.buffer_counter = {}
  return instance
endfunction

function! s:query.open(item, edit_action) abort
  let db = self.drawer.dbui.dbs[a:item.db_key_name]
  if a:item.type ==? 'buffer'
    return self.open_buffer(db, a:item.file_path, a:edit_action)
  endif
  let suffix = 'query'
  let table = ''
  if a:item.type !=? 'query'
    let suffix = a:item.table.'-'.a:item.label
    let table = a:item.table
  endif

  let buffer_name = printf('%s.%s', tempname(), self.generate_buffer_basename(db.name, suffix))
  call self.open_buffer(db, buffer_name, a:edit_action, table, get(a:item, 'content'))
  nnoremap <silent><Plug>(DBUI_SaveQuery) :call <sid>method('save_query')<CR>
endfunction

function! s:method(name) abort
  return s:query[a:name]()
endfunction

function! s:query.generate_buffer_basename(db_name, suffix) abort
  let buffer_basename = substitute(printf('%s-%s', a:db_name, a:suffix), '[^A-Za-z0-9_\-]', '', 'g')
  if !has_key(self.buffer_counter, buffer_basename)
    let self.buffer_counter[buffer_basename] = 1
    return buffer_basename
  endif

  let new_name = buffer_basename.'-'.self.buffer_counter[buffer_basename]
  let self.buffer_counter[buffer_basename] += 1
  return new_name
endfunction

function! s:query.focus_window() abort
  if winnr('$') ==? 1
    vertical new
    return
  endif

  let found = 0
  for win in range(1, winnr('$'))
    let buf = winbufnr(win)
    if !empty(getbufvar(buf, 'db_ui_database'))
      let found = 1
      exe win.'wincmd w'
      break
    endif
  endfor

  if !found
    2wincmd w
  endif
endfunction

function s:query.open_buffer(db, buffer_name, edit_action, ...)
  let table = get(a:, 1, '')
  let default_content = get(a:, 2, g:dbui_default_query)
  let was_single_win = winnr('$') ==? 1
  if a:edit_action ==? 'edit'
    call self.focus_window()
    let bufnr = bufnr(a:buffer_name)
    if bufnr > -1
      call self.focus_window()
      silent! exe 'b '.bufnr
      setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
      call self.resize_if_single(was_single_win)
      return
    endif
  endif

  silent! exe a:edit_action.' '.a:buffer_name
  call self.resize_if_single(was_single_win)
  let b:db_key_name = a:db.key_name
  let b:db_ui_database = {'name': a:db.name, 'key_name': a:db.key_name, 'url': a:db.url, 'save_path': a:db.save_path }
  let db_buffers = self.drawer.dbui.dbs[a:db.key_name].buffers

  if index(db_buffers.list, a:buffer_name) ==? -1
    if empty(db_buffers.list)
      let db_buffers.expanded = 1
    endif
    call add(db_buffers.list, a:buffer_name)
  endif
  setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
  augroup db_ui_query
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> nested call s:method('execute_query')
    autocmd BufDelete,BufWipeout <buffer> silent! call s:method('remove_buffer', str2nr(expand('<abuf>')))
  augroup END

  if empty(table)
    return
  endif

  let content = substitute(default_content, '{table}', table, 'g')
  let content = substitute(content, '{dbname}', a:db.name, 'g')
  silent 1,$delete _
  call setline(1, split(content, "\n"))
  if g:dbui_auto_execute_table_helpers
    write
  endif
endfunction

function! s:method(name, ...) abort
  if a:0 > 0
    return s:query_instance[a:name](a:1)
  endif

  return s:query_instance[a:name]()
endfunction

function! s:query.resize_if_single(is_single_win) abort
  if a:is_single_win
    exe bufwinnr('dbui').'wincmd w'
    exe 'vertical resize '.g:dbui_winwidth
    wincmd p
  endif
endfunction

function! s:query.remove_buffer(bufnr)
  let db_key_name = getbufvar(a:bufnr, 'db_key_name')
  let list = self.drawer.dbui.dbs[db_key_name].buffers.list
  return filter(list, 'v:val !=? bufname(a:bufnr)')
endfunction

function! s:query.execute_query() abort
  call db_ui#utils#echo_msg('Executing query...')
  let db = self.drawer.dbui.dbs[b:db_key_name]
  silent! exe '%DB '.db.url
  call db_ui#utils#echo_msg('Executing query...Done.')
endfunction

function! s:query.save_query() abort
  let db = self.drawer.dbui.dbs[b:db_key_name]
  if empty(db.save_path)
    throw 'Save location is empty. Please provide valid directory to g:db_ui_save_location'
  endif

  if !isdirectory(db.save_path)
    call mkdir(db.save_path, 'p')
  endif

  let name = db_ui#utils#input('Save as: ', '')

  let full_name = printf('%s/%s', db.save_path, name)
  if filereadable(full_name)
    throw 'That file already exists. Please choose another name.'
  endif

  exe 'write '.full_name
  call self.drawer.load_saved_sql(db)
endfunction
