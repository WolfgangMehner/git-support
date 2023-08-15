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

let s:Features = gitsupport#config#Features()
let s:EnableLogging = s:Features.is_logging_enabled

function! s:WriteLog(prefix, chunks)
  if s:EnableLogging
    call writefile([(strftime('%c')).' '.a:prefix.' '.join(a:chunks, ' ')], expand('<sfile>:p:h').'/gitsupport.log', 'a')
  endif
endfunction

function! gitsupport#log#Info(...)
  call s:WriteLog('INFO', a:000)
endfunction

function! gitsupport#log#Error(...)
  call s:WriteLog('ERROR', a:000)
endfunction
