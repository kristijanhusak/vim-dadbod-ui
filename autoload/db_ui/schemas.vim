function! s:strip_quotes(results) abort
  return split(substitute(join(a:results),'"','','g'))
endfunction

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

let s:postgres_list_schema_query = "
    \ SELECT nspname as schema_name
    \ FROM pg_catalog.pg_namespace
    \ WHERE nspname !~ '^pg_temp_'
    \   and pg_catalog.has_schema_privilege(current_user, nspname, 'USAGE')
    \ order by nspname"

let s:postgres_tables_and_views = "
      \ SELECT table_schema, table_name FROM information_schema.tables UNION ALL
      \ select schemaname, matviewname from pg_matviews;"
let s:postgresql = {
      \ 'args': ['-A', '-c'],
      \ 'foreign_key_query': s:postgres_foreign_key_query,
      \ 'schemes_query': s:postgres_list_schema_query,
      \ 'schemes_tables_query': s:postgres_tables_and_views,
      \ 'select_foreign_key_query': 'select * from "%s"."%s" where "%s" = %s',
      \ 'cell_line_number': 2,
      \ 'cell_line_pattern': '^-\++-\+',
      \ 'parse_results': {results,min_len -> s:results_parser(filter(results, '!empty(v:val)')[1:-2], '|', min_len)},
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

let s:sqlserver = {
      \   'args': ['-h-1', '-W', '-s', '|', '-Q'],
      \   'foreign_key_query': trim(s:sqlserver_foreign_keys_query),
      \   'schemes_query': 'SELECT schema_name FROM INFORMATION_SCHEMA.SCHEMATA',
      \   'schemes_tables_query': 'SELECT table_schema, table_name FROM INFORMATION_SCHEMA.TABLES',
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
let s:mysql = {
      \ 'foreign_key_query': s:mysql_foreign_key_query,
      \ 'schemes_query': 'SELECT schema_name FROM information_schema.schemata',
      \ 'schemes_tables_query': 'SELECT table_schema, table_name FROM information_schema.tables',
      \ 'select_foreign_key_query': 'select * from %s.%s where %s = %s',
      \ 'cell_line_number': 3,
      \ 'requires_stdin': v:true,
      \ 'cell_line_pattern': '^+-\++-\+',
      \ 'parse_results': {results, min_len -> s:results_parser(results[1:], '\t', min_len)},
      \ 'default_scheme': '',
      \ 'layout_flag': '\\G',
      \ 'quote': 0,
      \ 'filetype': 'mysql',
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
      \SELECT /*csv*/ DISTINCT RFRD.table_name, RFRD.column_name, RFRD.owner
      \ FROM all_cons_columns RFRD
      \ JOIN all_constraints CON ON RFRD.constraint_name = CON.r_constraint_name
      \ JOIN all_cons_columns RFRING ON CON.constraint_name = RFRING.constraint_name
      \ JOIN all_users U ON CON.owner = U.username
      \ WHERE CON.constraint_type = 'R'
      \ AND U.common = 'NO'
      \ AND RFRING.column_name = '{col_name}'"
let s:oracle_toggle_layout_query = "
      \ set feedback off \n
      \ create or replace procedure print_cols_as_rows( p_query in varchar2 )\n
      \ AUTHID CURRENT_USER is\n
      \   l_descriptionTable    dbms_sql.desc_tab;\n
      \   l_execStatus          integer;\n
      \   l_columnCount         integer;\n
      \   l_rowCount            integer;\n
      \   l_currentColumnLength integer;\n
      \   l_maxColumnLength     integer := 0;\n
      \   l_theCursor           integer default dbms_sql.open_cursor;\n
      \   l_columnValue         varchar2(4000);\n
      \   dash_line             varchar2(30) := rpad('-', 30, '-');
      \ begin \n
      \   dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);\n
      \   dbms_sql.describe_columns(l_theCursor, l_columnCount, l_descriptionTable);\n
      \
      \   for i in 1 .. l_columnCount loop\n
      \     dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);\n
      \     l_currentColumnLength := LENGTH(l_descriptionTable(i).col_name);\n
      \     if l_currentColumnLength > l_maxColumnLength then\n
      \        l_maxColumnLength := l_currentColumnLength;\n
      \     end if;\n
      \   end loop;\n
      \
      \   l_execStatus := dbms_sql.execute(l_theCursor);\n
      \   l_rowCount := 0;\n
      \   while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop\n
      \     l_rowCount := l_rowCount + 1;\n
      \     dbms_output.put_line( dash_line || ' ' || l_rowCount || '. row ' || dash_line);\n
      \     for i in 1 .. l_columnCount loop\n
      \       dbms_sql.column_value(l_theCursor, i, l_columnValue );\n
      \       dbms_output.put_line(rpad(l_descriptionTable(i).col_name,
      \                                 l_maxColumnLength + 1)
      \                            || ': ' || l_columnValue );\n
      \     end loop;\n
      \   end loop;\n
      \   if l_rowCount = 0 then\n
      \     dbms_output.put_line('no rows found');\n
      \   end if;\n
      \ end;\n
      \ /\n
      \
      \ set feedback on \n
      \ set serveroutput on \n"
let s:oracle_schemes_tables_query = "
      \SELECT /*csv*/ T.owner, T.table_name
      \ FROM (
      \ SELECT owner, table_name
      \ FROM all_tables
      \ UNION SELECT owner, view_name AS \"table_name\"
      \ FROM all_views
      \ ) T
      \ JOIN all_users U ON T.owner = U.username
      \ WHERE U.common = 'NO'
      \ ORDER BY T.table_name"
let s:oracle = {
      \   'callable': 'filter',
      \   'cell_line_number': 1,
      \   'cell_line_pattern': '^-\+\( \+-\+\)*',
      \   'default_scheme': '',
      \   'foreign_key_query': printf(s:oracle_args, s:oracle_foreign_key_query),
      \   'has_virtual_results': v:true,
      \   'layout_flag': '',
      \   'layout_query': s:oracle_toggle_layout_query,
      \   'parse_results': {results, min_len -> s:results_parser(results[3:], '\s\s\+', min_len)},
      \   'parse_virtual_results': {results, min_len -> s:results_parser(results[3:], '\s\s\+', min_len)},
      \   'requires_stdin': v:true,
      \   'quote': v:true,
      \   'schemes_query': printf(s:oracle_args, "SELECT /*csv*/ username FROM all_users WHERE common = 'NO' ORDER BY username"),
      \   'schemes_tables_query': printf(s:oracle_args, s:oracle_schemes_tables_query),
      \   'select_foreign_key_query': printf(s:oracle_args, 'SELECT /*csv*/ * FROM "%s"."%s" WHERE "%s" = %s'),
      \   'filetype': 'plsql',
      \ }

if get(g:, 'dbext_default_ORA_bin', '') == 'sql'
  let s:oracle.parse_results = {results, min_len -> s:results_parser(s:strip_quotes(results[3:]), ',', min_len)}
  let s:oracle.parse_virtual_results = {results, min_len -> s:results_parser(s:strip_quotes(results[3:]), ',', min_len)}
endif

if !exists('g:db_adapter_bigquery_region')
  let g:db_adapter_bigquery_region = 'region-us'
endif

let s:bigquery_schemas_query = printf("
      \ SELECT schema_name FROM `%s`.INFORMATION_SCHEMA.SCHEMATA
      \ ", g:db_adapter_bigquery_region)

let s:bigquery_schema_tables_query = printf("
      \ SELECT table_schema, table_name
      \ FROM `%s`.INFORMATION_SCHEMA.TABLES
      \ ", g:db_adapter_bigquery_region)

let s:bigquery = {
      \ 'callable': 'filter',
      \ 'args': ['--format=csv'],
      \ 'schemes_query': s:bigquery_schemas_query,
      \ 'schemes_tables_query': s:bigquery_schema_tables_query,
      \ 'parse_results': {results, min_len -> s:results_parser(results[1:], ',', min_len)},
      \ 'layout_flag': '\\x',
      \ 'requires_stdin': v:true,
      \ }


let s:schemas = {
      \ 'postgres': s:postgresql,
      \ 'postgresql': s:postgresql,
      \ 'sqlserver': s:sqlserver,
      \ 'mysql': s:mysql,
      \ 'oracle': s:oracle,
      \ 'bigquery': s:bigquery,
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

function! s:format_query(db, scheme, query) abort
  let conn = type(a:db) == v:t_string ? a:db : a:db.conn
  let callable = get(a:scheme, 'callable', 'interactive')
  let cmd = db#adapter#dispatch(conn, callable) + get(a:scheme, 'args', [])
  if get(a:scheme, 'requires_stdin', v:false)
    return [cmd, a:query]
  endif
  return [cmd + [a:query], '']
endfunction

function! db_ui#schemas#query(db, scheme, query) abort
  let result = call('db#systemlist', s:format_query(a:db, a:scheme, a:query))
  return map(result, {_, val -> substitute(val, "\r$", "", "")})
endfunction
