let s:suite = themis#suite('Initialization no connections')
let s:expect = themis#helper('expect')

function! s:suite.after() abort
  call delete(g:db_ui_save_location.'/connections.json')
  call Cleanup()
endfunction

function! s:suite.should_open_empty_dbui_with_button_to_add_connection() abort
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal('" No connections')
  call s:expect(getline(2)).to_equal(g:db_ui_icons.add_connection.' Add connection')
endfunction

function! s:suite.should_add_connection_from_empty_dbui_drawer() abort
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Enter connection url: '
      return 'sqlite:test/dadbod_ui_test.db'
    endif

    if a:name ==? 'Enter name: '
      return 'test-add-from-empty'
    endif
  endfunction

  norm jo
  call s:expect(getline(1)).to_equal(g:db_ui_icons.collapsed.db.' test-add-from-empty')
endfunction
