let s:dbs = {}
let s:buffers = {}
let s:buffer_counter = {}
let s:icons = { 'db': ' ', 'table': ' 🗉 ', 'buffer': '* ' }

let s:tree = { 'line': 1, 'content': [] }

function! s:tree.add(text, type, icon, ...) abort
  let extra_opts = a:0 > 0 ? a:1 : {}
  call add(self.content, extend({'line': self.line, 'text': a:text, 'icon': a:icon, 'type': a:type }, extra_opts))
  let self.line += 1
endfunction

function! s:tree.render() abort
  let view = winsaveview()
  let self.content = []
  let self.line = 1
  if !empty(s:buffers)
    call self.add('Buffers:', 'noaction', '')
    for [bufnr, bufname] in items(s:buffers)
      call self.add(substitute(bufname, '^[^\[]*', '', ''), 'buffer', s:icons.buffer, { 'bufname': bufname })
    endfor
    call self.add('', 'noaction', '')
  endif
  call self.add('Databases:', 'noaction', '')
  for [db_name, db] in items(s:dbs)
    call self.add(db_name, 'db', s:icons.db)
    if db.expanded
      for table in db.tables
        call self.add(table, 'table', s:icons.table, {'db_name': db_name })
      endfor
    endif
  endfor

  let content = map(copy(self.content), 'v:val.icon.v:val.text')

  setlocal modifiable
  silent 1,$delete _
  call setline(1, content)
  setlocal nomodifiable
  call winrestview(view)
endfunction

function! s:open_db_ui() abort
  let buffer = bufnr('__dbui__')
  if buffer > -1
    silent! exe 'b'.buffer
    return
  endif
  silent! exe 'vertical topleft new __dbui__'
  silent! exe 'vertical topleft resize '.g:db_ui_winwidth
  setlocal filetype=__dbui__ buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nomodifiable winfixwidth

  let db_names = keys(g:dbs)
  for db_name in db_names
    if !has_key(s:dbs, db_name)
      let s:dbs[db_name] = {
            \ 'url': g:dbs[db_name], 'conn': '', 'expanded': 0, 'tables': [], 'name': db_name
            \ }
    endif
  endfor

  call s:tree.render()
  nnoremap <silent><buffer> <Plug>(DBUI_SelectLine) :call <sid>toggle_line()<CR>
  nnoremap <silent><buffer> <Plug>(DBUI_Redraw) :call <sid>tree.render()<CR>
  augroup db_ui
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:tree.render()
  augroup END
  syntax clear
  for [icon_name, icon] in items(s:icons)
    exe 'syn match dbui_'.icon_name. ' /^'.icon.'/'
  endfor
  syn match dbui_titles /^\(Buffers\|Databases\):$/
  hi default link dbui_db Directory
  hi default link dbui_table String
  hi default link dbui_buffer Operator
  hi default link dbui_titles Constant
  silent! doautocmd User DBUIOpened
endfunction

function! s:focus_window() abort
  if winnr('$') ==? 1
    vertical new
    return
  endif

  let found = 0
  for win in range(1, winnr('$'))
    let buf = winbufnr(win)
    if !empty(getbufvar(buf, 'db_ui_table'))
      let found = 1
      exe win.'wincmd w'
      break
    endif
  endfor

  if !found
    2wincmd w
  endif
endfunction

function s:open_buffer(buffer_name, table)
  call s:focus_window()
  let bufnr = bufnr(a:buffer_name)
  if bufnr > -1
    silent! exe 'b '.bufnr
    return
  endif

  silent! exe 'edit '.a:buffer_name
  let content = printf('select * from "%s" LIMIT 200;', a:table)
  let s:buffers[bufnr(a:buffer_name)] = a:buffer_name
  setlocal filetype=sql nolist noswapfile nowrap cursorline nospell modifiable
  silent 1,$delete _
  call setline(1, content)
endfunction

function! s:open_db_ui_query(db, table) abort
  let buffer_basename = printf('[%s] %s', a:db.name, a:table)
  if has_key(s:buffer_counter, buffer_basename)
    let new_name = buffer_basename.'-'.s:buffer_counter[buffer_basename]
    let s:buffer_counter[buffer_basename] += 1
    let buffer_basename = new_name
  else
    let s:buffer_counter[buffer_basename] = 1
  endif
  let buffer_name = printf('%s.%s', tempname(), buffer_basename)
  call s:open_buffer(buffer_name, a:table)

  let b:db_ui_table = a:table
  let b:db_ui = a:db
  augroup db_ui_query
    autocmd! * <buffer>
    autocmd BufWritePost <buffer> silent! exe '%DB '.b:db_ui.url
    autocmd BufDelete,BufWipeout <buffer> silent! call remove(s:buffers, str2nr(expand('<abuf>')))
  augroup END
endfunction

function! s:toggle_line() abort
  let item = s:tree.content[line('.') - 1]
  if item.type ==? 'db'
    call s:toggle_db(item)
    return s:tree.render()
  endif

  if item.type ==? 'table'
    return s:open_db_ui_query(s:dbs[item.db_name], item.text)
  endif

  if item.type ==? 'buffer'
    return s:open_buffer(item.bufname, '')
  endif

  if item.type ==? 'noaction'
    return
  endif

  throw 'Unknown line.'
endfunction

function! s:toggle_db(item) abort
  let db = s:dbs[a:item.text]

  if db.expanded
    let db.expanded = 0
    return db
  endif

  let db.expanded = 1
  if empty(db.conn)
    let db.conn = db#connect(db.url)
    let db.tables = db#adapter#call(db.conn, 'tables', [db.conn], [])
  endif
endfunction

function! db_ui#open() abort
  if empty(g:dbs)
    throw 'g:dbs is not defined.'
  endif

  return s:open_db_ui()
endfunction
