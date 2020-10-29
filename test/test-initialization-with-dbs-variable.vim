let s:suite = themis#suite('Initialization with g:dbs variable')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  let g:db = 'sqlite:test/dadbod_gdb_test'
endfunction

function! s:suite.after() abort
  unlet g:db
  call Cleanup()
endfunction

function! s:suite.should_read_global_dbs_variable() abort
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_gdb_test'))
  call s:expect(getline(2)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_ui_test'))
  call s:expect(getline(3)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_ui_testing'))
endfunction
