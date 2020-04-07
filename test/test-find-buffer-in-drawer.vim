let s:suite = themis#suite('Find buffer')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_find_buffer_in_dbui_drawer() abort
  :DBUI
  norm o3jojojo
  call s:expect(getline(1)).to_equal('SELECT * from "contacts" LIMIT 200;')
  let bufnr = bufnr('')
  :DBUI
  norm jo
  exe 'b'.bufnr
  :DBUI
  call s:expect(getline('.')).to_equal(g:dbui_icons.expanded.' dadbod_ui_test')
  wincmd p
  :DBUIFindBuffer
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline('.')).to_equal('    '.g:dbui_icons.buffers.' contacts-List *')
endfunction
