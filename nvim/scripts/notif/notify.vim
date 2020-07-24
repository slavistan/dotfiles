"""
""" Basic notification system based on nvim floats.
"""

" TODO(fix): Implement a mutex for accesses into g:timer_to_win
" TODO(feat): Highlight (:help winhighlight)
" TODO(feat): Error and Info notifications

" [ [timer_id, win_id], [timer_id, win_id], ... ]
let g:notif_stack = []

fun! KillAndRedraw(timer_id)

  " find index of window_id corresponding to timer. O(n).
  let index = 0
  for ii in range(len(g:notif_stack))
    if g:notif_stack[ii][0] == a:timer_id
      let index = ii
      break
    endif
  endfor

  " extract window id and height of window and kill it
  " TODO(fix): Do I need to delete buffer explicitly before killing the window?
  let notif_win_id = g:notif_stack[index][1]
  let win_height = nvim_win_get_config(notif_win_id)['height']
  call nvim_win_close(notif_win_id, 1)

  " shift notifications up
  for ii in range(index+1, len(g:notif_stack)-1)
    let win_id = g:notif_stack[ii][1]
    let wid_cfg = nvim_win_get_config(win_id)
    let win_cfg['row'] = win_cfg['row'] - win_height
    call nvim_win_set_config(win_id, win_cfg)
  endfor

  " remove timer from info structure
  call remove(g:notif_stack, index)

endfun

fun! NotifySend(title, body, ms)

  " Preparation
  let lines = [a:title] + a:body
  let max_width = 0
  for ii in range(len(lines))
    if len(lines[ii]) > max_width
      let max_width = len(lines[ii])
    endif
  endfor
  if max_width == 0
    return
  endif

  " Write lines to an unlisted buffer and spawn a window for it
  let notif_buf = nvim_create_buf(0, 1)
  call nvim_buf_set_lines(notif_buf, 0, -1, v:true, lines)
  let notif_win_id = nvim_open_win(notif_buf, 0, {'relative': 'editor',
        \ 'width': max_width, 'height': len(lines),
        \ 'col': &columns-1, 'row': 3, 'anchor': 'NE',
        \ 'style': 'minimal'})

  " Shift all existing notifications down by height of new notification
  for ii in range(len(g:notif_stack))
    let win_id = g:notif_stack[ii][1]
    let win_cfg = nvim_win_get_config(win_id)
    let win_cfg['row'] = win_cfg['row'] + len(lines)
    call nvim_win_set_config(win_id, win_cfg)
  endfor

  " Queue removal of window and store away information
  let timer_id = timer_start(a:ms, 'KillAndRedraw')
  let g:notif_stack = extend([[timer_id, notif_win_id]], g:notif_stack)

endfun

"""
""" Convenience wrapper
"""

fun! Notify(...)
  if a:0 == 2
    if type(a:1) == 1 && type(a:2) == 0
      call NotifySend(a:1, [], a:2)
    endif
  endif
endfun
