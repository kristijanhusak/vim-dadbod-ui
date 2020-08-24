function! db_ui#dbout#jump_to_foreign_table() abort
  let parsed = db#url#parse(b:db)
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    return db_ui#utils#echo_err(parsed.scheme.' scheme not supported for foreign key jump.')
  endif

  let cell_line_number = s:get_cell_line_number(scheme)
  let cell_range = s:get_cell_range(getline(cell_line_number), col('.'))
  let field_name = trim(getline(cell_line_number - 1)[(cell_range.from):(cell_range.to)])
  let field_value = trim(getline('.')[(cell_range.from):(cell_range.to)])
  let foreign_key_query = substitute(scheme.foreign_key_query, '{col_name}', field_name, '')
  let result = scheme.parse_results(db_ui#schemas#query({ 'conn': b:db }, foreign_key_query), 3)
  if empty(result)
    return db_ui#utils#echo_err('No valid foreign key found.')
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
    return db_ui#utils#echo_err('Yanking cell value not supported for '.parsed.scheme.' scheme.')
  endif

  let cell_line_number = s:get_cell_line_number(scheme)
  let cell_range = s:get_cell_range(getline(cell_line_number), col('.'))
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
    return db_ui#utils#echo_err('Toggling layout not supported for '.parsed.scheme.' scheme.')
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
    return db_ui#utils#echo_err('Yanking headers not supported for '.parsed.scheme.' scheme.')
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

function! s:get_cell_range(line, col) abort
  let table_line = '-'
  let col = a:col - 1
  let from = 0
  let to = 0
  while col >= 0 && a:line[col] ==? table_line
    let from = col
    let col -= 1
  endwhile
  let col = a:col - 1
  while col <= len(a:line) && a:line[col] ==? table_line
    let to = col
    let col += 1
  endwhile

  return {'from': from, 'to': to}
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
