let s:suite = themis#suite('Rename buffer and saved query')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  " Sleep 1 sec to avoid overlapping temp names
  sleep 1
endfunction

function s:suite.after() abort
  call delete(g:db_ui_save_location.'/dadbod_ui_test', 'rf')
  call Cleanup()
endfunction

function! s:suite.should_rename_buffer() abort
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(name, val)
    return 'custom-buffer-name'
  endfunction

  :DBUI
  normal ojo
  call s:expect(&filetype).to_equal('sql')
  call setline(1, ['select * from contacts'])
  write
  :DBUIFindBuffer
  wincmd p
  normal r
  call s:expect(getline('.')).to_equal('    '.g:db_ui_icons.buffers.' custom-buffer-name *')
endfunction

function! s:suite.should_rename_saved_query() abort
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Save as: '
      return 'saved_query.sql'
    endif
    if a:name ==? 'Enter new name: '
      return 'new_query_name.sql'
    endif
  endfunction
  normal o
  normal ,W
  call s:expect(filereadable(printf('%s/%s/%s', g:db_ui_save_location, 'dadbod_ui_test', 'saved_query.sql'))).to_be_true()
  :DBUI
  /Saved queries
  norm oj
  normal r
  call s:expect(filereadable(printf('%s/%s/%s', g:db_ui_save_location, 'dadbod_ui_test', 'new_query_name.sql'))).to_be_true()
  call s:expect(filereadable(printf('%s/%s/%s', g:db_ui_save_location, 'dadbod_ui_test', 'saved_query.sql'))).to_be_false()
  call s:expect(search('new_query_name.sql')).to_be_greater_than(0)
endfunction

function! s:suite.should_rename_current_buffer() abort
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Enter new name: '
      return 'from-command'
    endif
  endfunction
  /custom-buffer-name
  norm o
  :DBUIRenameBuffer
  call s:expect(match(bufname('%'), 'from-command')).to_be_greater_than(0)
  :DBUI
  call s:expect(search('from-command')).to_be_greater_than(0)
endfunction
