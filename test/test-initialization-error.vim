let s:suite = themis#suite('Initialization error')
let s:expect = themis#helper('expect')

function! s:suite.after() abort
  call delete(g:db_ui_save_location.'/connections.json')
  call Cleanup()
endfunction

function! s:suite.should_return_error_on_no_connnections() abort
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(input, default) abort
    return ''
  endfunction
  let g:db_ui_messages = []
  :redir => g:db_ui_messages
  :DBUI
  :redir END
  let lines = split(g:db_ui_messages, "\n")
  call s:expect(trim(lines[0])).to_equal('[DBUI] No databases found. Use one of these methods to add a connection:')
  call s:expect(trim(lines[1])).to_equal('1. Call :DBUIAddConnection command to add a new globally available connection')
  call s:expect(trim(lines[2])).to_equal('2. Define g:dbs variable')
  call s:expect(trim(lines[3])).to_equal('3. Export $DBUI_URL env variable')
  call s:expect(trim(lines[4])).to_equal('4. Add an env variable into your .env file that starts with DB_UI_')
  call s:expect(trim(lines[5])).to_equal('[DBUI] DB: invalid URL')
endfunction

function! s:suite.should_return_error_and_prompt_to_add_connection() abort
  function! db_ui#utils#input(name, val)
    if a:name ==? 'Enter connection url: '
      return 'sqlite:test/dadbod_ui_test.db'
    endif

    if a:name ==? 'Enter name: '
      return 'test-add-on-error'
    endif
  endfunction
  let g:db_ui_messages = []
  :redir => g:db_ui_messages
  :DBUI
  :redir END
  let lines = split(g:db_ui_messages, "\n")
  call s:expect(trim(lines[0])).to_equal('[DBUI] No databases found. Use one of these methods to add a connection:')
  call s:expect(trim(lines[1])).to_equal('1. Call :DBUIAddConnection command to add a new globally available connection')
  call s:expect(trim(lines[2])).to_equal('2. Define g:dbs variable')
  call s:expect(trim(lines[3])).to_equal('3. Export $DBUI_URL env variable')
  call s:expect(trim(lines[4])).to_equal('4. Add an env variable into your .env file that starts with DB_UI_')
endfunction
