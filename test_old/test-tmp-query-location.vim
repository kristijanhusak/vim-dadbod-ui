let s:suite = themis#suite('Open query')
let s:expect = themis#helper('expect')

let s:query_folder = g:db_ui_save_location.'/queries'

function! s:suite.before() abort
  call SetOptionVariable('db_ui_tmp_query_location', s:query_folder)
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call delete(s:query_folder, 'rf')
  call Cleanup()
  call SetOptionVariable('db_ui_tmp_query_location', '')
endfunction

function! s:suite.should_open_contacts_table_list_query() abort
  :DBUI
  norm jo2jojojojo
  call s:expect(getline(1)).to_equal('SELECT * from "contacts" LIMIT 200;')
  call s:expect(b:dbui_table_name).to_equal('contacts')
  write
  call s:expect(filereadable(bufname('%'))).to_be_true()
  norm q
  call Cleanup()
endfunction

function! s:suite.should_have_saved_buffers_after_reopen() abort
  call SetupTestDbs()
  :DBUI
  norm jo2joj
  call s:expect(getline('.')).to_match('contacts-List')
  norm o
  call s:expect(getline(1)).to_equal('SELECT * from "contacts" LIMIT 200;')
endfunction
