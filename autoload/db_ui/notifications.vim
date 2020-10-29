" Author: Kristijan Husak
" Github: http://github.com/kristijanhusak
" Original: http://github.com/kristijanhusak/vim-simple-notifications
" LICENSE: MIT

" Default options, overrideable via second argument to functions
let s:delay = 5000                        "Hide after this number of milliseconds
let s:width = 40                          "Default notification width
let s:pos = 'bot'.g:db_ui_win_position     "Default position for notification
let s:title = '[DBUI]'                    "Title of notification
let s:last_msg = ''

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                  Public API, adapt names to your needs                      "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! db_ui#notifications#info(msg, ...) abort
  return s:notification(a:msg, get(a:, 1, {}))
endfunction

function! db_ui#notifications#error(msg, ...) abort
  return s:notification(a:msg, extend({'type': 'error'}, get(a:, 1, {})))
endfunction

function! db_ui#notifications#warning(msg, ...) abort
  return s:notification(a:msg, extend({'type': 'warning'}, get(a:, 1, {})))
endfunction

function! db_ui#notifications#get_last_msg() abort
  if type(s:last_msg) ==? type([])
    return join(s:last_msg)
  endif
  return s:last_msg
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                               Implementation                                "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:win = -1
let s:timer = -1
let s:neovim_float = has('nvim') && exists('*nvim_open_win')
let s:vim_popup = exists('*popup_create')

function! s:notification(msg, opts) abort
  if empty(a:msg)
    return
  endif
  let use_echo = get(a:opts, 'echo', 0)
  call s:setup_colors(use_echo)

  if s:neovim_float && !use_echo
    return s:notification_nvim(a:msg, a:opts)
  endif

  if s:vim_popup && !use_echo
    return s:notification_vim(a:msg, a:opts)
  endif

  return s:notification_echo(a:msg, a:opts)
endfunction

let s:hl_by_type = {
      \ 'info': 'NotificationInfo',
      \ 'error': 'NotificationError',
      \ 'warning': 'NotificationWarning',
      \ }

function! s:nvim_close() abort
  silent! call nvim_win_close(s:win, v:true)
  silent! call timer_stop(s:timer)
endfunction

function! s:notification_nvim(msg, opts) abort
  let width = get(a:opts, 'width', s:width)
  let title = get(a:opts, 'title', s:title)
  let msg = type(a:msg) !=? type([]) ? [a:msg] : a:msg
  if !empty(title)
    let msg = [title] + msg
  endif

  let height = 0
  for line in msg
    let height += len(split(line,'.\{'.width.'}\zs'))
  endfor
  let delay = get(a:opts, 'delay', s:delay)
  let type = get(a:opts, 'type', 'info')
  let pos = get(a:opts, 'pos', s:pos)
  let pos_map = {'topleft': 'NW', 'topright': 'NE', 'botleft': 'SW', 'botright': 'SE', 'top': 'NW', 'bottom': 'SW'}

  let pos_opts = s:get_pos(pos, width)
  let pos_opts.anchor = pos_map[pos]
  let opts = extend(pos_opts, {
        \ 'relative': 'editor',
        \ 'width': width,
        \ 'height': height,
        \ 'style': 'minimal',
        \ })

  call s:nvim_close()
  let buf = nvim_create_buf(v:false, v:true)
  silent! exe 'autocmd BufEnter <buffer='.buf.'> :bw!'
  call nvim_buf_set_lines(buf, 0, -1, v:false, msg)

  let s:win = nvim_open_win(buf, v:false, opts)
  call nvim_win_set_option(s:win, 'wrap', v:true)
  call nvim_win_set_option(s:win, 'signcolumn', 'yes') "simulate left padding
  call nvim_win_set_option(s:win, 'winhl', 'Normal:'.s:hl_by_type[type])
  let s:timer = timer_start(delay, {-> s:nvim_close()})
  let s:last_msg = a:msg
endfunction

