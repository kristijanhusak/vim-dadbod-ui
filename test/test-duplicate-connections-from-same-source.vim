let s:suite = themis#suite('Connections')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  let g:dbs = [
        \ {'name': 'db-ui-database', 'url': 'sqlite:test/dadbod_ui_test.db'},
        \ {'name': 'db-ui-database', 'url': 'sqlite:test/dadbod_ui_test.db'},
        \ ]
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_return_error_on_duplicate_connnections_from_same_source() abort
  :DBUI
  call s:expect(db_ui#notifications#get_last_msg()).to_equal('Warning: Duplicate connection name "db-ui-database" in "g:dbs" source. First one added has precedence.')
endfunction
