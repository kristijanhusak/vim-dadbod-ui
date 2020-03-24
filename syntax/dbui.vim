syntax clear
for [icon_name, icon] in items(g:db_ui_icons)
  exe 'syn match dbui_'.icon_name. ' /^[[:blank:]]*'.escape(icon, '*[]\/~').'/'
endfor

hi default link dbui_expanded Directory
hi default link dbui_collapsed Directory
hi default link dbui_saved_sql String
hi default link dbui_new_query Operator
hi default link dbui_buffers Constant
hi default link dbui_tables Constant
