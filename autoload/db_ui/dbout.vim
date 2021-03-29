function! db_ui#dbout#jump_to_foreign_table() abort
  let parsed = db#url#parse(b:db)
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
  let result = Parser(db_ui#schemas#query(b:db, scheme, foreign_key_query), 3)

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
  let parsed = db#url#parse(b:db)
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
  let parsed = db#url#parse(b:db)
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
  let parsed = db#url#parse(b:db)
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
let s:progress = {
      \ 'win': -1,
      \ 'buf': -1,
      \ 'timer': -1,
      \ 'counter': 0,
      \ 'icon_counter': 0,
      \ }

function s:progress_tick(timer) abort
  let s:progress.counter += 100
  if s:progress.icon_counter > 3
    let s:progress.icon_counter = 0
  endif
  let secs = string(s:progress.counter * 0.001).'s'
  let content = ' '.s:progress_icons[s:progress.icon_counter].' Execute query - '.secs
  if has('nvim')
    call nvim_buf_set_lines(s:progress.buf, 0, -1, v:false, [content])
  else
    call popup_settext(s:progress.win, content)
  endif
  let s:progress.icon_counter += 1
endfunction

function! s:progress_hide() abort
  if has('nvim')
    silent! call nvim_win_close(s:progress.win, v:true)
  else
    silent! call popup_close(s:progress.win)
  endif
  silent! call timer_stop(s:progress.timer)
  let s:progress.counter = 0
  let s:progress.icon_counter = 0
  let s:progress.win = -1
  let s:progress.buf = -1
  let s:progress.timer = -1
endfunction

function! s:get_out_win()
endfunction

function! s:progress_show_neovim(outwin) abort
  let outwin = win_getid(a:outwin)
  let s:progress.buf = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(s:progress.buf, 0, -1, v:false, ['| Execute query - 0.0s'])
  let opts = {
        \ 'relative': 'win',
        \ 'win': outwin,
        \ 'width': 24,
        \ 'height': 1,
        \ 'row': winheight(outwin) / 2,
        \ 'col': winwidth(outwin) / 2 - 12,
        \ 'focusable': v:false,
        \ 'style': 'minimal'
        \ }
  let s:progress.win = nvim_open_win(s:progress.buf, v:false, opts)
  let s:progress.timer = timer_start(100, function('s:progress_tick'), { 'repeat': -1 })
endfunction

function! s:progress_show_vim(outwin)
  let pos = win_screenpos(a:outwin)
  let s:progress.win = popup_create('| Execute query - 0.0s', {
        \ 'line': pos[0] + (winheight(a:outwin) / 2),
        \ 'col': pos[1] + (winwidth(a:outwin) / 2) - 12,
        \ 'minwidth': 24,
        \ 'maxwidth': 24,
        \ 'minheight': 1,
        \ 'maxheight': 1,
        \ })
  let s:progress.timer = timer_start(100, function('s:progress_tick'), { 'repeat': -1 })
endfunction

function! s:progress_show()
  call s:progress_hide()
  let outwin = get(filter(range(1, winnr('$')), 'getwinvar(v:val, "&filetype") ==? "dbout"'), 0, -1)
  if outwin < 0
    return
  endif

  if has('nvim')
    return s:progress_show_neovim(outwin)
  endif

  return s:progress_show_vim(outwin)
endfunction


if exists('*nvim_open_win') || exists('*popup_create')
  augroup dbui_async_queries_dbout
    autocmd!
    autocmd User DBQueryStart call s:progress_show()
    autocmd User DBQueryFinished call s:progress_hide()
  augroup END
endif
