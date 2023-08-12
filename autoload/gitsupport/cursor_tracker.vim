"-------------------------------------------------------------------------------
"
"          File:  cursor_tracker.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  19.03.2022
"      Revision:  12.08.2023
"       License:  Copyright (c) 2022, Wolfgang Mehner
"-------------------------------------------------------------------------------

if !exists("s:CursorTrackerState")
  let s:CursorTrackerState = {
        \ "buffers": {}
        \ }
endif

function! s:Callback(action)
  let buf_nr = expand('<abuf>')
  let action = a:action

  if action == 'close'
    call gitsupport#log#Info('remove cursor tracker autocommands for buffer', buf_nr)
    call remove(s:CursorTrackerState.buffers, buf_nr)
    call s:ClearAutocmd(buf_nr)
  else
    let buffer_info = get(s:CursorTrackerState.buffers, buf_nr, {'ids': {}})
    for [ id, Callback ] in items(buffer_info.ids)
      call Callback(str2nr(buf_nr), action)
    endfor
  endif
endfunction

function! gitsupport#cursor_tracker#Add(buf_nr, id, callback)
  let buf_nr = string(a:buf_nr)
  let id = a:id
  let buffers = s:CursorTrackerState.buffers

  if !has_key(buffers, buf_nr)
    call gitsupport#log#Info('add cursor tracker autocommands for buffer', buf_nr)
    call s:InitAutocmd(buf_nr)
    let buffers[buf_nr] = {'ids': {}}
  endif
  let buffer_info = buffers[buf_nr]
  if !has_key(buffer_info.ids, id)
    call gitsupport#log#Info('add cursor tracker for buffer', buf_nr, 'and ID', id)
    let buffer_info.ids[id] = a:callback
  endif
endfunction

function! s:InitAutocmd(buf_nr)
  augroup GitSupportCursorTracker
  exec 'autocmd CursorMoved,CursorMovedI <buffer='.a:buf_nr.'> call <SID>Callback("move")'
  exec 'autocmd CursorHold,CursorHoldI   <buffer='.a:buf_nr.'> call <SID>Callback("hold")'
  exec 'autocmd BufEnter                 <buffer='.a:buf_nr.'> call <SID>Callback("enter")'
  exec 'autocmd BufLeave                 <buffer='.a:buf_nr.'> call <SID>Callback("leave")'
  exec 'autocmd BufUnload                <buffer='.a:buf_nr.'> call <SID>Callback("close")'
  augroup END
endfunction

function! s:ClearAutocmd(buf_nr)
  augroup GitSupportCursorTracker
  exec 'autocmd! CursorMoved,CursorMovedI <buffer='.a:buf_nr.'>'
  exec 'autocmd! CursorHold,CursorHoldI   <buffer='.a:buf_nr.'>'
  exec 'autocmd! BufEnter                 <buffer='.a:buf_nr.'>'
  exec 'autocmd! BufLeave                 <buffer='.a:buf_nr.'>'
  exec 'autocmd! BufUnload                <buffer='.a:buf_nr.'>'
  augroup END
endfunction
