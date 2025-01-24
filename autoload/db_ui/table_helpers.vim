let s:basic_foreign_key_query = "
      \SELECT tc.constraint_name, tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name, rc.update_rule, rc.delete_rule\n
      \FROM\n
      \     information_schema.table_constraints AS tc\n
      \     JOIN information_schema.key_column_usage AS kcu\n
      \       ON tc.constraint_name = kcu.constraint_name\n
      \     JOIN information_schema.referential_constraints as rc\n
      \       ON tc.constraint_name = rc.constraint_name\n
      \     JOIN information_schema.constraint_column_usage AS ccu\n
      \       ON ccu.constraint_name = tc.constraint_name\n"

let s:bigquery = {
      \ 'List': 'select * from {optional_schema}{table} LIMIT 200',
      \ 'Columns': "select * from {schema}.INFORMATION_SCHEMA.COLUMNS where table_name='{table}'",
      \ }


let s:postgres = {
      \ 'List': 'select * from {optional_schema}"{table}" LIMIT 200',
      \ 'Columns': "select * from information_schema.columns where table_name='{table}' and table_schema='{schema}'",
      \ 'Indexes': "SELECT * FROM pg_indexes where tablename='{table}' and schemaname='{schema}'",
      \ 'Foreign Keys': s:basic_foreign_key_query."WHERE constraint_type = 'FOREIGN KEY'\nand tc.table_name = '{table}'\nand tc.table_schema = '{schema}'",
      \ 'References': s:basic_foreign_key_query."WHERE constraint_type = 'FOREIGN KEY'\nand ccu.table_name = '{table}'\nand tc.table_schema = '{schema}'",
      \ 'Primary Keys': "SELECT * FROM information_schema.table_constraints WHERE constraint_type = 'PRIMARY KEY' AND table_schema = '{schema}' AND table_name = '{table}'",
      \ }

let s:sqlite = {
      \ 'List': g:db_ui_default_query,
      \ 'Columns': "SELECT * FROM pragma_table_info('{table}')",
      \ 'Indexes': "SELECT * FROM pragma_index_list('{table}')",
      \ 'Foreign Keys': "SELECT * FROM pragma_foreign_key_list('{table}')",
      \ 'Primary Keys': "SELECT * FROM pragma_index_list('{table}') WHERE origin = 'pk'"
      \ }

let s:mysql = {
      \ 'List': 'SELECT * from {optional_schema}`{table}` LIMIT 200',
      \ 'Columns': 'DESCRIBE {optional_schema}`{table}`',
      \ 'Indexes': 'SHOW INDEXES FROM {optional_schema}`{table}`',
      \ 'Foreign Keys': "SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table}' AND CONSTRAINT_TYPE = 'FOREIGN KEY'",
      \ 'Primary Keys': "SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table}' AND CONSTRAINT_TYPE = 'PRIMARY KEY'",
      \ }

let s:oracle_from = "
      \FROM all_constraints N\n
      \JOIN all_cons_columns L\n\t
      \ON N.constraint_name = L.constraint_name\n\t
      \AND N.owner = L.owner"
let s:oracle_qualify_and_order_by = "
      \L.table_name = '{table}'\n
      \ORDER BY\n\t"
let s:oracle_key_cmd = "
      \SELECT\n\t
      \L.table_name,\n\t
      \L.column_name\n
      \" . s:oracle_from . "\n
      \WHERE\n\t
      \N.constraint_type = '%s'\n\t
      \AND " . s:oracle_qualify_and_order_by . "L.column_name"

