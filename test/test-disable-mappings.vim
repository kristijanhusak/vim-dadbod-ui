let s:suite = themis#suite('Disable mappings')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetOptionVariable('db_ui_disable_mappings', 1)
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call UnsetOptionVariable('db_ui_disable_mappings')
  call Cleanup()
endfunction

function! s:suite.should_not_map_o() abort
  :DBUI
  try
    norm o
  catch /.*/
    call s:expect(v:exception).to_equal('Vim(normal):E21: Cannot make changes, ''modifiable'' is off')
  endtry
  call s:expect(getline(1, '$')).to_equal([
        \ '▸ dadbod_ui_test',
        \ '▸ dadbod_ui_testing',
        \ ])
endfunction
