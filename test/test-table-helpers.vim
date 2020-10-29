let s:suite = themis#suite('Table helpers')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  call SetOptionVariable('db_ui_table_helpers', {
        \ 'sqlite': { 'List': 'SELECT * FROM {table}', 'Count': 'select count(*) from {table}', 'Explain': 'EXPLAIN ANALYZE {last_query}' }
        \ })
endfunction

function! s:suite.after() abort
  call SetOptionVariable('db_ui_table_helpers', {'sqlite': {'List': g:db_ui_default_query }})
  call Cleanup()
endfunction

function! s:suite.should_open_table_list_query_changed() abort
  :DBUI
  normal o3jojojo
  call s:expect(&filetype).to_equal('sql')
  call s:expect(getline(1)).to_equal('SELECT * FROM contacts')
  call s:expect(b:dbui_table_name).to_equal('contacts')
endfunction

function! s:suite.should_open_custom_count_helper() abort
  :DBUI
  /Count
  normal o
  call s:expect(&filetype).to_equal('sql')
  call s:expect(getline(1)).to_equal('select count(*) from contacts')
  write
endfunction

function! s:suite.should_open_custom_explain_helper_with_last_query_injected() abort
  :DBUI
  /Explain
  normal o
  call s:expect(&filetype).to_equal('sql')
  call s:expect(getline(1)).to_equal('EXPLAIN ANALYZE select count(*) from contacts')
endfunction
