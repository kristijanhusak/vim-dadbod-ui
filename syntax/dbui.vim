syntax clear
for [icon_name, icon] in items(g:dbui_icons)
  exe 'syn match dbui_'.icon_name. ' /^[[:blank:]]*'.escape(icon, '*[]\/~').'/'
endfor

exe 'syn match dbui_connection_source /\('.g:dbui_icons.expanded.'\s\|'.g:dbui_icons.collapsed.'\s\)\@<!([^)]*)$/'
hi default link dbui_connection_source Comment
hi default link dbui_expanded Directory
hi default link dbui_collapsed Directory
hi default link dbui_saved_sql String
hi default link dbui_new_query Operator
hi default link dbui_buffers Constant
hi default link dbui_tables Constant
