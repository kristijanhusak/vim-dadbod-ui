let s:suite = themis#suite('Initialization with custom environment variable')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetOptionVariable('db_ui_env_variable_url', 'DATABASE_URL')
  let $DATABASE_URL = 'sqlite:test/dadbod_ui_test.db'
endfunction

function! s:suite.after() abort
  call UnsetOptionVariable('db_ui_env_variable_url')
  unlet $DATABASE_URL
  call Cleanup()
endfunction

function! s:suite.should_read_env_variable() abort
  :DBUI
  cal s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_ui_test.db'))
endfunction
