# vim-dadbod-ui

Simple UI for [vim-dadbod](https://github.com/tpope/vim-dadbod).
It allows simple navigation through databases and allows saving queries for later use.

![screenshot](https://i.imgur.com/fhGqC9U.png)

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

" This is just an example. Keep this out of version control. Check for more examples below.
let g:dbs = {
\  'dev': 'postgres://postgres:mypassword@localhost:5432/my-dev-db'
\ }
```

After installation, run `:DBUI`, which should open up a drawer with all databases provided.
When you finish writing your query, just write the file (`:w`) and it will automatically execute the query for that database and it will automatically execute the query for selected database.

## Databases
There are 2 ways to provide database connections to UI:

1. Through environment variables
If `$DBUI_URL` env variable exists, it will be added as a connection. Name for the connection will be parsed from the url.
If you want to use a custom name, pass `$DBUI_NAME` alongside the url.
Env variables that will be read can be customized like this:

```vimL
let g:db_ui_env_variable_url = 'DATABASE_URL'
let g:db_ui_env_variable_name = 'DATABASE_NAME'
```

Optionally you can leverage [dotenv.vim](https://github.com/tpope/vim-dotenv)
to specific any number of connections in an `.env` file by using a specific
prefix (defaults to `DB_UI_`). The latter part of the env variable becomes the
name of the connection (lowercased)

```bash
# .env
DB_UI_DEV=...          # becomes the `dev` connection
DB_UI_PRODUCTION=...   # becomes the `production` connection
```

The prefix can be customized like this:

```vimL
let g:db_ui_dotenv_variable_prefix = 'MYPREFIX_'
```

2. Via `g:dbs` variable
Provide list with all databases that you want to use through `g:dbs` variable as an array of objects or an object:

```vimL
let g:dbs = {
\ 'dev': 'postgres://postgres:mypassword@localhost:5432/my-dev-db',
\ 'staging': 'postgres://postgres:mypassword@localhost:5432/my-staging-db',
\ 'wp': 'mysql://root@localhost/wp_awesome',
\ }
```

Or if you want them to be sorted in the order you define them, this way is also available:

```vimL
let g:dbs = [
\ { 'name': 'dev', 'url': 'postgres://postgres:mypassword@localhost:5432/my-dev-db' }
\ { 'name': 'staging', 'url': 'postgres://postgres:mypassword@localhost:5432/my-staging-db' },
\ { 'name': 'wp', 'url': 'mysql://root@localhost/wp_awesome' },
\ ]
```
Just make sure to **NOT COMMIT** these. I suggest using project local vim config (`:help exrc`)

If both env variable and g:dbs exists, they will be read in this order:
1. Env variable
2. g:dbs

If connection names is clashing, first one takes the precedence. For example, if you have these defined:

```
let $DBUI_URL = 'postgres://postgres:mypassword@localhost:5432/my-dev-db'
let g:dbs = {
  'my-dev-db': 'postgres://postgres:mypassword@localhost:5432/my-other-dev-db'
}
```

Surviving one will be `$DBUI_URL`. If you want to keep both, either provide `$DBUI_NAME` for the first connection,
or change the name for the one in `g:dbs`.
Env variable has precedence over g:dbs to allow having project level connections always available.

## Settings
### Table helpers
Table helper is a predefined query that is available for each table in the list.
Currently, default helper that each scheme has for it's tables is `List`, which for most schemes defaults to `g:db_ui_default_query`.
Postgres, Mysql and Sqlite has some additional helpers defined, like "Indexes", "Foreign Keys", "Primary Keys".

Predefined query can inject current db name and table name via `{table}` and `{dbname}`.

To add your own for a specific scheme, provide it through .`g:db_ui_table_helpers`.

For example, to add a "count rows" helper for postgres, you would add this as a config:

```vimL
let g:db_ui_table_helpers = {
\   'postgresql': {
\     'Count': 'select count(*) from "{table}"'
\   }
\ }
```

Or if you want to override any of the defaults, provide the same name as part of config:
```vimL
let g:db_ui_table_helpers = {
\   'postgresql': {
\     'List': 'select * from "{table}" order by id asc'
\   }
\ }
```

### Auto execute query
If this is set to `1`, opening any of the table helpers will also automatically execute the query.

Default value is: `0`

To enable it, add this to vimrc:

```vimL
let g:db_ui_auto_execute_table_helpers = 1
```

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

**DEPRECATED**: Use [Table helpers](#table-helpers) instead.

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
* d - Delete buffer or saved sql (`<Plug>(DBUI_DeleteLine)`)
* R - Redraw (`<Plug>(DBUI_Redraw)`)

For queries, filetype is automatically set to `sql`. Also, one mappings is added for the `sql` filetype:

* <Leader>W - Permanently save query for later use (`<Plug>(DBUI_SaveQuery)`)

Any of these mappings can be overridden:
```vimL
autocmd FileType dbui nmap <buffer> v <Plug>(DBUI_SelectLineVsplit)
```

If you don't want any mappings to be added, add this to vimrc:
```vimL
let g:db_ui_disable-mappings = 1
```

## TODO

* [ ] Test on Windows
* [ ] Test with more db types
