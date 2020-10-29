let s:suite = themis#suite('Delete buffer')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_delete_buffer()
  :DBUI
  norm ojo
  :DBUI
  call s:expect(search('Buffers', 'w')).to_be_greater_than(0)
  call s:expect(search(g:db_ui_icons.buffers.' query', 'w')).to_be_greater_than(0)
  norm d
  call s:expect(search('Buffers', 'w')).to_equal(0)
  call s:expect(search(g:db_ui_icons.buffers.' query', 'w')).to_equal(0)
endfunction
