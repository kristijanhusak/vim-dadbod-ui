let s:suite = themis#suite('Jump to sibling/node')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
  call SetOptionVariable('db_ui_table_helpers', {
        \ 'sqlite': { 'List': 'SELECT * FROM {table}', 'Count': 'select count(*) from {table}', 'Explain': 'EXPLAIN ANALYZE {last_query}' }
        \ })
endfunction

function! s:suite.after() abort
  call SetOptionVariable('db_ui_table_helpers', {'sqlite': {'List': g:db_ui_default_query }})
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
  call s:expect(line('.')).to_equal(13)
  exe "norm \<C-k>"
  call s:expect(line('.')).to_equal(5)
  norm j
  call s:expect(line('.')).to_equal(6)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(12)
  exe "norm \<C-k>"
  call s:expect(line('.')).to_equal(6)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(12)
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
  call s:expect(line('.')).to_equal(13)
  norm K
  call s:expect(line('.')).to_equal(5)
endfunction

function! s:suite.should_jump_to_last_line()
  norm! gg
  norm J
  call s:expect(line('.')).to_equal(14)
  norm oj
  call s:expect(line('.')).to_equal(15)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(17)
  exe "norm \<C-k>"
  call s:expect(line('.')).to_equal(15)
  exe "norm \<C-j>"
  call s:expect(line('.')).to_equal(17)
endfunction
