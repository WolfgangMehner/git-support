"-------------------------------------------------------------------------------
"
"          File:  cmd_commit.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  19.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_commit#FromCmdLine ( mode, q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )

  if a:mode == 'direct'
    return s:CommitDirect( args )
  elseif a:mode == 'file'
    return s:CommitFromFile( a:q_params )
  elseif a:mode == 'merge'
    return s:CommitWithMergeConflict()
  elseif a:mode == 'msg'
    return s:CommitWithMessage( a:q_params )
  else
    return s:ErrorMsg( 'unknown mode "'.a:mode.'"' )
  endif
endfunction

function! s:CommitDirect ( args )
  let args = a:args

  if index( args, '--dry-run' ) != -1
    " dry run in separate buffer
    " TODO
    return
  elseif ! empty( args ) || exists( '$GIT_EDITOR' ) || g:Git_Editor != ''
    " run assuming sensible parameters ...
    " or assuming a correctly set "$GIT_EDITOR", e.g.
    " - xterm -e vim
    " - gvim -f
    " TODO
  elseif empty( args )
    " empty parameter list
    return s:ErrorMsg ( 'The command :GitCommit currently can not be used this way.',
          \ 'Set $GIT_EDITOR properly, or use the configuration variable "g:Git_Editor".',
          \ 'Alternatively, supply the message using either the -m or -F options, or by',
          \ 'using the special commands :GitCommitFile, :GitCommitMerge, or :GitCommitMsg.' )
  endif

  return
endfunction

function! s:CommitWithMergeConflict ()
  " find the file "MERGE_HEAD"
  let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'git/MERGE_HEAD' )

  if ret_code != 0 || !filereadable( filename )
    return s:ErrorMsg(
          \ 'could not read the file ".git/MERGE_HEAD",',
          \ 'there does not seem to be a merge conflict' )
  endif

  " message from ./.git/MERGE_MSG
  let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'git/MERGE_MSG' )

  if ret_code != 0 || !filereadable( filename )
    return s:ErrorMsg(
          \ 'could not read the file ".git/MERGE_MSG",',
          \ 'but found ./git/MERGE_HEAD (see :help GitCommitMerge)' )
  endif

  return gitsupport#run#RunDirect( '', ['commit', '-F', filename], 'env_std', 1 )
endfunction

function! s:CommitFromFile ( filename )
  try
    update
  catch /E45.*/
    call s:ErrorMsg( 'could not write the file: '.bufname('%') )
  catch /.*/
    call s:ErrorMsg( 'unknown error while writing the file: '.bufname('%') )
  endtry

  if empty( a:filename ) | let filename = expand('%')
  else                   | let filename = a:filename
  endif

  return gitsupport#run#RunDirect( '', ['commit', '-F', filename], 'env_std', 1 )
endfunction

function! s:CommitWithMessage ( message )
  return gitsupport#run#RunDirect( '', ['commit', '-m', a:message], 'env_std', 1 )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

