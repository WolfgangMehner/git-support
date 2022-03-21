"-------------------------------------------------------------------------------
"
"          File:  cmd_remote.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  06.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_remote#FromCmdLine ( q_params, cmd_mods )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_remote#OpenBuffer( args, a:cmd_mods )
endfunction

function! gitsupport#cmd_remote#OpenBuffer ( params, cmd_mods )
  let params = a:params
  let cwd = gitsupport#services_path#GetWorkingDir()

  if empty( params )
    call gitsupport#run#OpenBuffer( 'Git - remote', 'mods', a:cmd_mods )
    call s:Run( params, cwd, 0 )

    command! -nargs=0 -buffer  Help   :call <SID>Help()
    nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
    nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
    nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

    nnoremap <expr>   <buffer> fe     <SID>Fetch()
    nnoremap <expr>   <buffer> ph     <SID>Push()
    nnoremap <expr>   <buffer> pl     <SID>Pull()
    nnoremap <expr>   <buffer> rm     <SID>Remove()
    nnoremap <expr>   <buffer> rn     <SID>Rename()
    nnoremap <expr>   <buffer> su     <SID>SetUrl()
    nnoremap <silent> <buffer> sh     :call <SID>Show()<CR>

    let b:GitSupport_Param = params
    let b:GitSupport_CWD = cwd
  else
    return gitsupport#run#RunDirect( '', ['remote'] + params, 'env_std', 1 )
  endif
endfunction

function! s:Help ()
  let text =
        \  "git remote\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
        \ ."\n"
        \ ."remote under cursor ...\n"
        \ ."fe      : fetch\n"
        \ ."ph      : push\n"
        \ ."pl      : pull\n"
        \ ."rm      : remove\n"
        \ ."rn      : rename\n"
        \ ."su      : set-url\n"
        \ ."sh      : show\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd, restore_cursor )
  call gitsupport#run#RunToBuffer( '', ['remote', '-v'] + a:params,
        \ 'cwd', a:cwd,
        \ 'restore_cursor', a:restore_cursor )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD, 1 )
endfunction

function! s:Fetch ()
  let [ rmt_name, rmt_url ] = s:GetRemote()
  return gitsupport#common#AssembleCmdLine( ':GitFetch '.rmt_name, '' )
endfunction

function! s:Pull ()
  let [ rmt_name, rmt_url ] = s:GetRemote()
  return gitsupport#common#AssembleCmdLine( ':GitPull '.rmt_name, '' )
endfunction

function! s:Push ()
  let [ rmt_name, rmt_url ] = s:GetRemote()
  return gitsupport#common#AssembleCmdLine( ':GitPush '.rmt_name, '' )
endfunction

function! s:Remove ()
  let [ rmt_name, rmt_url ] = s:GetRemote()
  return gitsupport#common#AssembleCmdLine( ':GitRemote rm '.rmt_name, '' )
endfunction

function! s:Rename ()
  let [ rmt_name, rmt_url ] = s:GetRemote()
  return gitsupport#common#AssembleCmdLine( ':GitRemote rename '.rmt_name.' ', '' )
endfunction

function! s:SetUrl ()
  let [ rmt_name, rmt_url ] = s:GetRemote()
  return gitsupport#common#AssembleCmdLine( ':GitRemote set-url '.rmt_name.' '.shellescape( rmt_url ), '' )
endfunction

function! s:Show ()
  let [ rmt_name, rmt_url ] = s:GetRemote()

  if rmt_name == ''
    return s:ErrorMsg( 'no remote under the cursor' )
  endif

  return gitsupport#run#RunDirect( '', ['remote', 'show', rmt_name], 'env_std', 1 )
endfunction

function! s:GetRemote()
  let line = getline('.')
  let mlist = matchlist( line, '^\s*\(\S\+\)\s\+\(.\+\)\s\+(\w\+)$' )

  if empty( mlist )
    return [ '', '' ]
  else
    return mlist[1:2]
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

