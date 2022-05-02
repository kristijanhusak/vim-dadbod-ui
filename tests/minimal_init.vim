set rtp+=.
set rtp+=./plenary.nvim
set rtp+=./vim-dadbod
set rtp+=./vim-dotenv
set termguicolors
set noswapfile
runtime plugin/dadbod.vim
runtime plugin/dotenv.vim
runtime plugin/db_ui.vim
runtime plugin/plenary.vim
let mapleader = ','

filetype plugin indent on
syntax enable
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set breakindent
set smartindent
let s:location_path = expand('%:p:h')
let g:db_ui_save_location = s:location_path
let g:db_ui_show_help = 0

function! SetupTestDbs() abort
let g:dbs = [
  \ {'name': 'dadbod_ui_test', 'url': 'sqlite:'.fnamemodify('tests/dadbod_ui_test.db', ':p') },
  \ {'name': 'dadbod_ui_testing', 'url': 'sqlite:'.fnamemodify('tests/dadbod_ui_test.db', ':p') },
  \ ]
endfunction

function! Cleanup() abort
  call db_ui#reset_state()
  unlet! g:dbs
  let w = 2
  while w <= winnr('$')
      silent! execute w . 'close!'
      let w += 1
  endwhile
  silent! execute 'bwipeout!' join(range(1, bufnr('$')), ' ')
endfunction

function! SetOptionVariable(name, value) abort
  unlet! g:loaded_dbui
  let g:{a:name} = a:value
  let g:db_ui_save_location = s:location_path
  runtime plugin/db_ui.vim
endfunction

function! UnsetOptionVariable(name) abort
  unlet! g:loaded_dbui
  unlet! let g:{a:name}
  let g:db_ui_save_location = s:location_path
  runtime plugin/db_ui.vim
endfunction
