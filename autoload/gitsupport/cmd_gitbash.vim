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

function! gitsupport#cmd_gitbash#FromCmdLine ( param )
  if s:Features.is_executable_bash == 0
    return s:ErrorMsg( 'can not execute git bash' )
  endif

  let cwd = gitsupport#services_path#GetWorkingDir()

  if a:param =~ '^\s*$'
    " no parameters: start interactive mode in background
    call gitsupport#run#RunDetach( s:Exec, [ '--login', '-i' ], 'cwd', cwd, 'env_std', 1 )
  else
    " otherwise: block editor and execute command
    call s:RunWithParams( a:param, cwd )
  endif
endfunction

function! s:RunWithParams ( param, cwd )
  let param = escape( a:param, '%#' )
  let saved_dir = gitsupport#services_path#SetDir( a:cwd )
  exec '!'.shellescape( s:Exec ).' --login -c '.shellescape( 'git '.param )
  call gitsupport#services_path#ResetDir( saved_dir )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

