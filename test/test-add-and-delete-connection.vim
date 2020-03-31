let s:suite = themis#suite('Add/Delete connection')
let s:expect = themis#helper('expect')

function s:suite.after() abort
  call delete(g:db_ui_save_location.'/connections.json')
  call Cleanup()
endfunction

function! s:suite.should_prompt_to_enter_url_for_new_connection()
  let g:test_connection_name = 'connection-file-db'
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Enter connection url: '
      return 'sqlite:test/dadbod_ui_test.db'
    endif

    if a:name ==? 'Enter name: '
      return g:test_connection_name
    endif
  endfunction

  call s:expect(&filetype).not.to_equal('dbui')
  :DBUIAddConnection
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1, '$')).to_equal(['▸ connection-file-db'])
  let g:test_connection_name = 'connection-second-db'
  norm A
  call s:expect(getline(1, '$')).to_equal(['▸ connection-file-db', '▸ connection-second-db'])
endfunction

function! s:suite.should_delete_connection() abort
  norm jd
  call s:expect(getline(1, '$')).to_equal(['▸ connection-file-db'])
endfunction

