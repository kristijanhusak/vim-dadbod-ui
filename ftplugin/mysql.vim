let s:current_folder = expand('<sfile>:p:h')
silent exe 'source '.s:current_folder.'/sql.vim'
