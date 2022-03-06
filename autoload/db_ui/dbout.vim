function! db_ui#dbout#jump_to_foreign_table() abort
  let db_url = db#resolve(b:db)
  let parsed = db#url#parse(db_url)
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    return db_ui#notifications#error(parsed.scheme.' scheme not supported for foreign key jump.')
  endif

  let cell_line_number = s:get_cell_line_number(scheme)
  let cell_range = s:get_cell_range(cell_line_number, getcurpos(), scheme)

  let virtual_cell_range = get(cell_range, 'virtual', cell_range)
  let field_name = trim(getline(cell_line_number - 1)[virtual_cell_range.from : virtual_cell_range.to])

  let field_value = trim(getline('.')[cell_range.from : cell_range.to])

  let foreign_key_query = substitute(scheme.foreign_key_query, '{col_name}', field_name, '')
  let Parser = get(scheme, 'parse_virtual_results', scheme.parse_results)
  let result = Parser(db_ui#schemas#query(db_url, scheme, foreign_key_query), 3)

  if empty(result)
    return db_ui#notifications#error('No valid foreign key found.')
  endif

  let [foreign_table_name, foreign_column_name,foreign_table_schema] = result[0]
  let query = printf(scheme.select_foreign_key_query, foreign_table_schema, foreign_table_name, foreign_column_name, db_ui#utils#quote_query_value(field_value))

  exe 'DB '.query
endfunction

function! db_ui#dbout#foldexpr(lnum) abort
  if getline(a:lnum) !~? '^[[:blank:]]*$'
    " Mysql
    if getline(a:lnum) =~? '^+---' && getline(a:lnum + 2) =~? '^+---'
      return '>1'
    endif
    " Postgres & Sqlserver
    if getline(a:lnum + 1) =~? '^----'
      return '>1'
    endif
    return 1
  endif

  "Postgres & Sqlserver
  if getline(a:lnum) =~? '^[[:blank:]]*$'
    if getline(a:lnum + 2) !~? '^----'
      return 1
    endif
    return 0
  endif

  return -1
endfunction

function! db_ui#dbout#get_cell_value() abort
  let parsed = db#url#parse(db#resolve(b:db))
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    return db_ui#notifications#error('Yanking cell value not supported for '.parsed.scheme.' scheme.')
  endif

  let cell_line_number = s:get_cell_line_number(scheme)
  let cell_range = s:get_cell_range(cell_line_number, getcurpos(), scheme)
  let field_value = getline('.')[(cell_range.from):(cell_range.to)]
  let start_spaces = len(matchstr(field_value, '^[[:blank:]]*'))
  let end_spaces = len(matchstr(field_value, '[[:blank:]]*$'))
  let old_selection = &selection
  set selection=inclusive
  let from = cell_range.from + start_spaces + 1
  let to = cell_range.to - end_spaces + 1
  call cursor(line('.'), from)
  let motion = max([(to - from), 0])
  let cmd = 'normal!v'
  if motion > 0
    let cmd .= motion.'l'
  endif
  exe cmd
  let &selection = old_selection
endfunction

function! db_ui#dbout#toggle_layout() abort
  let parsed = db#url#parse(db#resolve(b:db))
  let scheme = db_ui#schemas#get(parsed.scheme)
  if !has_key(scheme, 'layout_flag')
    return db_ui#notifications#error('Toggling layout not supported for '.parsed.scheme.' scheme.')
  endif
  let content = join(readfile(b:db_input), "\n")
  let expanded_layout = get(b:, 'db_ui_expanded_layout', 0)

  if expanded_layout
    let b:db_ui_expanded_layout = !expanded_layout
    norm R
    return
  endif

  let content = substitute(content, ';\?$', ' '.scheme.layout_flag, '')
  let tmp = tempname()
  call writefile(split(content, "\n"), tmp)
  let old_db_input = b:db_input
  let b:db_input = tmp
  norm R
  let b:db_input = old_db_input
  let b:db_ui_expanded_layout = !expanded_layout
endfunction

function! db_ui#dbout#yank_header() abort
  let parsed = db#url#parse(db#resolve(b:db))
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    return db_ui#notifications#error('Yanking headers not supported for '.parsed.scheme.' scheme.')
  endif

  let cell_line_number = s:get_cell_line_number(scheme)
  let table_line = '-'
  let column_line = getline(cell_line_number-1)
  let underline = getline(cell_line_number)
  let from = 0
  let to = 0
  let i = 0
  let columns=[]
  let lastcol = strlen(underline)
  while i <= lastcol
    if underline[i] !=? table_line || i == lastcol
      let to = i-1
      call add(columns, trim(column_line[from:to]))
      let from = i+1
    endif
    let i += 1
  endwhile
  let csv_columns = join(columns, ', ')
  call setreg(v:register, csv_columns)
endfunction

function! s:get_cell_range(cell_line_number, curpos, scheme) abort
  if get(a:scheme, 'has_virtual_results', v:false)
    return s:get_virtual_cell_range(a:cell_line_number, a:curpos)
  endif

  let line = getline(a:cell_line_number)
  let table_line = '-'

  let col = a:curpos[2] - 1
  let from = 0

  while col >= 0 && line[col] ==? table_line
    let from = col
    let col -= 1
  endwhile

  let col = a:curpos[2] - 1
  let to = 0

  while col <= len(line) && line[col] ==? table_line
    let to = col
    let col += 1
  endwhile

  return {'from': from, 'to': to}
endfunction

function! s:get_virtual_cell_range(cell_line_number, curpos) abort
  let line = getline(a:cell_line_number)
  let position = a:curpos[1:]
  let table_line = '-'

  let col = position[-1] - 1
  let virtual_from = 0

  while col >= 0 && line[col] ==? table_line
    let virtual_from = col
    let col -= 1
  endwhile

  let col = position[-1] - 1
  let virtual_to = 0

  while col <= len(line) && line[col] ==? table_line
    let virtual_to = col
    let col += 1
  endwhile

  let position_above = insert(position[1:], position[0] - 1)

  call cursor(add(position_above[:-2], virtual_from))
  norm! j
  let from = col('.')

  call cursor(add(position_above[:-2], virtual_to))
  norm! j
  let to = col('.')

  call cursor(position)

  " NOTE: 'virtual' refers to a position in reference to virtcol().
  "       other fields reference col()
  return {
  \   'from': max([from, 0]),
  \   'to': max([to, 0]),
  \   'virtual': {'from': max([virtual_from, 0]), 'to': max([virtual_to, 0])}
  \}
endfunction

function! s:get_cell_line_number(scheme) abort
  let line = line('.')

  while (line > a:scheme.cell_line_number)
    if getline(line) =~? a:scheme.cell_line_pattern
      return line
    endif
    let line -= 1
  endwhile

  return a:scheme.cell_line_number
endfunction

let s:progress_icons = ['/', '—', '\', '|']
let s:progress_buffers = {}
let s:progress = {
      \ 'win': -1,
      \ 'outwin': -1,
      \ 'buf': -1,
      \ 'timer': -1,
      \ 'counter': 0,
      \ 'icon_counter': 0,
      \ }

function! s:progress_tick(progress, timer) abort
  let a:progress.counter += 100
  if a:progress.icon_counter > 3
    let a:progress.icon_counter = 0
  endif
  let secs = string(a:progress.counter * 0.001).'s'
  let content = ' '.s:progress_icons[a:progress.icon_counter].' Execute query - '.secs
  if has('nvim')
    call nvim_buf_set_lines(a:progress.buf, 0, -1, v:false, [content])
  else
    call popup_settext(a:progress.win, content)
  endif
  let a:progress.icon_counter += 1
endfunction

function! s:progress_winpos(win)
  let pos = win_screenpos(a:win)
  return [
        \ pos[0] + (winheight(a:win) / 2),
        \ pos[1] + (winwidth(a:win) / 2) - 12,
        \ ]
endfunction

function! s:progress_hide() abort
  let bufname = bufname()
  let progress = get(s:progress_buffers, bufname, {})
  if empty(progress)
    return
  endif
  if has('nvim')
    silent! call nvim_win_close(progress.win, v:true)
  else
    silent! call popup_close(progress.win)
  endif
  silent! call timer_stop(progress.timer)
  unlet! s:progress_buffers[bufname]
  call s:progress_reset_positions()
endfunction

function! s:progress_reset_positions()
  for bprogress in values(s:progress_buffers)
    let win = bprogress.win
    let [row, col] = s:progress_winpos(bprogress.outwin)
    if has('nvim')
      call nvim_win_set_config(win, { 'relative': 'editor', 'row': row - 2, 'col': col })
    else
      call popup_move(win, { 'line': row, 'col': col })
    endif
  endfor
endfunction

function! s:progress_show_neovim() abort
  let bufname =  bufname()
  let outwin = win_getid()
  let progress = copy(s:progress)
  let progress.outwin = outwin
  let progress.buf = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(progress.buf, 0, -1, v:false, ['| Execute query - 0.0s'])
  let [row, col] = s:progress_winpos(outwin)
  let opts = {
        \ 'relative': 'editor',
        \ 'width': 24,
        \ 'height': 1,
        \ 'row': row - 2,
        \ 'col': col,
        \ 'focusable': v:false,
        \ 'style': 'minimal'
        \ }

  if has('nvim-0.5')
    let opts.border = 'rounded'
  endif
  let progress.win = nvim_open_win(progress.buf, v:false, opts)
  let progress.timer = timer_start(100, function('s:progress_tick', [progress]), { 'repeat': -1 })
  let s:progress_buffers[bufname] = progress
endfunction

function! s:progress_show_vim()
  let outwin = winnr()
  let bufname = bufname()
  let pos = win_screenpos(outwin)
  let progress = copy(s:progress)
  let progress.outwin = outwin
  let [row, col] = s:progress_winpos(outwin)
  let progress.win = popup_create('| Execute query - 0.0s', {
        \ 'line': row,
        \ 'col': col,
        \ 'minwidth': 24,
        \ 'maxwidth': 24,
        \ 'minheight': 1,
        \ 'maxheight': 1,
        \ 'border': [],
        \ })
  let progress.timer = timer_start(100, function('s:progress_tick', [progress]), { 'repeat': -1 })
  let s:progress_buffers[bufname] = progress
endfunction

function! s:progress_show()
  if has('nvim')
    call s:progress_show_neovim()
  else
    call s:progress_show_vim()
  endif
  call s:progress_reset_positions()
endfunction


if exists('*nvim_open_win') || exists('*popup_create')
  augroup dbui_async_queries_dbout
    autocmd!
    autocmd User DBQueryPre call s:progress_show()
    autocmd User DBQueryPost call s:progress_hide()
  augroup END
endif
