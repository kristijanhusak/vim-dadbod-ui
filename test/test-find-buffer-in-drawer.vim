let s:suite = themis#suite('Find buffer')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  let self.filename = 'test_random_query.sql'
  call writefile(['SELECT * FROM contacts ORDER BY created_at DESC'], self.filename)
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
  call delete(self.filename)
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
  call s:expect(getline('.')).to_equal(g:db_ui_icons.expanded.db.' dadbod_ui_test '.g:db_ui_icons.connection_ok)
  wincmd p
  :DBUIFindBuffer
  call s:expect(&filetype).to_equal('sql')
  wincmd p
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline('.')).to_match('^    '.g:db_ui_icons.buffers.' contacts-List-.*$')
endfunction

function! s:suite.should_find_non_dbui_buffer_in_dbui_drawer() abort
  let filename = fnamemodify(self.filename, ':p')
  exe 'edit '.filename
  call s:expect(expand('%:p')).to_equal(filename)

  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#inputlist(list)
    return 1
  endfunction
  :DBUIFindBuffer
  call s:expect(&filetype).to_equal('sql')
  call s:expect(b:dbui_db_key_name).to_equal('dadbod_ui_test_g:dbs')
  call s:expect(b:db).to_equal(g:dbs[0].url)
  wincmd p
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(5)).to_equal('    '.g:db_ui_icons.buffers.' '.self.filename)
  wincmd p
  write
  call s:expect(bufname('.dbout')).not.to_be_empty()
  call s:expect(getwinvar(bufwinnr('.dbout'), '&previewwindow')).to_equal(1)
endfunction
