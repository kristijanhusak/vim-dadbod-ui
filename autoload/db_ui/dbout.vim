function! db_ui#dbout#jump_to_foreign_table() abort
  let parsed = db#url#parse(b:db)
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    return db_ui#utils#echo_err(parsed.scheme.' scheme not supported for foreign key jump.')
  endif

  let cell_range = s:get_cell_range(getline(scheme.cell_line_number), col('.'), scheme.cell_line_delimiter)
  let field_name = trim(getline(scheme.cell_line_number - 1)[(cell_range.from):(cell_range.to)])
  let field_value = trim(getline('.')[(cell_range.from):(cell_range.to)])
  let foreign_key_query = substitute(scheme.foreign_key_query, '{col_name}', field_name, '')
  let result = db_ui#schemas#query({ 'url': b:db }, foreign_key_query)
  let result = scheme.parse_results(result)
  if empty(result)
    return
  endif

  let result = result[0]
  let [foreign_table_name, foreign_column_name] = map(split(result, scheme.cell_delimiter), 'trim(v:val)')
  let query = printf(scheme.select_foreign_key_query, foreign_table_name, foreign_column_name, db_ui#utils#quote_query_value(field_value))
  exe 'DB '.query
endfunction

function! s:get_cell_range(line, col, delimiter) abort
  let col = a:col - 1
  let from = 0
  let to = 0
  while col >= 0 && a:line[col] !=? a:delimiter
    let from = col
    let col -= 1
  endwhile
  let col = a:col - 1
  while col <= len(a:line) && a:line[col] !=? a:delimiter
    let to = col
    let col += 1
  endwhile

  return {'from': from, 'to': to}
endfunction