let s:oracle = {
      \ 'Columns': 'DESCRIBE "{schema}"."{table}"',
      \ 'Foreign Keys': printf(s:oracle_key_cmd, 'R'),
      \ 'Indexes': "
            \SELECT DISTINCT\n\t
            \N.owner,\n\t
            \N.index_name,\n\t
            \N.constraint_type\n
            \" . s:oracle_from . "\n
            \WHERE\n\t
            \" . s:oracle_qualify_and_order_by . "N.index_name",
      \ 'List': 'SELECT * FROM "{schema}"."{table}"',
      \ 'Primary Keys': printf(s:oracle_key_cmd, 'P'),
      \ 'References': "
            \SELECT\n\t
            \RFRING.owner,\n\t
            \RFRING.table_name,\n\t
            \RFRING.column_name\n
            \FROM all_cons_columns RFRING\n
            \JOIN all_constraints N\n\t
            \ON RFRING.constraint_name = N.constraint_name\n
            \JOIN all_cons_columns RFRD\n\t
            \ON N.r_constraint_name = RFRD.constraint_name\n
            \JOIN all_users U\n\t
            \ON N.owner = U.username\n
            \WHERE\n\t
            \N.constraint_type = 'R'\n
            \AND\n\t
            \U.common = 'NO'\n
            \AND\n\t
            \RFRD.owner = '{schema}'\n
            \AND\n\t
            \RFRD.table_name = '{table}'\n
            \ORDER BY\n\t
            \RFRING.owner,\n\t
            \RFRING.table_name,\n\t
            \RFRING.column_name",
      \ }

for [helper, query] in items(s:oracle)
   let s:oracle[helper] = "
      \SET linesize 4000;\n
      \SET pagesize 4000;\n\n
      \COLUMN column_name FORMAT a20;\n
      \COLUMN constraint_type FORMAT a20;\n
      \COLUMN index_name FORMAT a20;\n
      \COLUMN owner FORMAT a20;\n
      \COLUMN table_name FORMAT a20;\n\n
      \" . query . "\n;"
endfor

let s:sqlserver_column_summary_query = "
      \ select c.column_name + ' (' + \n
      \     isnull(( select 'PK, ' from information_schema.table_constraints as k join information_schema.key_column_usage as kcu on k.constraint_name = kcu.constraint_name where constraint_type='PRIMARY KEY' and k.table_name = c.table_name and kcu.column_name = c.column_name), '') + \n
      \     isnull(( select 'FK, ' from information_schema.table_constraints as k join information_schema.key_column_usage as kcu on k.constraint_name = kcu.constraint_name where constraint_type='FOREIGN KEY' and k.table_name = c.table_name and kcu.column_name = c.column_name), '') + \n
      \     data_type + coalesce('(' + rtrim(cast(character_maximum_length as varchar)) + ')','(' + rtrim(cast(numeric_precision as varchar)) + ',' + rtrim(cast(numeric_scale as varchar)) + ')','(' + rtrim(cast(datetime_precision as varchar)) + ')','') + ', ' + \n
      \     case when is_nullable = 'YES' then 'null' else 'not null' end + ')' as Columns \n
      \ from information_schema.columns c where c.table_name='{table}' and c.TABLE_SCHEMA = '{schema}'"

let s:sqlserver_foreign_keys_query = "
      \ SELECT c.constraint_name  \n
      \    ,kcu.column_name as column_name  \n
      \    ,c2.table_name as foreign_table_name  \n
      \    ,kcu2.column_name as foreign_column_name \n
      \ from   information_schema.table_constraints c  \n
      \        inner join information_schema.key_column_usage kcu  \n
      \          on c.constraint_schema = kcu.constraint_schema  \n
      \             and c.constraint_name = kcu.constraint_name  \n
      \        inner join information_schema.referential_constraints rc  \n
      \          on c.constraint_schema = rc.constraint_schema  \n
      \             and c.constraint_name = rc.constraint_name  \n
      \        inner join information_schema.table_constraints c2  \n
      \          on rc.unique_constraint_schema = c2.constraint_schema  \n
      \             and rc.unique_constraint_name = c2.constraint_name  \n
      \        inner join information_schema.key_column_usage kcu2  \n
      \          on c2.constraint_schema = kcu2.constraint_schema  \n
      \             and c2.constraint_name = kcu2.constraint_name  \n
      \             and kcu.ordinal_position = kcu2.ordinal_position  \n
      \ where  c.constraint_type = 'FOREIGN KEY'  \n
      \ and c.TABLE_NAME = '{table}' and c.TABLE_SCHEMA = '{schema}'"

