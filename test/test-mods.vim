let s:suite = themis#suite('Test mods')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_open_in_new_tab() abort
  call s:expect(tabpagenr('$')).to_equal(1)
  :tab DBUI
  call s:expect(tabpagenr('$')).to_equal(2)
  call s:expect(tabpagenr()).to_equal(2)
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_ui_test'))
  call s:expect(getline(2)).to_equal(printf('%s %s', g:db_ui_icons.collapsed.db, 'dadbod_ui_testing'))
endfunction
