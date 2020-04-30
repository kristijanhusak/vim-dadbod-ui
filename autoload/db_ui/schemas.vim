let s:foreign_key_query = "
      \ ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name
      \ FROM
      \     information_schema.table_constraints AS tc
      \     JOIN information_schema.key_column_usage AS kcu
      \       ON tc.constraint_name = kcu.constraint_name
      \     JOIN information_schema.constraint_column_usage AS ccu
      \       ON ccu.constraint_name = tc.constraint_name
      \ WHERE constraint_type = 'FOREIGN KEY' and kcu.column_name = '{col_name}'"

let s:postgresql_args = '-A -c "%s"'
let s:postgresql = {
      \ 'foreign_key_query': printf(s:postgresql_args, printf('SELECT%s LIMIT 1', s:foreign_key_query)),
      \ 'schemes_query': printf(s:postgresql_args, 'SELECT schema_name FROM information_schema.schemata'),
      \ 'schemes_tables_query': printf(s:postgresql_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \ 'select_foreign_key_query': 'select * from "%s" where "%s" = %s',
      \ 'cell_line_delimiter': '+',
      \ 'cell_line_number': 2,
      \ 'cell_delimiter': '|',
      \ 'parse_results': {results -> results[1:(len(results) - 2)]},
      \ 'quote': 1,
      \ }

let s:sqlserver_args = '-h-1 -W -Q "%s"'
let s:sqlserver = {
      \   'foreign_key_query': printf(s:sqlserver_args, printf('SELECT TOP 1%s', s:foreign_key_query)),
      \   'schemes_query': printf(s:sqlserver_args, 'SELECT schema_name FROM information_schema.schemata'),
      \   'schemes_tables_query': printf(s:sqlserver_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \   'select_foreign_key_query': 'select * from %s where %s = %s',
      \   'cell_line_delimiter': ' ',
      \   'cell_line_number': 2,
      \   'cell_delimiter': ' ',
      \   'parse_results': {results -> results[0:(len(results) - 3)]},
      \   'quote': 0,
      \ }

let s:mysql_args = '-e "%s"'
let s:mysql = {
      \ 'foreign_key_query': printf(s:mysql_args, "SELECT referenced_table_name, referenced_column_name from information_schema.key_column_usage where referenced_table_name is not null and column_name = '{col_name}' LIMIT 1"),
      \ 'schemes_query': printf(s:mysql_args, 'SELECT schema_name FROM information_schema.schemata'),
      \ 'schemes_tables_query': printf(s:mysql_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \ 'select_foreign_key_query': 'select * from %s where %s = %s',
      \ 'cell_line_delimiter': '+',
      \ 'cell_line_number': 3,
      \ 'cell_delimiter': '\t',
      \ 'parse_results': {results -> results[1:]},
      \ 'quote': 1,
      \ }
let s:schemas = {
      \ 'postgres': s:postgresql,
      \ 'postgresql': s:postgresql,
      \ 'sqlserver': s:sqlserver,
      \ 'mysql': s:mysql,
      \ }

if !exists('g:db_adapter_postgres')
  let g:db_adapter_postgres = 'db#adapter#postgresql#'
endif

if !exists('g:db_adapter_sqlite3')
  let g:db_adapter_sqlite3 = 'db#adapter#sqlite#'
endif

function! db_ui#schemas#get(scheme) abort
  return get(s:schemas, a:scheme, {})
endfunction

function! db_ui#schemas#query(db, query) abort
  let base_query = db#adapter#dispatch(a:db.url, 'interactive')
  return systemlist(printf('%s %s', base_query, a:query))
endfunction
