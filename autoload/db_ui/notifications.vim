" Author: Kristijan Husak
" Github: http://github.com/kristijanhusak
" Original: http://github.com/kristijanhusak/vim-simple-notifications
" LICENSE: MIT

" Default options, overrideable via second argument to functions
let s:delay = 7000                        "Hide after this number of milliseconds
let s:width = g:db_ui_notification_width  "Default notification width
let s:pos = 'bot'.g:db_ui_win_position     "Default position for notification
let s:title = '[DBUI]'                    "Title of notification
let s:last_msg = ''
let s:use_nvim_notify = g:db_ui_use_nvim_notify

let s:colors_set = 0

if s:use_nvim_notify && !has('nvim')
  echoerr "Option db_ui_use_nvim_notify is supported only in neovim"
endif

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

  let type = get(a:opts, 'type', 'info')

  if type ==? 'info' && g:db_ui_disable_info_notifications
    return
  endif

  let use_echo = get(a:opts, 'echo', 0)
  if !use_echo
    let use_echo = g:db_ui_force_echo_notifications
  endif

  if s:use_nvim_notify && !use_echo
    return s:notification_nvim_notify(a:msg, a:opts)
  endif

  if !s:colors_set
    call s:setup_colors()
    let s:colors_set = 1
  endif

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

function! s:notification_nvim_notify(msg, opts) abort
  let type = get(a:opts, 'type', 'info')
  let title = get(a:opts, 'title', s:title)
  let opts = { 'title': title }
  if get(a:opts, 'delay')
    let opts.timeout = { 'timeout': a:opts.delay }
  endif
  if (type ==? 'info')
    let opts.id = 'vim-dadbod-ui-info'
    let opts.replace = 'vim-dadbod-ui-info'
  endif

  let log_levels = {
    \ 'info': luaeval("vim.log.levels.INFO"),
    \ 'error': luaeval("vim.log.levels.ERROR"),
    \ 'warning': luaeval("vim.log.levels.WARN")
  \ }

  return luaeval('vim.notify(_A[1], _A[2], _A[3])', [a:msg, log_levels[type], opts])
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
  call nvim_buf_set_lines(buf, 0, -1, v:false, msg)

  let s:win = nvim_open_win(buf, v:false, opts)
  silent! exe 'autocmd BufEnter <buffer='.buf.'> :bw!'
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
  silent! exe 'echohl Echo'.s:hl_by_type[type]
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

function! s:setup_colors() abort
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

  call s:set_hl('NotificationInfo', normal_bg, normal_fg)
  call s:set_hl('NotificationError', error_fg, error_bg)
  call s:set_hl('NotificationWarning', warning_fg, warning_bg)

  call s:set_hl('EchoNotificationInfo', normal_fg, 'NONE')
  call s:set_hl('EchoNotificationError', error_bg, 'NONE')
  call s:set_hl('EchoNotificationWarning', warning_bg, 'NONE')
endfunction

function! s:get_pos(pos, width) abort
  let min_col = s:neovim_float ? 1 : 2
  let min_row = s:neovim_float ? 0 : 1
  let max_col = &columns - 1
  let dbout_buffers = filter(range(1, winnr('$')), 'getwinvar(v:val, "&filetype") ==? "dbout"')
  let extra_height = 0
  if len(dbout_buffers)
    let extra_height = max(map(copy(dbout_buffers), 'winheight(v:val)'))
    let extra_height += 1
  endif
  let max_row = &lines - 3 - extra_height
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

function! s:set_hl(name, fg, bg) abort
  if !hlexists(a:name)
    silent! exe 'hi '.a:name.' guifg='.a:fg.' guibg='.a:bg
  endif
endfunction

function! s:hide_notifications() abort
  if has('nvim')
    return s:nvim_close()
  endif
  if exists('*popup_close')
    return popup_close(s:win)
  endif
endfunction

command DBUIHideNotifications call s:hide_notifications()