function! s:notification_vim(msg, opts) abort
  let width = get(a:opts, 'width', s:width)
  let delay = get(a:opts, 'delay', s:delay)
  let type = get(a:opts, 'type', 'info')
  let pos = get(a:opts, 'pos', s:pos)
  let title = get(a:opts, 'title', s:title)
  let pos_opts = s:get_pos(pos, width)
  let pos_opts.line = pos_opts.row
  unlet! pos_opts.row
  let pos_map = {'top': 'topleft', 'bottom': 'botleft'}
  let pos = has_key(pos_map, pos) ? pos_map[pos] : pos
  let opts = extend(pos_opts, {
        \ 'pos': pos,
        \ 'minwidth': width,
        \ 'maxwidth': width,
        \ 'time': delay,
        \ 'close': 'click',
        \ 'title': title,
        \ 'padding': [0, 0, 0, 1],
        \ })

  let opts.highlight = s:hl_by_type[type]
  call popup_hide(s:win)
  let s:win = popup_create(a:msg, opts)
  let s:last_msg = a:msg
endfunction

function! s:notification_echo(msg, opts) abort
  let type = get(a:opts, 'type', 'info')
  let title = get(a:opts, 'title', s:title)
  silent! exe 'echohl '.s:hl_by_type[type]
  redraw!
  let title = !empty(title) ? title.' ' : ''
  if type(a:msg) ==? type('')
    echom title.a:msg
  elseif type(a:msg) !=? type([])
    echom title.string(a:msg)
  else
    echom title.a:msg[0]
    for msg in a:msg[1:]
      echom msg
    endfor
  endif
  echohl None
  let s:last_msg = a:msg
endfunction

function! s:setup_colors(use_echo) abort
  let warning_fg = ''
  let warning_bg = ''
  let error_fg = ''
  let error_bg = ''
  let normal_fg = ''
  let normal_bg = ''
  let warning_bg = synIDattr(hlID('WarningMsg'), 'bg')
  let warning_fg = synIDattr(hlID('WarningMsg'), 'fg')
  if empty(warning_bg)
    let warning_bg = warning_fg
    let warning_fg = '#FFFFFF'
  endif

  let error_bg = synIDattr(hlID('Error'), 'bg')
  let error_fg = synIDattr(hlID('Error'), 'fg')
  if empty(error_bg)
    let error_bg = error_fg
    let error_fg = '#FFFFFF'
  endif

  let normal_bg = synIDattr(hlID('Normal'), 'bg')
  let normal_fg = synIDattr(hlID('Normal'), 'fg')
  if empty(normal_bg)
    let normal_bg = normal_fg
    let normal_fg = '#FFFFFF'
  endif

  if (s:neovim_float || s:vim_popup) && !a:use_echo
    silent! exe 'hi NotificationInfo guifg='.normal_bg.' guibg='.normal_fg
    silent! exe 'hi NotificationError guifg='.error_fg.' guibg='.error_bg
    silent! exe 'hi NotificationWarning guifg='.warning_fg.' guibg='.warning_bg
  else
    silent! exe 'hi NotificationInfo guifg='.normal_fg.' guibg=NONE'
    silent! exe 'hi NotificationError guifg='.error_bg.' guibg=NONE'
    silent! exe 'hi NotificationWarning guifg='.warning_bg.' guibg=NONE'
  endif
endfunction

function! s:get_pos(pos, width) abort
  let min_col = s:neovim_float ? 1 : 2
  let min_row = s:neovim_float ? 0 : 1
  let max_col = &columns - 1
  let dbout_opened = len(filter(range(1, winnr('$')), 'getwinvar(v:val, "&filetype") ==? "dbout"')) > 0
  let max_row = &lines - 3 - (dbout_opened ? (&previewheight + 1) : 0)
  let pos_data = {'col': min_col, 'row': min_row}

  if a:pos ==? 'top'
    let pos_data.row = min_row
    let pos_data.col = (&columns / 2) - (a:width / 2)
  endif

  if a:pos ==? 'bottom'
    let pos_data.row = max_row
    let pos_data.col = (&columns / 2) - (a:width / 2)
  endif

  if a:pos ==? 'topright'
    let pos_data.col = max_col
    let pos_data.row = min_row
  endif

  if a:pos ==? 'botleft'
    let pos_data.col = min_col
    let pos_data.row = max_row
  endif

  if a:pos ==? 'botright'
    let pos_data.col = max_col
    let pos_data.row = max_row
  endif

  return pos_data
endfunction
