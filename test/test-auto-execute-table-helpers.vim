let s:suite = themis#suite('Auto execute table helpers')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  call SetOptionVariable('db_ui_auto_execute_table_helpers', 1)
endfunction

function! s:suite.after() abort
  call UnsetOptionVariable('db_ui_auto_execute_table_helpers')
  call UnsetOptionVariable('db_ui_execute_on_save')
  call Cleanup()
endfunction

function! s:suite.should_open_contacts_table_list_query() abort
  :DBUI
  norm o3jojojo
  let out_name = bufname('.dbout')
  call s:expect(out_name).not.to_be_empty()
  call s:expect(getwinvar(bufwinnr('.dbout'), '&previewwindow')).to_equal(1)
  exe 'bw! '.out_name
endfunction

function! s:suite.should_trigger_auto_execute_when_execute_on_save_is_disabled() abort
  call SetOptionVariable('db_ui_execute_on_save', 0)
  bw!
  :DBUI
  /List
  norm o
  call s:expect(bufname('.dbout')).not.to_be_empty()
  call s:expect(getwinvar(bufwinnr('.dbout'), '&previewwindow')).to_equal(1)
endfunction
