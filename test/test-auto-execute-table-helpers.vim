let s:suite = themis#suite('Auto execute table helpers')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  call SetOptionVariable('db_ui_auto_execute_table_helpers', 1)
endfunction

function! s:suite.after() abort
  call UnsetOptionVariable('db_ui_auto_execute_table_helpers')
  call Cleanup()
endfunction

function! s:suite.should_open_contacts_table_list_query() abort
  :DBUI
  norm o3jojojo
  call s:expect(bufname('.dbout')).not.to_be_empty()
  call s:expect(getwinvar(bufwinnr('.dbout'), '&previewwindow')).to_equal(1)
endfunction
