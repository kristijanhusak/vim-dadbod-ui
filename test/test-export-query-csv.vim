let s:suite = themis#suite('Export query CSV')
let s:expect = themis#helper('expect')
let s:csv_file = tempname().'.csv'

function! s:suite.before() abort
  call SetOptionVariable('db_ui_export_csv_strip_limit', 0)
  call SetupTestDbs()
  sleep 1
endfunction

function! s:suite.after() abort
  call delete(s:csv_file)
  call UnsetOptionVariable('db_ui_export_csv_strip_limit')
  call Cleanup()
endfunction

function! s:suite.should_export_query_to_csv() abort
  if !executable('sqlite3')
    return
  endif

  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(name, default) abort
    return s:csv_file
  endfunction

  :DBUI
  norm ojo
  call setline(1, 'select contact_id, first_name from contacts order by contact_id limit 1;')
  norm ,X

  call s:expect(readfile(s:csv_file)).to_equal(['contact_id,first_name', '1,John'])
endfunction

function! s:suite.should_convert_sqlserver_output_to_csv() abort
  let output = [
        \ 'id'."\t".'name'."\t".'note',
        \ '--'."\t".'----'."\t".'----',
        \ '1'."\t".'Smith, Jane'."\t".'Said "hello"',
        \ '',
        \ ]

  call s:expect(db_ui#query#sqlserver_to_csv(output)).to_equal([
        \ 'id,name,note',
        \ '1,"Smith, Jane","Said ""hello"""',
        \ ])
endfunction

function! s:suite.should_default_export_path_to_current_working_directory() abort
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(name, default) abort
    let g:db_ui_test_export_default = a:default
    return ''
  endfunction

  enew
  file test-query.sql
  call db_ui#query#export_csv(['select 1'], {'db_url': 'sqlite:test/dadbod_ui_test.db'})

  call s:expect(g:db_ui_test_export_default).to_equal(fnamemodify('test-query.csv', ':p'))
  unlet! g:db_ui_test_export_default
endfunction
