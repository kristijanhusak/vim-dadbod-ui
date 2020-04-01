let s:suite = themis#suite('Bind parameters')
let s:expect = themis#helper('expect')
let s:bufnr = ''

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_prompt_to_set_bind_parameters() abort
  :DBUI
  norm ojo
  call s:expect(&filetype).to_equal('sql')
  let s:bufnr = bufnr('')
  norm!Iselect * from contacts where id = :contactId and first_name = :firstName and last_name = ":shouldSkip"
  runtime autoload/db_ui/utils.vim
  function! db_ui#utils#input(msg, default) abort
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
  let self.bind_params = getbufvar(s:bufnr, 'db_ui_bind_params')
  call s:expect(self.bind_params).to_be_dict()
  call s:expect(self.bind_params[':contactId']).to_equal(1)
  call s:expect(self.bind_params[':firstName']).to_equal('John')
  call s:expect(self.bind_params[':shouldSkip']).to_equal('')
endfunction

function! s:suite.should_prompt_to_edit_bind_parameters() abort
  let g:dbui_test_option = 1
  function! db_ui#utils#inputlist(msg) abort
    return g:dbui_test_option
  endfunction

  let g:dbui_bind_param_keys = keys(self.bind_params)
  let g:dbui_new_bind_params = {
        \ ':contactId': '2',
        \ ':shouldSkip': '',
        \ ':firstName': 'Peter'
        \ }

  function! db_ui#utils#input(msg, default) abort
    return g:dbui_new_bind_params[g:dbui_bind_param_keys[g:dbui_test_option - 1]]
  endfunction
  exe 'b'.s:bufnr
  norm ,E
  let g:dbui_test_option = 2
  norm ,E
  let g:dbui_test_option = 3
  norm ,E
  let self.bind_params = getbufvar(s:bufnr, 'db_ui_bind_params')
  call s:expect(self.bind_params[':contactId']).to_equal(2)
  call s:expect(self.bind_params[':firstName']).to_equal('Peter')
  call s:expect(self.bind_params[':shouldSkip']).to_equal('')
endfunction
