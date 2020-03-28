#!/usr/bin/env bash

if [ ! -d "vader.vim" ]; then
  git clone https://github.com/junegunn/vader.vim
fi

if [ ! -d "vim-dadbod" ]; then
  git clone https://github.com/tpope/vim-dadbod
fi

vim -EsNu <(cat << EOF
filetype off
set rtp+=vader.vim
set rtp+=vim-dadbod
set rtp+=.
filetype plugin indent on
syntax enable
let g:mapleader = ','
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set breakindent
set smartindent
EOF
) -c 'Vader! spec/*' && echo 'All tests passed!' || (echo 'Tests failed.' && exit 1)
