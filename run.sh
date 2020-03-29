#!/usr/bin/env bash

if [ ! -d "vim-themis" ]; then
  git clone https://github.com/thinca/vim-themis
fi

if [ ! -d "vim-dadbod" ]; then
  git clone https://github.com/tpope/vim-dadbod
fi

./vim-themis/bin/themis
