let s:suite = themis#suite('Bind parameters')
let s:expect = themis#helper('expect')
let s:bufnr = ''

function! s:suite.before() abort
  call SetupTestDbs()
  " Sleep 1 sec to avoid overlapping temp names
  sleep 1
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_prompt_to_set_bind_parameters() abort
  :DBUI
  norm ojo
  call s:expect(&filetype).to_equal('sql')
  let g:db_ui_cast_not_considered_bind_param = 1
  let g:db_ui_string_content_not_considered_bind_param = 1
  norm!Iselect *, name::text from contacts where id = :contactId and first_name = :firstName and last_name = ":shouldSkip" and settings = '{:ignored 123}'
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(msg, default) abort
    if stridx(a:msg, ':ignored') > -1
      let g:db_ui_string_content_not_considered_bind_param = 0
      return ''
    endif
    if stridx(a:msg, ':text') > -1
      let g:db_ui_cast_not_considered_bind_param = 0
      return ''
    endif
    if stridx(a:msg, ':contactId') > -1
      return '1'
    endif
    if stridx(a:msg, ':firstName') > -1
      return 'John'
    endif
    if stridx(a:msg, ':shouldSkip') > -1
      return ''
    endif
  endfunction
  write
  call s:expect(g:db_ui_cast_not_considered_bind_param).to_equal(1)
  call s:expect(g:db_ui_string_content_not_considered_bind_param).to_equal(1)
  call s:expect(get(b:, 'dbui_bind_params')).to_be_dict()
  call s:expect(b:dbui_bind_params[':contactId']).to_equal(1)
  call s:expect(b:dbui_bind_params[':firstName']).to_equal('John')
  call s:expect(b:dbui_bind_params[':shouldSkip']).to_equal('')
endfunction

function! s:suite.should_prompt_to_edit_bind_parameters() abort
  let g:db_ui_test_option = 1
  function! db_ui#utils#inputlist(msg) abort
    return g:db_ui_test_option
  endfunction

  let g:db_ui_bind_param_keys = keys(b:dbui_bind_params)
  let g:db_ui_new_bind_params = {
        \ ':contactId': '2',
        \ ':shouldSkip': '',
        \ ':firstName': 'Peter'
        \ }

  function! db_ui#utils#input(msg, default) abort
    return g:db_ui_new_bind_params[g:db_ui_bind_param_keys[g:db_ui_test_option - 1]]
  endfunction
  norm ,E
  let g:db_ui_test_option = 2
  norm ,E
  let g:db_ui_test_option = 3
  norm ,E
  call s:expect(b:dbui_bind_params[':contactId']).to_equal(2)
  call s:expect(b:dbui_bind_params[':firstName']).to_equal('Peter')
  call s:expect(b:dbui_bind_params[':shouldSkip']).to_equal('')
endfunction
