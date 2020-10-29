let s:suite = themis#suite('Save query to file')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function s:suite.after() abort
  call delete(g:db_ui_save_location.'/dadbod_ui_test', 'rf')
  call Cleanup()
endfunction

function! s:suite.should_save_query_to_file()
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Save as: '
      return 'test-saved-query'
    endif
  endfunction

  :DBUI
  normal o3jojojo
  call s:expect(&filetype).to_equal('sql')
  call s:expect(getline(1)).to_equal('SELECT * from "contacts" LIMIT 200;')
  normal ,W
  :DBUI
  /Saved queries
  norm oj
  call s:expect(getline('.')).to_equal('    '.g:db_ui_icons.saved_query.' test-saved-query')
  call s:expect(filereadable(printf('%s/%s/%s', g:db_ui_save_location, 'dadbod_ui_test', 'test-saved-query'))).to_be_true()
endfunction

function! s:suite.should_delete_saved_query() abort
  norm gg6jd
  call s:expect(search('test-saved-query')).to_equal(0)
  call s:expect(filereadable(printf('%s/%s/%s', g:db_ui_save_location, 'dadbod_ui_test', 'test-saved-query'))).to_be_false()
endfunction
