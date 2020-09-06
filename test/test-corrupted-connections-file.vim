let s:suite = themis#suite('Handle corrupted connections file')
let s:expect = themis#helper('expect')

function s:suite.before() abort
  call writefile(['{}'], g:db_ui_save_location.'/connections.json')
endfunction

function s:suite.after() abort
  call delete(g:db_ui_save_location.'/connections.json')
  call Cleanup()
endfunction

function! s:suite.should_show_error_for_corrupted_file_and_continue()
  :DBUI
  call s:expect(db_ui#notifications#get_last_msg()).to_match('^Error reading connections file.')
endfunction

