let s:suite = themis#suite('Grouped Connections')
let s:expect = themis#helper('expect')

let s:connections_file = g:db_ui_save_location.'/connections.json'

function s:suite.after() abort
  call delete(s:connections_file)
  call Cleanup()
endfunction

function! s:suite.should_create_groups_and_connections() abort
  let g:test_connection_name = '/group/connection-first-db'
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Enter connection url: '
      return 'sqlite:test/dadbod_ui_test.db'
    endif

    if a:name ==? 'Enter name: '
      return g:test_connection_name
    endif
  endfunction

  :DBUI
  norm A
  call s:expect(getline(1, '$')).to_equal(['▸ group'])
  norm o
  call s:expect(getline(1, '$')).to_equal(['▾ group', '  ▸ connection-first-db'])
  let g:test_connection_name = '/group/nested-group/connection-second-db'
  norm A
  call s:expect(getline(1, '$')).to_equal(['▾ group', '  ▸ connection-first-db', '  ▸ nested-group'])
endfunction

function! s:suite.should_allow_renaming_groups_and_connections() abort
  let g:test_group_name = 'edited-group-name'
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Edit group name: '
      return g:test_group_name
    endif

    if a:name =~? 'Edit connection url'
      return 'sqlite:test/dadbod_ui_test_new.db'
    endif

    if a:name ==? 'Edit connection name: '
      return 'edited-db-name'
    endif
  endfunction
  :DBUI
  norm r
  call s:expect(getline(1, '$')).to_equal(['▸ edited-group-name'])
  norm ojr
  let g:test_group_name = 'edited-nested-group-name'
  norm jr
  call s:expect(getline(1, '$')).to_equal(['▾ edited-group-name', '  ▸ edited-db-name', '  ▸ edited-nested-group-name'])
endfunction

function! s:suite.should_delete_group_and_connection() abort
  norm d
  call s:expect(getline(1, '$')).to_equal(['▾ edited-group-name', '  ▸ edited-db-name'])
  norm d
  " Empty group is not shown
  call s:expect(getline(1, '$')).to_equal(['" No connections', '[+] Add connection'])
endfunction
