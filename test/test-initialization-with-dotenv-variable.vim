let s:suite = themis#suite('Initialization with dotenv variables')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  let self.env_filename = '.env'
  call writefile(['DB_UI_DEV_DB:sqlite:test/dadbod_ui_test.db', 'DB_UI_PROD_DB:sqlite:test/dadbod_ui_test.db'], self.env_filename)
endfunction

function! s:suite.after() abort
  call delete(self.env_filename)
  unlet self.env_filename
  unlet $DB_UI_DEV_DB
  unlet $DB_UI_PROD_DB
  call Cleanup()
endfunction

function! s:suite.should_read_dotenv_variables()
  edit LICENSE
  :DBUI
  call s:expect(&filetype).to_equal('dbui')
  call s:expect(getline(1)).to_match(printf('%s %s', g:db_ui_icons.collapsed.db, '\(dev_db\|prod_db\)'))
  call s:expect(getline(2)).to_match(printf('%s %s', g:db_ui_icons.collapsed.db, '\(dev_db\|prod_db\)'))
endfunction
