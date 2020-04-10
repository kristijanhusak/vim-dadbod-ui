let s:basic_constraint_query = "
      \ SELECT tc.constraint_name, tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name\n
      \ FROM\n
      \     information_schema.table_constraints AS tc\n
      \     JOIN information_schema.key_column_usage AS kcu\n
      \       ON tc.constraint_name = kcu.constraint_name\n
      \     JOIN information_schema.constraint_column_usage AS ccu\n
      \       ON ccu.constraint_name = tc.constraint_name\n"

let s:postgres = {
      \ 'List': g:dbui_default_query,
      \ 'Columns': "select * from information_schema.columns where table_name='{table}'",
      \ 'Indexes': "SELECT * FROM pg_indexes where tablename='{table}'",
      \ 'Foreign Keys': s:basic_constraint_query."WHERE constraint_type = 'FOREIGN KEY'\nand tc.table_name = '{table}'",
      \ 'References': s:basic_constraint_query."WHERE constraint_type = 'FOREIGN KEY'\nand ccu.table_name = '{table}'",
      \ 'Primary Keys': s:basic_constraint_query."WHERE constraint_type = 'PRIMARY KEY'\nand tc.table_name = '{table}'",
      \ }

let s:sqlite = {
      \ 'List': g:dbui_default_query,
      \ 'Indexes': "SELECT * FROM pragma_index_list('{table}')",
      \ 'Foreign Keys': "SELECT * FROM pragma_foreign_key_list('{table}')",
      \ 'Primary Keys': "SELECT * FROM pragma_index_list('{table}') WHERE origin = 'pk'"
      \ }

let s:mysql = {
      \ 'List': 'SELECT * from {table} LIMIT 200',
      \ 'Indexes': 'SHOW INDEXES FROM {table}',
      \ 'Foreign Keys': "SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = '{dbname}' AND TABLE_NAME = '{table}' AND CONSTRAINT_TYPE = 'FOREIGN KEY'",
      \ 'Primary Keys': "SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = '{dbname}' AND TABLE_NAME = '{table}' AND CONSTRAINT_TYPE = 'PRIMARY KEY'",
      \ }

let s:helpers = {
      \ 'postgresql': s:postgres,
      \ 'mysql': s:mysql,
      \ 'oracle': { 'List': g:dbui_default_query },
      \ 'sqlite': s:sqlite,
      \ 'sqlserver': { 'List': 'SELECT TOP 200 * from {table}' },
      \ 'mongodb': { 'List': 'db.{table}.find()'},
      \  }

let s:all = {}

for scheme in db#adapter#schemes()
  let s:all[scheme] = get(s:helpers, scheme, {})
endfor

let s:all.postgres = s:all.postgresql
let s:all.sqlite3 = s:all.sqlite

function db_ui#table_helpers#get(scheme) abort
  return extend(get(s:all, a:scheme, { 'List': '' }), get(g:dbui_table_helpers, a:scheme, {}))
endfunction
