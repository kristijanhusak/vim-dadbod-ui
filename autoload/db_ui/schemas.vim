let s:postgres_foreign_key_query = "
      \ SELECT ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name
      \ FROM
      \     information_schema.table_constraints AS tc
      \     JOIN information_schema.key_column_usage AS kcu
      \       ON tc.constraint_name = kcu.constraint_name
      \     JOIN information_schema.constraint_column_usage AS ccu
      \       ON ccu.constraint_name = tc.constraint_name
      \ WHERE constraint_type = 'FOREIGN KEY' and kcu.column_name = '{col_name}' LIMIT 1"

let s:postgresql_args = '-A -c "%s"'
let s:postgresql = {
      \ 'foreign_key_query': printf(s:postgresql_args, s:postgres_foreign_key_query),
      \ 'schemes_query': printf(s:postgresql_args, 'SELECT schema_name FROM information_schema.schemata'),
      \ 'schemes_tables_query': printf(s:postgresql_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \ 'select_foreign_key_query': 'select * from "%s" where "%s" = %s',
      \ 'cell_line_delimiter': '+',
      \ 'cell_line_number': 2,
      \ 'cell_delimiter': '|',
      \ 'parse_results': {results -> results[1:(len(results) - 2)]},
      \ 'quote': 1,
      \ }

let s:sqlserver_foreign_keys_query = "
      \ SELECT TOP 1
      \    c2.table_name as foreign_table_name,
      \    kcu2.column_name as foreign_column_name
      \ from   information_schema.table_constraints c
      \        inner join information_schema.key_column_usage kcu
      \          on c.constraint_schema = kcu.constraint_schema
      \             and c.constraint_name = kcu.constraint_name
      \        inner join information_schema.referential_constraints rc
      \          on c.constraint_schema = rc.constraint_schema
      \             and c.constraint_name = rc.constraint_name
      \        inner join information_schema.table_constraints c2
      \          on rc.unique_constraint_schema = c2.constraint_schema
      \             and rc.unique_constraint_name = c2.constraint_name
      \        inner join information_schema.key_column_usage kcu2
      \          on c2.constraint_schema = kcu2.constraint_schema
      \             and c2.constraint_name = kcu2.constraint_name
      \             and kcu.ordinal_position = kcu2.ordinal_position
      \ where  c.constraint_type = 'FOREIGN KEY'
      \ and kcu.column_name = '{col_name}'"

let s:sqlserver_args = '-h-1 -W -Q "%s"'
let s:sqlserver = {
      \   'foreign_key_query': printf(s:sqlserver_args, s:sqlserver_foreign_keys_query),
      \   'schemes_query': printf(s:sqlserver_args, 'SELECT schema_name FROM information_schema.schemata'),
      \   'schemes_tables_query': printf(s:sqlserver_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \   'select_foreign_key_query': 'select * from %s where %s = %s',
      \   'cell_line_delimiter': ' ',
      \   'cell_line_number': 2,
      \   'cell_delimiter': ' ',
      \   'parse_results': {results -> results[0:(len(results) - 3)]},
      \   'quote': 0,
      \ }

let s:mysql_foreign_key_query =  "
      \ SELECT referenced_table_name, referenced_column_name
      \ from information_schema.key_column_usage
      \ where referenced_table_name is not null and column_name = '{col_name}' LIMIT 1"
let s:mysql_args = '-e "%s"'
let s:mysql = {
      \ 'foreign_key_query': printf(s:mysql_args, s:mysql_foreign_key_query),
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
