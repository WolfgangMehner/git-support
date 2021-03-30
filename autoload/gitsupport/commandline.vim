"-------------------------------------------------------------------------------
"
"          File:  commandline.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  30.03.2021
"      Revision:  ---
"       License:  Copyright (c) 2021, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! s:ProcessBranchList ( branch_list )
  let ret_list = []

  for branch in a:branch_list
    " remove leading whitespaces, "*" (current branch), and "remotes/"
    " remove trailing "-> ..." (as in "origin/HEAD -> origin/master")
    let branch = matchstr( branch, '^[ *]*\%(remotes\/\)\?\zs.\{-}\ze\%(\s*->.*\)\?$' )
    call add( ret_list, branch )
  endfor
  return ret_list + [ 'HEAD', 'ORIG_HEAD', 'FETCH_HEAD', 'MERGE_HEAD' ]
endfunction

function! s:GetListFromGit ( cmd, cwd )
  let [ ret_code, ret_txt ] = gitsupport#run#RunDirect( '', a:cmd, 'cwd', a:cwd, 'mode', 'return' )

  if ret_code == 0
    return split( ret_txt, "\n" )
  else
    return []
  endif
endfunction

function! s:FilterWithLead ( wordlist, lead )
  return filter( a:wordlist, 'v:val =~ "\\V\\<'.escape(a:lead,'\').'\\w\\*"' )
endfunction

function! gitsupport#commandline#Complete ( ArgLead, CmdLine, CursorPos )
  let cwd = gitsupport#services_path#GetWorkingDir()
  let branches = s:GetListFromGit( ['branch', '-a'], cwd )
  let branches = s:ProcessBranchList( branches )
  let remotes = s:GetListFromGit( ['remote'], cwd )
  let tags = s:GetListFromGit( ['tag'], cwd )

  return s:FilterWithLead( branches + tags + remotes, a:ArgLead )
endfunction
