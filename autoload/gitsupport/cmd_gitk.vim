"-------------------------------------------------------------------------------
"
"          File:  cmd_gitk.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  16.02.2021
"      Revision:  ---
"       License:  Copyright (c) 2021, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:Features = gitsupport#config#Features()

function! gitsupport#cmd_gitk#FromCmdLine ( q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_gitk#Run( args, '' )
endfunction

function! gitsupport#cmd_gitk#Run ( args, dir_hint )
  let args = [ gitsupport#config#GitKExecutable() ] + a:args
  let env = gitsupport#config#Env()

  if ! s:Features.is_executable_gitk
    return s:ErrorMsg( 'can not execute gitk' )
  endif

  call gitsupport#run#RunDetach( args[0], args[1:], 'env_std', 1 )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

