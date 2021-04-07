let s:suite = themis#suite('Open query')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  " Sleep 1 sec to avoid overlapping temp names
  sleep 1
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_open_new_query_buffer() abort
  :DBUI
  norm ojo
  call s:expect(&filetype).to_equal('sql')
  call s:expect(getline(1)).to_be_empty()
endfunction

function! s:suite.should_open_contacts_table_list_query() abort
  :DBUI
  norm 4jojojo
  call s:expect(getline(1)).to_equal('SELECT * from "contacts" LIMIT 200;')
  call s:expect(db_ui#statusline()).to_equal('DBUI: dadbod_ui_test -> contacts')
  call s:expect(db_ui#statusline({'prefix': ''})).to_equal('dadbod_ui_test -> contacts')
  call s:expect(db_ui#statusline({'prefix': '', 'separator': ' / '})).to_equal('dadbod_ui_test / contacts')
  call s:expect(db_ui#statusline({'prefix': '', 'show': ['db_name'] })).to_equal('dadbod_ui_test')
  call s:expect(b:dbui_table_name).to_equal('contacts')
endfunction

function! s:suite.should_write_query() abort
  write
  call s:expect(bufname('.dbout')).not.to_be_empty()
  call s:expect(getwinvar(bufwinnr('.dbout'), '&previewwindow')).to_equal(1)
  pclose
  :DBUI
  norm G
  call s:expect(getline('.')).to_equal(g:db_ui_icons.collapsed.saved_queries.' Query results (1)')
  norm o
  call s:expect(getline('.')).to_equal(g:db_ui_icons.expanded.saved_queries.' Query results (1)')
  norm j
  call s:expect(getline('.')).to_match('\'.g:db_ui_icons.tables.' \d\+\.dbout')
  call s:expect(bufwinnr('.dbout')).to_equal(-1)
  norm o
  call s:expect(bufwinnr('.dbout')).to_be_greater_than(-1)
endfunction
