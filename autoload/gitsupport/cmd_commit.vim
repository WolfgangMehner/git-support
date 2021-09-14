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
    call gitsupport#common#ExpandWildcards( args )
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

  if empty( args ) && empty( g:Git_Editor ) && !exists( '$GIT_EDITOR' )
    " empty parameter list
    return s:ErrorMsg ( 'The command :GitCommit currently can not be used this way.',
          \ 'Set $GIT_EDITOR properly, or use the configuration variable "g:Git_Editor".',
          \ 'Alternatively, supply the message using either the -m or -F options, or by',
          \ 'using the special commands :GitCommitFile, :GitCommitMerge, or :GitCommitMsg.' )
  elseif index( args, '--dry-run' ) != -1
    return s:DryRun( args )
  else
    return s:CommitRun( args )
  endif
endfunction

function! s:CommitRun ( args )
  " run assuming sensible parameters ...
  " or assuming a correctly set "$GIT_EDITOR", e.g.
  " - xterm -e vim
  " - gvim -f
  let env = gitsupport#config#Env()

  if g:Git_Editor != ''
    if g:Git_Editor == 'vim'
      let bash_exec = gitsupport#config#GitBashExecutable()

      if bash_exec =~# '\cxterm'
        let env.GIT_EDITOR = bash_exec.' '.g:Xterm_Options.' -title "git commit" -e vim '
      else
        let env.GIT_EDITOR = bash_exec.' '.g:Xterm_Options.' -e vim '
      endif
    elseif g:Git_Editor == 'gvim'
      let env.GIT_EDITOR = 'gvim -f'
    else
      return s:ErrorMsg( 'invalid setting for g:Git_Editor: "'.g:Git_Editor.'"' )
    endif
  endif

  return gitsupport#run#RunDirect( '', ['commit'] + a:args, 'env', env )
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

function! s:DryRun ( args )
  let args = a:args
  let cwd = gitsupport#services_path#GetWorkingDir()

  call gitsupport#run#OpenBuffer( 'Git - commit --dry-run' )

  let &l:filetype = 'gitsstatus'
  let &l:foldmethod = 'syntax'
  let &l:foldlevel = s:ListHas( args, [ '-v', '--verbose' ] ) ? 2 : 1
  let &l:foldtext = 'GitS_FoldLog()'

  call s:Run( args, cwd, 0 )

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
  nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

  let b:GitSupport_Param = args
  let b:GitSupport_CWD = cwd
endfunction

function! s:Help ()
  let text =
        \  "git commit (dry-run)\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd, restore_cursor )
  call gitsupport#run#RunToBuffer( '', ['commit'] + a:params,
        \ 'cwd', a:cwd,
        \ 'env_std', 1,
        \ 'restore_cursor', a:restore_cursor )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD, 1 )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

function! s:ListHas ( list, items )
  for item in a:items
    if index( a:list, item ) >= 0
      return 1
    endif
  endfor
  return 0
endfunction

