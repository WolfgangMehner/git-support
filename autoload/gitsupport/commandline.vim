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

function! s:PreloadData ()
  let basic_data = gitsupport#data#LoadData( 'basic' )
  let s:command_list = get( basic_data, 'commands', [] )
endfunction

call s:PreloadData()

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

function! s:PreprocessLead ( lead )
  let idx = 0

  if match( a:lead, '^--[^=]\+=' ) == 0
    " prefixed by --option=
    let idx = matchend( a:lead, '^--[^=]\+=' )
  elseif match( a:lead, '\.\.\.\?\|:' ) >= 0
    " split at a "..", "...", or ":"
    let idx = matchend( a:lead, '\.\.\.\?\|:' )
  endif

  if idx > 0
    return [ strpart( a:lead, 0, idx ), strpart( a:lead, idx ) ]
  else
    return [ '', a:lead ]
  endif
endfunction

function! s:SubcommandAnalysis ( head )
  let general_command = match( a:head, '^\cGit\%(!\|Run\|Buf\|Bash\|Term\)\?\s' ) == 0
  if general_command
    let sub_cmd = matchstr( a:head, '^Git\w*\s\+\zs\S\+' )
    return [ tolower( sub_cmd ), ( len( a:head ) == matchend( a:head, '^Git\w*\s\+\S*' ) ) ]
  endif

  let sub_cmd = matchstr( a:head, '^\cGit\zs[a-z]\+\ze\s' )
  return [ tolower( sub_cmd ), 0 ]
endfunction

function! gitsupport#commandline#Complete ( ArgLead, CmdLine, CursorPos )
  let argument_lead = a:ArgLead
  let cmdline_head = strpart( a:CmdLine, 0, a:CursorPos )

  let [ sub_cmd, complete_command ] = s:SubcommandAnalysis( cmdline_head )
  if complete_command
    return s:FilterWithLead( s:command_list, sub_cmd )
  endif

  let cwd = gitsupport#services_path#GetWorkingDir()
  let branches = s:GetListFromGit( ['branch', '-a'], cwd )
  let branches = s:ProcessBranchList( branches )
  let remotes = s:GetListFromGit( ['remote'], cwd )
  let tags = s:GetListFromGit( ['tag'], cwd )

  let [ prep_prefix, prep_lead ] = s:PreprocessLead( argument_lead )
  let git_objects = s:FilterWithLead( branches + tags + remotes, prep_lead )
  call map( git_objects, 'prep_prefix.v:val' )

  return git_objects
endfunction

