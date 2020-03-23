syntax clear
for [icon_name, icon] in items(g:db_ui_icons)
  exe 'syn match dbui_'.icon_name. ' /^[[:blank:]]*'.escape(icon, '*[]\/').'/'
endfor
syn match dbui_titles /^\(Buffers\|Databases\):$/

hi default link dbui_db_expanded Directory
hi default link dbui_db_collapsed Directory
hi default link dbui_table String
hi default link dbui_buffer Operator
hi default link dbui_titles Constant
