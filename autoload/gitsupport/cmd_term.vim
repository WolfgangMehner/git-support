"-------------------------------------------------------------------------------
"
"          File:  cmd_term.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  23.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:Features = gitsupport#config#Features()

function! gitsupport#cmd_term#FromCmdLine ( q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_term#Run( args, '' )
endfunction

function! gitsupport#cmd_term#Run ( args, dir_hint )
  if !s:Features.is_avaiable_term
    return s:WarningMsg ( 'can not execute git terminal' )
  endif

  let args = [ gitsupport#config#GitExecutable() ] + a:args
  let env = gitsupport#config#Env()
  let cwd = gitsupport#services_path#GetWorkingDir( a:dir_hint )
  let cwd = cwd != '' ? cwd : '.'

  let title = 'git'
  if len( args ) >= 2
    let title = 'git '.args[1]
  end

  try
    if s:Features.running_nvim
      " :TODO:11.10.2017 18:03:WM: better handling than using 'job_id', but ensures
      " successful operation for know
      above new
      let job_id = termopen( args, {
            \ 'term_name' : title,
            \ 'cwd' : cwd,
            \ 'env' : env,
            \ } )

      silent exe 'file '.fnameescape( title.' -'.job_id.'-' )
    else
      let buf_nr = term_start( args, {
            \ 'term_name' : title,
            \ 'cwd' : cwd,
            \ 'env' : env,
            \ } )
    endif
  catch /.*/
    return s:WarningMsg(
          \ "internal error " . v:exception,
          \ " - occurred at " . v:throwpoint )
  endtry
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

function! s:WarningMsg ( ... )
  echohl WarningMsg
  echo join( a:000, "\n" )
  echohl None
endfunction

