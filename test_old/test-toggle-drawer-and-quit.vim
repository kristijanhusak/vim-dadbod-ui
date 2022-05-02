let s:suite = themis#suite('Test toggle drawer and quit')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_toggle_drawer() abort
  :DBUIToggle
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1, '$')).to_equal([
        \ '▸ dadbod_ui_test',
        \ '▸ dadbod_ui_testing',
        \ ])
  :DBUIToggle
  call s:expect(bufwinnr('dbui')).to_equal(-1)
endfunction

function! s:suite.should_quit_drawer() abort
  :DBUIToggle
  call s:expect(&filetype).to_equal('dbui')
  norm q
  call s:expect(bufwinnr('dbui')).to_equal(-1)
endfunction
