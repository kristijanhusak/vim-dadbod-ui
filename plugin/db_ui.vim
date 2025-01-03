if exists('g:loaded_dbui')
  finish
endif
let g:loaded_dbui = 1

let g:db_ui_disable_progress_bar = get(g:, 'db_ui_disable_progress_bar', 0)
let g:db_ui_use_postgres_views = get(g:, 'db_ui_use_postgres_views', 1)
let g:db_ui_notification_width = get(g:, 'db_ui_notification_width', 40)
let g:db_ui_winwidth = get(g:, 'db_ui_winwidth', 40)
let g:db_ui_win_position = get(g:, 'db_ui_win_position', 'left')
let g:db_ui_default_query = get(g:, 'db_ui_default_query', 'SELECT * from "{table}" LIMIT 200;')
let g:db_ui_save_location = get(g:, 'db_ui_save_location', '~/.local/share/db_ui')
let g:db_ui_tmp_query_location = get(g:, 'db_ui_tmp_query_location', '')
let g:db_ui_dotenv_variable_prefix = get(g:, 'db_ui_dotenv_variable_prefix', 'DB_UI_')
let g:db_ui_env_variable_url = get(g:, 'db_ui_env_variable_url', 'DBUI_URL')
let g:db_ui_env_variable_name = get(g:, 'db_ui_env_variable_name', 'DBUI_NAME')
let g:db_ui_disable_mappings = get(g:, 'db_ui_disable_mappings', 0)
let g:db_ui_disable_mappings_dbui = get(g:, 'db_ui_disable_mappings_dbui', 0)
let g:db_ui_disable_mappings_dbout = get(g:, 'db_ui_disable_mappings_dbout', 0)
let g:db_ui_disable_mappings_sql = get(g:, 'db_ui_disable_mappings_sql', 0)
let g:db_ui_disable_mappings_javascript = get(g:, 'db_ui_disable_mappings_javascript', 0)
let g:db_ui_table_helpers = get(g:, 'db_ui_table_helpers', {})
let g:db_ui_auto_execute_table_helpers = get(g:, 'db_ui_auto_execute_table_helpers', 0)
let g:db_ui_show_help = get(g:, 'db_ui_show_help', 1)
let g:db_ui_use_nerd_fonts = get(g:, 'db_ui_use_nerd_fonts', 0)
let g:db_ui_execute_on_save = get(g:, 'db_ui_execute_on_save', 1)
let g:db_ui_force_echo_notifications = get(g:, 'db_ui_force_echo_notifications', 0)
let g:db_ui_disable_info_notifications = get(g:, 'db_ui_disable_info_notifications', 0)
let g:db_ui_use_nvim_notify = get(g:, 'db_ui_use_nvim_notify', 0)
let g:Db_ui_buffer_name_generator = get(g:, 'Db_ui_buffer_name_generator', 0)
let g:Db_ui_table_name_sorter = get(g:, 'Db_ui_table_name_sorter', 0)
let g:db_ui_debug = get(g:, 'db_ui_debug', 0)
let g:db_ui_hide_schemas = get(g:, 'db_ui_hide_schemas', [])
let g:db_ui_bind_param_pattern = get(g: , 'db_ui_bind_param_pattern', ':\w\+')
let g:db_ui_is_oracle_legacy = get(g:, 'db_ui_is_oracle_legacy', 0)
let s:dbui_icons = get(g:, 'db_ui_icons', {})
let s:expanded_icon = get(s:dbui_icons, 'expanded', '▾')
let s:collapsed_icon = get(s:dbui_icons, 'collapsed', '▸')
let s:expanded_icons = {}
let s:collapsed_icons = {}

if type(s:expanded_icon) !=? type('')
  let s:expanded_icons = s:expanded_icon
  let s:expanded_icon = '▾'
else
  silent! call remove(s:dbui_icons, 'expanded')
endif

if type(s:collapsed_icon) !=? type('')
  let s:collapsed_icons = s:collapsed_icon
  let s:collapsed_icon = '▸'
else
  silent! call remove(s:dbui_icons, 'collapsed')
endif

let g:db_ui_icons = {
      \ 'expanded': {
      \   'db': s:expanded_icon,
      \   'buffers': s:expanded_icon,
      \   'saved_queries': s:expanded_icon,
      \   'schemas': s:expanded_icon,
      \   'schema': s:expanded_icon,
      \   'tables': s:expanded_icon,
      \   'table': s:expanded_icon,
      \ },
      \ 'collapsed': {
      \   'db': s:collapsed_icon,
      \   'buffers': s:collapsed_icon,
      \   'saved_queries': s:collapsed_icon,
      \   'schemas': s:collapsed_icon,
      \   'schema': s:collapsed_icon,
      \   'tables': s:collapsed_icon,
      \   'table': s:collapsed_icon,
      \ },
      \ 'saved_query': '*',
      \ 'new_query': '+',
      \ 'tables': '~',
      \ 'buffers': '»',
      \ 'add_connection': '[+]',
      \ 'connection_ok': '✓',
      \ 'connection_error': '✕',
      \ }

if g:db_ui_use_nerd_fonts
  let g:db_ui_icons = {
        \ 'expanded': {
        \   'db': s:expanded_icon.' 󰆼',
        \   'buffers': s:expanded_icon.' ',
        \   'saved_queries': s:expanded_icon.' ',
        \   'schemas': s:expanded_icon.' ',
        \   'schema': s:expanded_icon.' 󰙅',
        \   'tables': s:expanded_icon.' 󰓱',
        \   'table': s:expanded_icon.' ',
        \ },
        \ 'collapsed': {
        \   'db': s:collapsed_icon.' 󰆼',
        \   'buffers': s:collapsed_icon.' ',
        \   'saved_queries': s:collapsed_icon.' ',
        \   'schemas': s:collapsed_icon.' ',
        \   'schema': s:collapsed_icon.' 󰙅',
        \   'tables': s:collapsed_icon.' 󰓱',
        \   'table': s:collapsed_icon.' ',
        \ },
        \ 'saved_query': '  ',
        \ 'new_query': '  󰓰',
        \ 'tables': '  󰓫',
        \ 'buffers': '  ',
        \ 'add_connection': '  󰆺',
        \ 'connection_ok': '✓',
        \ 'connection_error': '✕',
        \ }
endif

let g:db_ui_icons.expanded = extend(g:db_ui_icons.expanded, s:expanded_icons)
let g:db_ui_icons.collapsed = extend(g:db_ui_icons.collapsed, s:collapsed_icons)
silent! call remove(s:dbui_icons, 'expanded')
silent! call remove(s:dbui_icons, 'collapsed')
let g:db_ui_icons = extend(g:db_ui_icons, s:dbui_icons)

augroup dbui
  autocmd!
  autocmd BufRead,BufNewFile *.dbout set filetype=dbout
  autocmd BufReadPost *.dbout nested call db_ui#save_dbout(expand('<afile>'))
  autocmd FileType dbout setlocal foldmethod=expr foldexpr=db_ui#dbout#foldexpr(v:lnum) | silent! normal!zo
  autocmd FileType dbout,dbui autocmd BufEnter,WinEnter <buffer> stopinsert
augroup END

command! DBUI call db_ui#open('<mods>')
command! DBUIToggle call db_ui#toggle()
command! DBUIClose call db_ui#close()
command! DBUIAddConnection call db_ui#connections#add()
command! DBUIFindBuffer call db_ui#find_buffer()
command! DBUIRenameBuffer call db_ui#rename_buffer()
command! DBUILastQueryInfo call db_ui#print_last_query_info()
