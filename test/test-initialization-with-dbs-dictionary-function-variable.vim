let s:suite = themis#suite('Initialization with g:dbs variable as functions in a dictionary')
let s:expect = themis#helper('expect')

function! s:db_conn() abort
  return 'sqlite:test/dadbod_ui_test.db'
endfunction

function! s:suite.before() abort
  call SetupTestDbs()
  let g:dbs = {
        \ 'dadbod_gdb_test_fn': function('s:db_conn'),
        \ 'dadbod_gdb_test_string': 'sqlite:test/dadbod_ui_test',
        \ }
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_read_global_dbs_variable() abort
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_gdb_test_string'))
  call s:expect(getline(2)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_gdb_test_fn'))
  norm jo
  call s:expect(getline(1, '$')).to_equal([
        \ '▸ dadbod_gdb_test_string',
        \ '▾ dadbod_gdb_test_fn '.g:db_ui_icons.connection_ok,
        \ '  + New query',
        \ '  ▸ Saved queries (0)',
        \ '  ▸ Tables (2)',
        \ ])
endfunction
