let s:suite = themis#suite('Initialization with g:dbs and env variable')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  let $DBUI_URL = 'sqlite:test/dadbod_ui_test.db'
  let $DBUI_NAME = 'dbui_test'
  let g:dbs = {'dbui_testing': 'sqlite:test/dadbod_ui_test.db'}
endfunction

function! s:suite.after() abort
  unlet $DBUI_URL
  unlet $DBUI_NAME
  call Cleanup()
endfunction

function! s:suite.should_read_both_env_and_global_dbs_variable()
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dbui_test'))
  call s:expect(getline(2)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dbui_testing'))
endfunction
