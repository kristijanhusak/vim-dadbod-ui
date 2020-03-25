# vim-dadbod-ui

Simple UI for [vim-dadbod](https://github.com/tpope/vim-dadbod).
It allows simple navigation through databases and allows saving queries for later use.

![screenshot](https://i.imgur.com/siBjM6K.png)

This is still work in progress.
Currently tested only on Linux Vim 8+ and Neovim with PostgreSQL.

If you find any bugs, please report them.

## Installation

Use your favorite package manager. If you don't have one, I suggest [vim-packager](https://github.com/kristijanhusak/vim-packager)
```vimL
function! PackagerInit() abort
  packadd vim-packager
  call packager#init()
  call packager#add('kristijanhusak/vim-packager', { 'type': 'opt' })
  call packager#add('tpope/vim-dadbod')
  call packager#add('kristijanhusak/vim-dadbod-ui')
endfunction

" This is just an example. Keep this out of version control
let g:dbs = {
  'dev': 'postgres://postgres:mypassword@localhost:5432/my-dev-db'
}
```

After installation, run `:DBUI`, which should open up a drawer with all databases provided.
When you finish writing your query, just write the file (`:w`) and it will automatically execute the query for that database and it will automatically execute the query for selected database.

## Databases
Provide dictionary with all databases that you want to use through `g:dbs` variable:

```vimL
let g:dbs = {
\ 'dev': 'postgres://postgres:mypassword@localhost:5432/my-dev-db',
\ 'staging': 'postgres://postgres:mypassword@localhost:5432/my-staging-db',
\ 'wp': 'mysql://root@localhost/wp_awesome',
\ }
```

Just make sure to **NOT COMMIT** these. I suggest using project local vim config (`:help exrc`)

## Settings
### Icons
These are the default icons used:

```vimL
let g:db_ui_icons = {
    \ 'expanded': '▾',
    \ 'collapsed': '▸',
    \ 'saved_sql': '*',
    \ 'new_query': '+',
    \ 'tables': '~',
    \ 'buffers': '»'
    \ }
```

You can override any of these:
```vimL
let g:db_ui_icons = {
    \ 'expanded': '+',
    \ 'collapsed': '-',
    \ }
```

### Drawer width

What should be the drawer width when opened. Default is `40`.

```vimL
let g:db_ui_winwidth = 30
```

### Default query
When opening up a table, buffer will be prepopulated with some basic select, which defaults to:
```sql
select * from table LIMIT 200;
```
To change the default value, use `g:db_ui_default_query`, where `{table}` is placeholder for table name.

```vimL
let g:db_ui_default_query = 'select * from "{table}" limit 10'
```

### Save location
All queries are by default written to tmp folder.
There's a mapping to save them permanently for later to the specific location.

That location is by default `~/.local/share/db_ui`. To change it, addd `g:db_ui_save_location` to your vimrc.
```vimL
let g:db_ui_save_location = '~/Dropbox/db_ui_queries'
```

## Mappings
These are the default mappings for `dbui` drawer:

* o / <CR> - Open/Toggle Drawer options (`<Plug>(DBUI_SelectLine)`)
* S - Open in vertical split (`<Plug>(DBUI_SelectLineVsplit)`)
* R - Redraw (`<Plug>(DBUI_Redraw)`)

For queries, filetype is automatically set to `sql`. Also, one mappings is added for the `sql` filetype:

* <Leader>W - Permanently save query for later use (`<Plug>(DBUI_SaveQuery)`)

Any of these mappings can be overridden:
```vimL
autocmd FileType dbui nmap <buffer> v <Plug>(DBUI_SelectLineVsplit)
```

If you don't want any mappings to be added, add this to vimrc:
```
let g:db_ui_disable-mappings = 1
