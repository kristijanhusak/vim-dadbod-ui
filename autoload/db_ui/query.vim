let s:buffer_counter = {}

function! db_ui#query#open(item, edit_action) abort
  let db = g:db_ui_drawer.dbs[a:item.db_name]
  if a:item.type ==? 'buffer'
    return s:open_buffer(db, a:item.file_path, a:edit_action)
  endif
  let suffix = 'query'
  let table = ''
  if a:item.type !=? 'query'
    let suffix = a:item.table.'-'.a:item.label
    let table = a:item.table
  endif

  let buffer_name = printf('%s.%s', tempname(), s:generate_buffer_basename(db.name, suffix))
  call s:open_buffer(db, buffer_name, a:edit_action, table, get(a:item, 'content'))
  nnoremap <silent><Plug>(DBUI_SaveQuery) :call <sid>save_query()<CR>
endfunction

function! s:generate_buffer_basename(db_name, suffix) abort
  let buffer_basename = substitute(printf('%s-%s', a:db_name, a:suffix), '[^A-Za-z0-9_\-]', '', 'g')
  if !has_key(s:buffer_counter, buffer_basename)
    let s:buffer_counter[buffer_basename] = 1
    return buffer_basename
  endif

  let new_name = buffer_basename.'-'.s:buffer_counter[buffer_basename]
  let s:buffer_counter[buffer_basename] += 1
  return new_name
endfunction

function! s:focus_window() abort
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

function s:open_buffer(db, buffer_name, edit_action, ...)
  let table = get(a:, 1, '')
  let default_content = get(a:, 2, g:db_ui_default_query)
  let was_single_win = winnr('$') ==? 1
  if a:edit_action ==? 'edit'
    call s:focus_window()
    let bufnr = bufnr(a:buffer_name)
    if bufnr > -1
      call s:focus_window()
      silent! exe 'b '.bufnr
      setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
      call s:resize_if_single(was_single_win)
      return
    endif
  endif

  silent! exe a:edit_action.' '.a:buffer_name
  call s:resize_if_single(was_single_win)
  let b:db_ui_database = {'name': a:db.name, 'url': a:db.url, 'save_path': a:db.save_path }
  let db_buffers = g:db_ui_drawer.dbs[a:db.name].buffers

  if index(db_buffers.list, a:buffer_name) ==? -1
    if empty(db_buffers.list)
      let db_buffers.expanded = 1
    endif
    call add(db_buffers.list, a:buffer_name)
  endif
  setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
  augroup db_ui_query
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> ++nested call s:execute_query()
    autocmd BufDelete,BufWipeout <buffer> silent! call s:remove_buffer(str2nr(expand('<abuf>')))
  augroup END

  if empty(table)
    return
  endif

  let content = substitute(default_content, '{table}', table, 'g')
  let content = substitute(content, '{dbname}', a:db.name, 'g')
  silent 1,$delete _
  call setline(1, split(content, "\n"))
  if g:db_ui_auto_execute_table_helpers
    write
  endif
endfunction

function! s:resize_if_single(is_single_win) abort
  if a:is_single_win
    exe bufwinnr('dbui').'wincmd w'
    exe 'vertical resize '.g:db_ui_winwidth
    wincmd p
  endif
endfunction

function! s:remove_buffer(bufnr)
  let db = getbufvar(a:bufnr, 'db_ui_database')
  let list = g:db_ui_drawer.dbs[db.name].buffers.list
  return filter(list, 'v:val !=? bufname(a:bufnr)')
endfunction

function! s:execute_query() abort
  call db_ui#utils#echo_msg('Executing query...')
  silent! exe '%DB '.b:db_ui_database.url
  call db_ui#utils#echo_msg('Done.')
endfunction

function! s:save_query() abort
  if empty(b:db_ui_database.save_path)
    return db_ui#utils#echo_err('Save location is empty. Please provide valid directory to g:db_ui_save_location')
  endif

  if !isdirectory(b:db_ui_database.save_path)
    call mkdir(b:db_ui_database.save_path, 'p')
  endif

  call inputsave()
  let name = input('Save as: ')
  call inputrestore()

  let full_name = printf('%s/%s', b:db_ui_database.save_path, name)
  if filereadable(full_name)
    return db_ui#utils#echo_err('That file already exists. Please choose another name.')
  endif

  exe 'write '.full_name
  let g:db_ui_drawer.dbs[b:db_ui_database.name].saved_sql.list = split(glob(printf('%s/*', b:db_ui_database.save_path)), "\n")
endfunction
