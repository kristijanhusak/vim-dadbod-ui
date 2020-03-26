let s:basic_constraint_query = "
      \ SELECT tc.constraint_name, tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name\n
      \ FROM\n
      \     information_schema.table_constraints AS tc\n
      \     JOIN information_schema.key_column_usage AS kcu\n
      \       ON tc.constraint_name = kcu.constraint_name\n
      \     JOIN information_schema.constraint_column_usage AS ccu\n
      \       ON ccu.constraint_name = tc.constraint_name\n"
let s:postgres = {
      \ 'List': g:db_ui_default_query,
      \ 'Indexes': "SELECT * FROM pg_indexes where tablename='{table}'",
      \ 'Foreign Keys': s:basic_constraint_query."WHERE constraint_type = 'FOREIGN KEY'\nand tc.table_name = '{table}'",
      \ 'References': s:basic_constraint_query."WHERE constraint_type = 'FOREIGN KEY'\nand ccu.table_name = '{table}'",
      \ 'Primary Keys': s:basic_constraint_query."WHERE constraint_type = 'PRIMARY KEY'\nand tc.table_name = '{table}'",
      \ }

let s:helpers = {
      \ 'postgresql': extend(s:postgres, get(g:db_ui_table_helpers, 'postgres', {})),
      \ 'mysql': extend({ 'List': g:db_ui_default_query }, get(g:db_ui_table_helpers, 'mysql', {})),
      \ 'oracle': extend({ 'List': g:db_ui_default_query }, get(g:db_ui_table_helpers, 'oracle', {})),
      \ 'sqlite': extend({ 'List': g:db_ui_default_query }, get(g:db_ui_table_helpers, 'sqlite', {})),
      \ 'sqlserver': extend({ 'List': g:db_ui_default_query }, get(g:db_ui_table_helpers, 'sqlserver', {})),
      \ 'mongodb': extend({ 'List': 'db.{table}.find()'}, get(g:db_ui_table_helpers, 'mongodb', {})),
      \  }

let s:all = {}

for scheme in db#adapter#schemes()
  let s:all[scheme] = get(s:helpers, scheme, { 'List': '' })
endfor

let s:all.postgres = s:all.postgresql
let s:all.sqlite3 = s:all.sqlite

function db_ui#table_helpers#get(scheme) abort
  return get(s:all, a:scheme, {'List': '' })
endfunction
