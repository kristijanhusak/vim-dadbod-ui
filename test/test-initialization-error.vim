let s:suite = themis#suite('Initialization error')
let s:expect = themis#helper('expect')

function! s:suite.should_return_error_on_no_connnections() abort
  let g:db_ui_messages = []
  :redir => g:db_ui_messages
  :DBUI
  :redir END
  call s:expect(get(filter(split(g:db_ui_messages, "\n"), '!empty(v:val)'), 0)).to_equal(
        \ '[DBUI] No databases found. use :DBUIAddConnection command to add a new connection or define the g:dbs variable, a $DBUI_URL env variable or use the prefix DB_UI_ in your .env file.')
endfunction
