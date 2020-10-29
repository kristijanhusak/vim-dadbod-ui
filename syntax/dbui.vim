syntax clear
for [icon_name, icon] in items(g:db_ui_icons)
  if type(icon) ==? type({})
    for [nested_icon_name, nested_icon] in items(icon)
      let name = 'dbui_'.icon_name.'_'.nested_icon_name
      exe 'syn match '.name.' /^[[:blank:]]*'.escape(nested_icon, '*[]\/~').'/'
      exe 'hi default link '.name.' Directory'
    endfor
  else
    exe 'syn match dbui_'.icon_name. ' /^[[:blank:]]*'.escape(icon, '*[]\/~').'/'
  endif
endfor

exe 'syn match dbui_connection_source /\('.g:db_ui_icons.expanded.db.'\s\|'.g:db_ui_icons.collapsed.db.'\s\)\@<!([^)]*)$/'
exe 'syn match dbui_connection_ok /'.g:db_ui_icons.connection_ok.'/'
exe 'syn match dbui_connection_error /'.g:db_ui_icons.connection_error.'/'
syn match dbui_help /^".*$/
syn match dbui_help_key /^"\s\zs[^ ]*\ze\s-/ containedin=dbui_help
hi default link dbui_connection_source Comment
hi default link dbui_help Comment
hi default link dbui_help_key String
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
