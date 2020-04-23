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
  let g:db_ui_messages = []
  :redir => g:db_ui_connection_msg
  :DBUI
  :redir END
  call s:expect(get(filter(split(g:db_ui_connection_msg, "\n"), '!empty(v:val)'), 0)).to_equal(
        \ '[DBUI] Error reading connections file.')
endfunction

