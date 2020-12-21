"-------------------------------------------------------------------------------
"
"          File:  cmd_log.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  16.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_log#FromCmdLine ( q_params, line1, line2, count )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  if a:count > 0 
    let range_info = [ a:line1, a:line2 ]
  else
    let range_info = []
  endif
  return gitsupport#cmd_log#OpenBuffer( args, range_info, '' )
endfunction

function! gitsupport#cmd_log#OpenBuffer ( params, range_info, dir_hint )
  let params = a:params
  let cwd = gitsupport#services_path#GetWorkingDir( a:dir_hint )

  if len( a:range_info ) == 2
    let params = [ '-L', a:range_info[0].','.a:range_info[1].':'.expand('%') ] + params
  endif

  call gitsupport#run#OpenBuffer( 'Git - log' )
  call s:Run( params, cwd )

  let &l:filetype = 'gitslog'
  let &l:foldmethod = 'syntax'
  let &l:foldlevel = 3
  let &l:foldtext = 'GitS_FoldLog()'

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
  nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

  nnoremap <expr>   <buffer> ch     <SID>Checkout()
  nnoremap <expr>   <buffer> cr     <SID>Create()
  nnoremap <silent> <buffer> cs     :call <SID>Show()<CR>
  nnoremap <silent> <buffer> sh     :call <SID>Show()<CR>
  nnoremap <expr>   <buffer> ta     <SID>Tag()

  let b:GitSupport_Param = params
  let b:GitSupport_CWD = cwd
endfunction

function! s:Help ()
  let text =
        \  "git log\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
        \ ."\n"
        \ ."commit under cursor ...\n"
        \ ."ch      : checkout\n"
        \ ."cr      : use as starting point for creating a new branch\n"
        \ ."cs / sh : show the commit\n"
        \ ."ta      : tag the commit\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd )
  call gitsupport#run#RunToBuffer( '', ['log'] + a:params, 'cwd', a:cwd )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD )
endfunction

function! s:Show (  )
  let commit_name = s:GetCommit()

  if commit_name == ''
    return s:ErrorMsg( 'no commit under the cursor' )
  endif

  return gitsupport#cmd_show#OpenBuffer( [ commit_name ] )
endfunction

function! s:Checkout ()
  let commit_name = s:GetCommit()
  return gitsupport#common#AssembleCmdLine( ':GitCheckout '.shellescape( commit_name ), '' )
endfunction

function! s:Create ()
  let commit_name = s:GetCommit()
  return gitsupport#common#AssembleCmdLine( ':GitBranch ', ' '.shellescape( commit_name ) )
endfunction

function! s:Tag ()
  let commit_name = s:GetCommit()
  return gitsupport#common#AssembleCmdLine( ':GitTag ', ' '.shellescape( commit_name ) )
endfunction

function! s:GetCommit (  )
  " in case of "git log --oneline"
  let line_str = getline('.')
  let commit = matchstr( line_str, '^\x\{6,}\ze\(\s\|\_$\)' )
  if commit != ''
    return commit
  endif

  let c_pos = search( '\m\_^commit \x', 'bcnW' )

  if c_pos == 0
    return ''
  else
    return matchstr( getline(c_pos), '^commit\s\zs\x\+' )
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

