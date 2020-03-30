#!/usr/bin/env bash

if [ ! -d "vim-themis" ]; then
  git clone https://github.com/thinca/vim-themis
fi

if [ ! -d "vim-dadbod" ]; then
  git clone https://github.com/tpope/vim-dadbod
fi

if [ ! -d "vim-dotenv" ]; then
  git clone https://github.com/tpope/vim-dotenv
fi

./vim-themis/bin/themis
