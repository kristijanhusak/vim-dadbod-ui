let s:suite = themis#suite('Custom icons')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  call SetOptionVariable('db_ui_icons', { 'expanded': '[-]', 'collapsed': '[+]' })
endfunction

function! s:suite.after() abort
  call UnsetOptionVariable('db_ui_icons')
  call Cleanup()
endfunction

function! s:suite.should_use_custom_icons() abort
  :DBUI
  call s:expect(getline(1, '$')).to_equal([
        \ '[+] dadbod_ui_test',
        \ '[+] dadbod_ui_testing',
        \ ])
endfunction
