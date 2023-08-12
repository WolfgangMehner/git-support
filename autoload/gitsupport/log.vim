"-------------------------------------------------------------------------------
"
"          File:  log.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  12.08.2023
"      Revision:  ---
"       License:  Copyright (c) 2023, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:EnableLogging = 0

function! s:WriteLog(prefix, lines)
  if !s:EnableLogging
    return
  endif

  call writefile([a:prefix.' '.join(a:lines, ' ')], expand('<sfile>:p:h').'/gitsupport.log', 'a')
endfunction

function! gitsupport#log#Info(...)
  call s:WriteLog('INFO', a:000)
endfunction

function! gitsupport#log#Error(...)
  call s:WriteLog('ERROR', a:000)
endfunction
