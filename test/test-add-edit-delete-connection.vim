let s:suite = themis#suite('Add/Delete connection')
let s:expect = themis#helper('expect')

let s:connections_file = g:db_ui_save_location.'/connections.json'

function s:suite.after() abort
  call delete(s:connections_file)
  call Cleanup()
endfunction

function! s:suite.should_prompt_to_enter_url_for_new_connection() abort
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

function! s:suite.should_allow_renaming_connection() abort
  function! db_ui#utils#input(name, val)
    if a:name =~? 'Edit connection url'
      return 'sqlite:test/dadbod_ui_test_new.db'
    endif

    if a:name ==? 'Edit connection name: '
      return 'edited-name'
    endif
  endfunction
  :DBUI
  norm r
  call s:expect(getline(1, '$')).to_equal(['▸ edited-name', '▸ connection-second-db'])
  let file = db_ui#utils#readfile(s:connections_file)
  call s:expect(file).to_equal([
        \ {'url': db_ui#resolve('sqlite:test/dadbod_ui_test_new.db'), 'name': 'edited-name'},
        \ {'url': db_ui#resolve('sqlite:test/dadbod_ui_test.db'), 'name': 'connection-second-db'}
        \ ])
endfunction

function! s:suite.should_delete_connection() abort
  norm jd
  call s:expect(getline(1, '$')).to_equal(['▸ edited-name'])
endfunction

