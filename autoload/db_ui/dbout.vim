let s:foreign_key_query = "
      \ ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name
      \ FROM
      \     information_schema.table_constraints AS tc
      \     JOIN information_schema.key_column_usage AS kcu
      \       ON tc.constraint_name = kcu.constraint_name
      \     JOIN information_schema.constraint_column_usage AS ccu
      \       ON ccu.constraint_name = tc.constraint_name
      \ WHERE constraint_type = 'FOREIGN KEY' and kcu.column_name = '{col_name}'"

let s:foreign_key_postgresql = {
      \ 'query': printf('-A -c "SELECT%s LIMIT 1"', s:foreign_key_query),
      \ 'cell_line_delimiter': '+',
      \ 'cell_delimiter': '|',
      \ 'parse_results': {results -> results[1:(len(results) - 2)]},
      \ 'quote': 1,
      \ }

let s:foreign_key_sqlserver = {
      \   'query': printf('-h-1 -W -Q "SELECT TOP 1%s"', substitute(s:foreign_key_query, '^\s*SELECT', '', '')),
      \   'cell_line_delimiter': ' ',
      \   'cell_delimiter': ' ',
      \   'parse_results': {results -> results[0:(len(results) - 3)]},
      \   'quote': 0,
      \ }

let s:foreign_key_query = {
      \ 'postgres': s:foreign_key_postgresql,
      \ 'postgresql': s:foreign_key_postgresql,
      \ }

function! db_ui#dbout#jump_to_foreign_table() abort
  let parsed = db#url#parse(b:db)
  let db_query = get(s:foreign_key_query, parsed.scheme)
  if empty(db_query)
    return db_ui#utils#echo_err(parsed.scheme.' scheme not supported for foreign key jump.')
  endif

  let cell_range = s:get_cell_range(getline(2), col('.'), db_query.cell_line_delimiter)
  let field_name = trim(getline(1)[(cell_range.from):(cell_range.to)])
  let field_value = trim(getline('.')[(cell_range.from):(cell_range.to)])
  let base_query = db#adapter#dispatch(b:db, 'interactive')
  let foreign_key_query = substitute(db_query.query, '{col_name}', field_name, '')
  let query = printf('%s %s', base_query, foreign_key_query)
  let result = systemlist(query)
  let result = db_query.parse_results(result)
  if empty(result)
    return
  endif

  let result = result[0]
  let [foreign_table_name, foreign_column_name] = map(split(result, db_query.cell_delimiter), 'trim(v:val)')
  if db_query.quote
    let foreign_table_name = printf('"%s"', foreign_table_name)
    let foreign_column_name = printf('"%s"', foreign_column_name)
  endif
  exe printf(':DB select * from %s where %s = %s', foreign_table_name, foreign_column_name, db_ui#utils#quote_query_value(field_value))
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
