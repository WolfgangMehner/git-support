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
  let s:command_details = gitsupport#data#LoadData( 'commandline' )
endfunction

function! s:GetCommandDetails ( cmd, key, default )
  let details = get( s:command_details, a:cmd, {} )
  return get( details, a:key, a:default )
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
  let main_cmd = ''
  let sub_cmd = ''
  let idx1 = 0

  let general_command = match( a:head, '^\cGit\%(!\|Run\|Buf\|Bash\|Term\)\?\s' ) == 0
  if general_command
    let main_cmd = matchstr( a:head, '^Git\w*\s\+\zs\S\+' )
    let idx1 = matchend( a:head, '^Git\w*\s\+\S*' )

    if len( a:head ) == idx1
      return [ tolower( main_cmd ), '', 1 ]
    endif
  else
    let main_cmd = matchstr( a:head, '^\cGit\zs[a-z]\+' )
    let idx1 = 3 + len( main_cmd )
  endif

  if match( a:head, '^\s', idx1 ) >= 0
    let sub_cmd = matchstr( a:head, '^\s\+\zs\S\+', idx1 )
    let idx2 = matchend( a:head, '^\s\+\S*', idx1 )

    if len( a:head ) == idx2
      return [ tolower( main_cmd ), tolower( sub_cmd ), 2 ]
    endif
  endif

  return [ tolower( main_cmd ), tolower( sub_cmd ), 0 ]
endfunction

function! s:FilterOnWord ( wordlist, lead )
  return filter( copy( a:wordlist ), 'v:val =~ "\\V\\<'.escape(a:lead,'\').'\\w\\*"' )
endfunction

function! s:FilterOnStart ( wordlist, lead )
  return filter( copy( a:wordlist ), 'v:val =~ "\\V\\^'.escape(a:lead,'\').'"' )
endfunction

function! gitsupport#commandline#Complete ( ArgLead, CmdLine, CursorPos )
  let argument_lead = a:ArgLead
  let cmdline_head = strpart( a:CmdLine, 0, a:CursorPos )

  let [ git_cmd, sub_cmd, complete_command ] = s:SubcommandAnalysis( cmdline_head )
  if complete_command == 1
    return s:FilterOnWord( s:command_list, git_cmd )
  endif

  let [ prep_prefix, prep_lead ] = s:PreprocessLead( argument_lead )

  if prep_lead =~# '^-'
    let options = s:GetCommandDetails( git_cmd, 'options', [] )
    return s:FilterOnStart( options, prep_lead )
  endif

  let cwd = gitsupport#services_path#GetWorkingDir()
  let git_objects = []
  if s:GetCommandDetails( git_cmd, 'include_branches', 0 )
    let branches = s:GetListFromGit( ['branch', '-a'], cwd )
    let git_objects += s:ProcessBranchList( branches )
  endif
  if s:GetCommandDetails( git_cmd, 'include_remotes', 0 )
    let git_objects += s:GetListFromGit( ['remote'], cwd )
  endif
  if s:GetCommandDetails( git_cmd, 'include_tags', 0 )
    let git_objects += s:GetListFromGit( ['tag'], cwd )
  endif

  let git_objects = s:FilterOnWord( git_objects, prep_lead )
  call map( git_objects, 'prep_prefix.v:val' )

  let all_returns = []

  if complete_command == 2
    let cmds = s:GetCommandDetails( git_cmd, 'subcommands', [] )
    let all_returns += s:FilterOnWord( cmds, sub_cmd )
  endif

  let all_returns += git_objects

  return all_returns
endfunction

