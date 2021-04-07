let s:suite = themis#suite('Custom icons')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call UnsetOptionVariable('Db_ui_buffer_name_generator')
  call Cleanup()
endfunction

function! s:name_generator(opts)
  if empty(a:opts.table)
    return 'query-from-test-suite-'.localtime().'.'.a:opts.filetype
  endif

  return 'query-from-test-suite-'.a:opts.table.'-'.localtime().'.'.a:opts.filetype
endfunction

function! s:suite.should_use_custom_icons() abort
  :DBUI
  norm ojo
  :DBUI
  call s:expect(getline(4)).to_match('^    '.g:db_ui_icons.buffers.' query-.*$')
  call SetOptionVariable('Db_ui_buffer_name_generator', function('s:name_generator'))
  norm ggjo
  :DBUI
  call s:expect(getline(5)).to_match('^    '.g:db_ui_icons.buffers.' query-from-test-suite-\d\+\.sql\s\*$')
  norm gg6jojojo
  :DBUI
  call s:expect(getline(6)).to_match('^    '.g:db_ui_icons.buffers.' query-from-test-suite-contacts-\d\+\.sql\s\*$')
endfunction
