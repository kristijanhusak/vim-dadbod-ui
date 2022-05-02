let s:suite = themis#suite('Initialization with env variable')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  let $DBUI_URL = 'sqlite:test/dadbod_ui_test.db'
endfunction

function! s:suite.after() abort
  unlet $DBUI_URL
  call Cleanup()
endfunction

function! s:suite.should_read_env_variable_and_parse_name_from_connection()
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_ui_test.db'))
endfunction
