let s:suite = themis#suite('Test db navigation')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_open_dbui() abort
  DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1, '$')).to_equal([
        \ '▸ dadbod_ui_test',
        \ '▸ dadbod_ui_testing',
        \ ])
endfunction

function! s:suite.should_open_db_navigation() abort
  normal o
  call s:expect(getline(1, '$')).to_equal([
        \ '▾ dadbod_ui_test',
        \ '  + New query',
        \ '  ▸ Saved sql (0)',
        \ '  ▸ Tables (2)',
        \ '▸ dadbod_ui_testing',
        \ ])
endfunction
