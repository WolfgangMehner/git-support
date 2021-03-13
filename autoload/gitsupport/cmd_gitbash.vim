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

  let param = escape( a:param, '%#' )

  if param =~ '^\s*$'
    " no parameters: start interactive mode in background
    silent exe '!start '.s:Exec.' --login -i'
  else
    " otherwise: block editor and execute command
    silent exe '!'.s:Exec.' --login -c '.shellescape ( 'git '.param )
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

