let s:suite = themis#suite('Jump to sibling/node')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_jump_to_first_last_sibling() abort
  :DBUI
  norm oj
  call s:expect(line('.')).to_equal(2)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(4)
  exe "norm \<C-k>"
  call s:expect(line('.')).to_equal(2)
  norm 2jojo
  call s:expect(line('.')).to_equal(5)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(10)
  exe "norm \<C-k>"
  call s:expect(line('.')).to_equal(5)
  norm j
  call s:expect(line('.')).to_equal(6)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(9)
  exe "norm \<C-k>"
  call s:expect(line('.')).to_equal(6)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(9)
endfunction

function! s:suite.should_jump_to_parent_child_node()
  exe "norm \<C-p>"
  call s:expect(line('.')).to_equal(5)
  exe "norm \<C-p>"
  call s:expect(line('.')).to_equal(4)
  exe "norm \<C-p>"
  call s:expect(line('.')).to_equal(1)

  exe "norm \<C-n>"
  call s:expect(line('.')).to_equal(2)
  exe "norm \<C-n>"
  call s:expect(line('.')).to_equal(2)
  norm 2jo
  call s:expect(line('.')).to_equal(4)
  call s:expect(getline('.')).to_equal('  ▸ Tables (2)')
  exe "norm \<C-n>"
  call s:expect(line('.')).to_equal(5)
  call s:expect(getline(4)).to_equal('  ▾ Tables (2)')
  exe "norm \<C-n>"
  call s:expect(line('.')).to_equal(6)
endfunction

function! s:suite.should_jump_to_prev_next_sibling()
  norm k
  call s:expect(line('.')).to_equal(5)
  norm J
  call s:expect(line('.')).to_equal(10)
  norm K
  call s:expect(line('.')).to_equal(5)
endfunction
