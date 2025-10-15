let s:suite = themis#suite('Drawer sections')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_show_default_sections() abort
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  normal o
  call s:expect(getline(1, '$')).to_equal([
        \ '▾ dadbod_ui_test '.g:db_ui_icons.connection_ok,
        \ '  + New query',
        \ '  ▸ Saved queries (0)',
        \ '  ▸ Tables (2)',
        \ '▸ dadbod_ui_testing',
        \ ])
  normal o
endfunction

function! s:suite.should_show_only_schemas_section() abort
  call SetOptionVariable('db_ui_drawer_sections', ['schemas'])
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  normal o
  call s:expect(getline(1, '$')).to_equal([
        \ '▾ dadbod_ui_test '.g:db_ui_icons.connection_ok,
        \ '  ▸ Tables (2)',
        \ '▸ dadbod_ui_testing',
        \ ])
  normal o
  call UnsetOptionVariable('db_ui_drawer_sections')
endfunction

function! s:suite.should_show_only_saved_queries_section() abort
  call SetOptionVariable('db_ui_drawer_sections', ['saved_queries'])
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  normal o
  call s:expect(getline(1, '$')).to_equal([
        \ '▾ dadbod_ui_test '.g:db_ui_icons.connection_ok,
        \ '  ▸ Saved queries (0)',
        \ '▸ dadbod_ui_testing',
        \ ])
  normal o
  call UnsetOptionVariable('db_ui_drawer_sections')
endfunction

function! s:suite.should_show_only_new_query_section() abort
  call SetOptionVariable('db_ui_drawer_sections', ['new_query'])
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  normal o
  call s:expect(getline(1, '$')).to_equal([
        \ '▾ dadbod_ui_test '.g:db_ui_icons.connection_ok,
        \ '  + New query',
        \ '▸ dadbod_ui_testing',
        \ ])
  normal o
  call UnsetOptionVariable('db_ui_drawer_sections')
endfunction

function! s:suite.should_show_custom_section_order() abort
  call SetOptionVariable('db_ui_drawer_sections', ['schemas', 'new_query', 'saved_queries'])
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  normal o
  call s:expect(getline(1, '$')).to_equal([
        \ '▾ dadbod_ui_test '.g:db_ui_icons.connection_ok,
        \ '  ▸ Tables (2)',
        \ '  + New query',
        \ '  ▸ Saved queries (0)',
        \ '▸ dadbod_ui_testing',
        \ ])
  normal o
  call UnsetOptionVariable('db_ui_drawer_sections')
endfunction
