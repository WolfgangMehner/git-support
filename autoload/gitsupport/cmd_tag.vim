"-------------------------------------------------------------------------------
"
"          File:  cmd_tag.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  30.11.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_tag#FromCmdLine ( q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_tag#OpenBuffer ( args )
endfunction

function! gitsupport#cmd_tag#OpenBuffer ( params )
  let params = a:params

  if empty ( params )
        \ || index ( params, '-l' ) != -1
        \ || index ( params, '--list' ) != -1
        \ || index ( params, '--contains' ) != -1
        \ || match ( params, '^-n\d\?' ) != -1
    call gitsupport#run#OpenBuffer( 'Git - tag' )
    call s:Run( params )

    nnoremap          <buffer> sh     :call <SID>Help()<CR>
    nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
    nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
    nnoremap <silent> <buffer> u      :call <SID>Update()<CR>
    nnoremap <silent> <buffer> st     :call <SID>Show("tag")<CR>
    nnoremap <silent> <buffer> cs     :call <SID>Show("commit")<CR>

    let b:GitSupport_Param = params
  else
    let git_exec = gitsupport#config#GitExecutable()
    let git_env  = gitsupport#config#Env()
    return gitsupport#run#RunDirect( git_exec, ['tag'] + params, 'env', git_env )
  endif
endfunction

function! s:Help ()
  let text =
        \  "git tag\n\n"
        \ ."sh S-F1 : help\n"
        \ ."q       : close\n"
        \ ."u       : update"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params )
  call gitsupport#run#RunToBuffer( '', ['tag'] + a:params )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param )
endfunction

function! s:Show ( mode )
  let tag_name = s:GetTag()

  if a:mode == 'tag'
    call gitsupport#cmd_show#OpenBuffer( [ tag_name ] )
  elseif a:mode == 'commit'
    call gitsupport#cmd_show#OpenBuffer( [ tag_name.'^{commit}' ] )
  endif
endfunction

function! s:GetTag()
  let t_pos = search ( '\m\_^\S', 'bcnW' )      " the position of the tag name
  if t_pos == 0
    return ''
  endif
  return matchstr ( getline(t_pos), '^\S\+' )
endfunction

