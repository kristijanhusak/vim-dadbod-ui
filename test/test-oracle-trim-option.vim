let s:suite = themis#suite('Oracle trim option')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_have_default_trim_value() abort
  call s:expect(g:db_ui_trim).to_equal(25)
endfunction

function! s:suite.should_use_custom_trim_value() abort
  call SetOptionVariable('db_ui_trim', 30)
  call s:expect(g:db_ui_trim).to_equal(30)
  call UnsetOptionVariable('db_ui_trim')
endfunction

function! s:suite.should_reset_to_default_trim_value() abort
  call SetOptionVariable('db_ui_trim', 20)
  call UnsetOptionVariable('db_ui_trim')
  call s:expect(g:db_ui_trim).to_equal(25)
endfunction