let s:sqlserver_references_query = "
      \ select kcu1.constraint_name as constraint_name  \n
      \     ,kcu1.table_name as foreign_table_name   \n
      \     ,kcu1.column_name as foreign_column_name  \n
      \     ,kcu2.column_name as column_name  \n
      \ from information_schema.referential_constraints as rc  \n
      \ inner join information_schema.key_column_usage as kcu1  \n
      \     on kcu1.constraint_catalog = rc.constraint_catalog   \n
      \     and kcu1.constraint_schema = rc.constraint_schema  \n
      \     and kcu1.constraint_name = rc.constraint_name  \n
      \ inner join information_schema.key_column_usage as kcu2  \n
      \     on kcu2.constraint_catalog = rc.unique_constraint_catalog   \n
      \     and kcu2.constraint_schema = rc.unique_constraint_schema  \n
      \     and kcu2.constraint_name = rc.unique_constraint_name  \n
      \     and kcu2.ordinal_position = kcu1.ordinal_position  \n
      \ where kcu2.table_name='{table}' and kcu2.table_schema = '{schema}'"

let s:sqlserver_primary_keys = "
      \  select tc.constraint_name, kcu.column_name \n
      \  from \n
      \      information_schema.table_constraints AS tc \n
      \      JOIN information_schema.key_column_usage AS kcu \n
      \        ON tc.constraint_name = kcu.constraint_name \n
      \      JOIN information_schema.constraint_column_usage AS ccu \n
      \        ON ccu.constraint_name = tc.constraint_name \n
      \ where constraint_type = 'PRIMARY KEY' \n
      \ and tc.table_name = '{table}' and tc.table_schema = '{schema}'"

let s:sqlserver_constraints_query = "
      \ SELECT u.CONSTRAINT_NAME, c.CHECK_CLAUSE FROM INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE u \n
      \     inner join INFORMATION_SCHEMA.CHECK_CONSTRAINTS c on u.CONSTRAINT_NAME = c.CONSTRAINT_NAME \n
      \ where TABLE_NAME = '{table}' and u.TABLE_SCHEMA = '{schema}'"

let s:sqlserver = {
      \ 'List': 'select top 200 * from {optional_schema}[{table}]',
      \ 'Columns': s:sqlserver_column_summary_query,
      \ 'Indexes': 'exec sp_helpindex ''{schema}.{table}''',
      \ 'Foreign Keys': s:sqlserver_foreign_keys_query,
      \ 'References': s:sqlserver_references_query,
      \ 'Primary Keys': s:sqlserver_primary_keys,
      \ 'Constraints': s:sqlserver_constraints_query,
      \ 'Describe': 'exec sp_help ''{schema}.{table}''',
\   }

let s:clickhouse = {
      \ 'List': "select * from `{schema}`.`{table}` limit 100 Format PrettyCompactMonoBlock",
      \ 'Columns': "select name from system.columns where database='{schema} and table={table}'",
      \ }

let s:helpers = {
      \ 'bigquery': s:bigquery,
      \ 'postgresql': s:postgres,
      \ 'mysql': s:mysql,
      \ 'mariadb': s:mysql,
      \ 'oracle': s:oracle,
      \ 'sqlite': s:sqlite,
      \ 'sqlserver': s:sqlserver,
      \ 'clickhouse': s:clickhouse,
      \ 'mongodb': { 'List': '{table}.find()'},
      \  }

let s:all = {}

for scheme in db#adapter#schemes()
  let s:all[scheme] = get(s:helpers, scheme, {})
endfor

let s:all.postgres = s:all.postgresql
let s:all.sqlite3 = s:all.sqlite

let s:scheme_map = {
      \ 'postgres': 'postgresql',
      \ 'postgresql': 'postgres',
      \ 'sqlite3': 'sqlite',
      \ 'sqlite': 'sqlite3',
      \ }

function! db_ui#table_helpers#get(scheme) abort
  let result = extend(get(s:all, a:scheme, { 'List': '' }), get(g:db_ui_table_helpers, a:scheme, {}))
  if has_key(s:scheme_map, a:scheme)
    let result = extend(result, get(g:db_ui_table_helpers, s:scheme_map[a:scheme], {}))
  endif

  return result
endfunction
