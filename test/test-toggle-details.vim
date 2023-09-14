let s:suite = themis#suite('Toggle details')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_show_details() abort
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1, '$')).to_equal([
        \ '▸ dadbod_ui_test',
        \ '▸ dadbod_ui_testing',
        \ ])
  norm H
  call s:expect(getline(1, '$')).to_equal([
        \ '▸ dadbod_ui_test (sqlite - g:dbs)',
        \ '▸ dadbod_ui_testing (sqlite - g:dbs)',
        \ ])
  norm H
  call s:expect(getline(1, '$')).to_equal([
        \ '▸ dadbod_ui_test',
        \ '▸ dadbod_ui_testing',
        \ ])
endfunction
