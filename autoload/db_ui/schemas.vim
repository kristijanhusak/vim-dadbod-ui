function! s:results_parser(results, delimiter, min_len) abort
  if a:min_len ==? 1
    return filter(a:results, '!empty(trim(v:val))')
  endif
  let mapped = map(a:results, {_,row -> filter(split(row, a:delimiter), '!empty(trim(v:val))')})
  if a:min_len > 1
    return filter(mapped, 'len(v:val) ==? '.a:min_len)
  endif

  let counts = map(copy(mapped), 'len(v:val)')
  let min_len = max(counts)

  return filter(mapped,'len(v:val) ==? '.min_len)
endfunction

let s:postgres_foreign_key_query = "
      \ SELECT ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name, ccu.table_schema as foreign_table_schema
      \ FROM
      \     information_schema.table_constraints AS tc
      \     JOIN information_schema.key_column_usage AS kcu
      \       ON tc.constraint_name = kcu.constraint_name
      \     JOIN information_schema.constraint_column_usage AS ccu
      \       ON ccu.constraint_name = tc.constraint_name
      \ WHERE constraint_type = 'FOREIGN KEY' and kcu.column_name = '{col_name}' LIMIT 1"

let s:postgresql_args = '-A -c "%s"'
let s:postgresql = {
      \ 'args': s:postgresql_args,
      \ 'foreign_key_query': printf(s:postgresql_args, s:postgres_foreign_key_query),
      \ 'schemes_query': printf(s:postgresql_args, 'SELECT schema_name FROM information_schema.schemata'),
      \ 'schemes_tables_query': printf(s:postgresql_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \ 'select_foreign_key_query': 'select * from "%s"."%s" where "%s" = %s',
      \ 'cell_line_number': 2,
      \ 'cell_line_pattern': '^-\++-\+',
      \ 'parse_results': {results,min_len -> s:results_parser(results[1:-2], '|', min_len)},
      \ 'default_scheme': 'public',
      \ 'layout_flag': '\\x',
      \ 'quote': 1,
      \ }

let s:sqlserver_foreign_keys_query = "
      \ SELECT TOP 1 c2.table_name as foreign_table_name, kcu2.column_name as foreign_column_name, kcu2.table_schema as foreign_table_schema
      \ from   information_schema.table_constraints c
      \        inner join information_schema.key_column_usage kcu
      \          on c.constraint_schema = kcu.constraint_schema and c.constraint_name = kcu.constraint_name
      \        inner join information_schema.referential_constraints rc
      \          on c.constraint_schema = rc.constraint_schema and c.constraint_name = rc.constraint_name
      \        inner join information_schema.table_constraints c2
      \          on rc.unique_constraint_schema = c2.constraint_schema and rc.unique_constraint_name = c2.constraint_name
      \        inner join information_schema.key_column_usage kcu2
      \          on c2.constraint_schema = kcu2.constraint_schema and c2.constraint_name = kcu2.constraint_name and kcu.ordinal_position = kcu2.ordinal_position
      \ where  c.constraint_type = 'FOREIGN KEY'
      \ and kcu.column_name = '{col_name}'
      \ "

let s:sqlserver_args = '-h-1 -W -s "|" -Q "%s"'
let s:sqlserver = {
      \   'args': s:sqlserver_args,
      \   'foreign_key_query': printf(s:sqlserver_args, trim(s:sqlserver_foreign_keys_query)),
      \   'schemes_query': printf(s:sqlserver_args, 'SELECT schema_name FROM information_schema.schemata'),
      \   'schemes_tables_query': printf(s:sqlserver_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \   'select_foreign_key_query': 'select * from %s.%s where %s = %s',
      \   'cell_line_number': 2,
      \   'cell_line_pattern': '^-\+.-\+',
      \   'parse_results': {results, min_len -> s:results_parser(results[0:-3], '|', min_len)},
      \   'quote': 0,
      \   'default_scheme': 'dbo',
      \ }

let s:mysql_foreign_key_query =  "
      \ SELECT referenced_table_name, referenced_column_name, referenced_table_schema
      \ from information_schema.key_column_usage
      \ where referenced_table_name is not null and column_name = '{col_name}' LIMIT 1"
let s:mysql_args = '-e "%s"'
let s:mysql = {
      \ 'args': s:mysql_args,
      \ 'foreign_key_query': printf(s:mysql_args, s:mysql_foreign_key_query),
      \ 'schemes_query': printf(s:mysql_args, 'SELECT schema_name FROM information_schema.schemata'),
      \ 'schemes_tables_query': printf(s:mysql_args, 'SELECT table_schema, table_name FROM information_schema.tables'),
      \ 'select_foreign_key_query': 'select * from %s.%s where %s = %s',
      \ 'cell_line_number': 3,
      \ 'cell_line_pattern': '^+-\++-\+',
      \ 'parse_results': {results, min_len -> s:results_parser(results[1:], '\t', min_len)},
      \ 'default_scheme': '',
      \ 'layout_flag': '\\G',
      \ 'quote': 0,
      \ }

let s:oracle_args = join(
      \    [
           \  'SET linesize 4000',
           \  'SET pagesize 4000',
           \  'COLUMN owner FORMAT a20',
           \  'COLUMN table_name FORMAT a25',
           \  'COLUMN column_name FORMAT a25',
           \  '%s',
      \    ],
      \    ";\n"
      \ ).';'
let s:oracle_foreign_key_query = "
      \SELECT DISTINCT RFRD.table_name, RFRD.column_name, RFRD.owner
      \ FROM all_cons_columns RFRD
      \ JOIN all_constraints CON ON RFRD.constraint_name = CON.r_constraint_name
      \ JOIN all_cons_columns RFRING ON CON.constraint_name = RFRING.constraint_name
      \ JOIN all_users U ON CON.owner = U.username
      \ WHERE CON.constraint_type = 'R'
      \ AND U.common = 'NO'
      \ AND RFRING.column_name = '{col_name}'"
let s:oracle_schemes_tables_query = "
      \SELECT T.owner, T.table_name
      \ FROM all_tables T
      \ JOIN all_users U ON T.owner = U.username
      \ WHERE U.common = 'NO'
      \ ORDER BY T.table_name"
let s:oracle = {
      \   'args': s:oracle_args,
      \   'cell_line_number': 1,
      \   'cell_line_pattern': '^-\+\( \+-\+\)*',
      \   'default_scheme': '',
      \   'foreign_key_query': printf(s:oracle_args, s:oracle_foreign_key_query),
      \   'has_virtual_results': v:true,
      \   'parse_results': {results, min_len -> s:results_parser(results[15:-5], '\s\s\+', min_len)},
      \   'parse_virtual_results': {results, min_len -> s:results_parser(results[15:-4], '\s\s\+', min_len)},
      \   'pipe_query': v:true,
      \   'quote': v:true,
      \   'schemes_query': printf(s:oracle_args, "SELECT username FROM all_users WHERE common = 'NO' ORDER BY username"),
      \   'schemes_tables_query': printf(s:oracle_args, s:oracle_schemes_tables_query),
      \   'select_foreign_key_query': printf(s:oracle_args, 'SELECT * FROM "%s"."%s" WHERE "%s" = %s'),
      \ }

let s:schemas = {
      \ 'postgres': s:postgresql,
      \ 'postgresql': s:postgresql,
      \ 'sqlserver': s:sqlserver,
      \ 'mysql': s:mysql,
      \ 'oracle': s:oracle,
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

function! db_ui#schemas#format_query(db, scheme, query) abort
  let base_query = db#adapter#dispatch(
  \   type(a:db) == v:t_string ? a:db : a:db.conn,
  \   'interactive'
  \ )
  let format_expression = '%s %s'

  return get(a:scheme, 'pipe_query', v:false) ?
  \  printf(format_expression, 'echo "'.a:query.'" |', base_query) :
  \  printf(format_expression, base_query, a:query)
endfunction

function! db_ui#schemas#query(db, scheme, query) abort
  let formatted_query = db_ui#schemas#format_query(a:db, a:scheme, a:query)
  return map(systemlist(formatted_query), {_, val -> substitute(val, "\r$", "", "")})
endfunction
