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
"      Revision:  ---
"       License:  Copyright (c) 2022, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cursor_tracker#Add ( callback )
  augroup GitSupportCursorTracker
  exec 'autocmd CursorMoved,CursorMovedI <buffer> call' a:callback '("move")'
  exec 'autocmd CursorHold,CursorHoldI   <buffer> call' a:callback '("hold")'
  exec 'autocmd BufLeave                 <buffer> call' a:callback '("leave")'
  augroup END
endfunction

function! gitsupport#cursor_tracker#Clear ( callback )
  augroup GitSupportCursorTracker
  exec 'autocmd! CursorMoved,CursorMovedI <buffer> call' a:callback '("move")'
  exec 'autocmd! CursorHold,CursorHoldI   <buffer> call' a:callback '("hold")'
  exec 'autocmd! BufLeave                 <buffer> call' a:callback '("leave")'
  augroup END
endfunction
