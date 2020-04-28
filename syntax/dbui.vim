syntax clear
for [icon_name, icon] in items(g:dbui_icons)
  exe 'syn match dbui_'.icon_name. ' /^[[:blank:]]*'.escape(icon, '*[]\/~').'/'
endfor

exe 'syn match dbui_connection_source /\('.g:dbui_icons.expanded.'\s\|'.g:dbui_icons.collapsed.'\s\)\@<!([^)]*)$/'
exe 'syn match dbui_connection_ok /'.g:dbui_icons.connection_ok.'/'
exe 'syn match dbui_connection_error /'.g:dbui_icons.connection_error.'/'
syn match dbui_help /^".*$/
syn match dbui_help_key /^"\s\zs[^ ]*\ze\s-/ containedin=dbui_help
hi default link dbui_connection_source Comment
hi default link dbui_help Comment
hi default link dbui_help_key String
hi default link dbui_expanded Directory
hi default link dbui_collapsed Directory
hi default link dbui_add_connection Directory
hi default link dbui_saved_query String
hi default link dbui_new_query Operator
hi default link dbui_buffers Constant
hi default link dbui_tables Constant
if &background ==? 'light'
  hi dbui_connection_ok guifg=#00AA00
  hi dbui_connection_error guifg=#AA0000
else
  hi dbui_connection_ok guifg=#88FF88
  hi dbui_connection_error guifg=#ff8888
endif
