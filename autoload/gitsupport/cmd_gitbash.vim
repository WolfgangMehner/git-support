"-------------------------------------------------------------------------------
"
"          File:  cmd_gitbash.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  13.03.2021
"      Revision:  ---
"       License:  Copyright (c) 2021, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:Features = gitsupport#config#Features()
let s:Exec = gitsupport#config#GitBashExecutable()

function! gitsupport#cmd_gitbash#FromCmdLine ()
  if s:Features.is_executable_bash == 0
    return s:ErrorMsg( 'can not execute git bash' )
  endif

  call gitsupport#run#RunDetach( s:Exec, [ '--login', '-i' ], 'env_std', 1 )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

