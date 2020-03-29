let s:suite = themis#suite('Test initialization with g:dbs variable')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_read_global_dbs_variable() abort
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal(printf('%s %s', g:dbui_icons.collapsed, 'dadbod_ui_test'))
endfunction
