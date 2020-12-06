"-------------------------------------------------------------------------------
"
"          File:  cmd_stash.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  02.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_stash#FromCmdLine ( q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_stash#OpenBuffer ( args )
endfunction

function! gitsupport#cmd_stash#OpenBuffer ( params )
  let params = a:params
  let subcmd = get ( params, 0, '' )

  if subcmd == 'list'
    call gitsupport#run#OpenBuffer( 'Git - stash list' )
    call s:Run( params )

    command! -nargs=0 -buffer  Help   :call <SID>Help()
    nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
    nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
    nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

    nnoremap <expr>   <buffer> sa     <SID>Save()
    nnoremap          <buffer> pu     :call <SID>Create()<CR>
    nnoremap <expr>   <buffer> ap     <SID>Apply()
    nnoremap <expr>   <buffer> dr     <SID>Drop()
    nnoremap <expr>   <buffer> po     <SID>Pop()
    nnoremap <expr>   <buffer> br     <SID>Branch()
    nnoremap <silent> <buffer> sh     :call <SID>Show("show")<CR>
    nnoremap <silent> <buffer> sp     :call <SID>Show("patch")<CR>

    let b:GitSupport_Param = params
  elseif subcmd == 'show'
    call gitsupport#run#OpenBuffer( 'Git - stash show' )
    call s:Run( params )

    command! -nargs=0 -buffer  Help   :call <SID>HelpShow()
    nnoremap          <buffer> <S-F1> :call <SID>HelpShow()<CR>
    nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
    nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

    let b:GitSupport_Param = params
  else
    return gitsupport#run#RunDirect( '', ['stash'] + params, 'env_std', 1 )
  endif
endfunction

function! s:Help ()
  let text =
        \  "git stash list\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
        \ ."\n"
        \ ."sa      : save with a message\n"
        \ ."pu      : create a new stash (push)\n"
        \ ."\n"
        \ ."stash under cursor ...\n"
        \ ."ap      : apply\n"
        \ ."po      : pop\n"
        \ ."dr      : drop\n"
        \ ."br      : create and checkout a new branch\n"
        \ ."sh      : show the stash under the cursor\n"
        \ ."sp      : show the stash in patch form\n"
  echo text
endfunction

function! s:HelpShow ()
  let text =
        \  "git stash show\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params )
  call gitsupport#run#RunToBuffer( '', ['stash'] + a:params, 'callback', function( 's:Wrap' ) )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param )
endfunction

function! s:Save ()
  return gitsupport#common#AssembleCmdLine( ':GitStash save "', '"' )
endfunction

function! s:Create ()
  return gitsupport#run#RunDirect( '', ['stash'], 'env_std', 1 )
endfunction

function! s:Apply ()
  let stash_name = s:GetStash()
  return gitsupport#common#AssembleCmdLine( ':GitStash apply --index', ' '.stash_name )
endfunction

function! s:Branch ()
  let stash_name = s:GetStash()
  return gitsupport#common#AssembleCmdLine( ':GitStash branch ', ' '.stash_name )
endfunction

function! s:Drop ()
  let stash_name = s:GetStash()
  return gitsupport#common#AssembleCmdLine( ':GitStash drop '.stash_name, '' )
endfunction

function! s:Pop ()
  let stash_name = s:GetStash()
  return gitsupport#common#AssembleCmdLine( ':GitStash pop --index', ' '.stash_name )
endfunction

function! s:Show ( mode )
  let stash_name = s:GetStash()

  if stash_name == ''
    return s:ErrorMsg( 'no stash under the cursor' )
  endif

  if a:mode == 'show'
    call gitsupport#cmd_stash#OpenBuffer( [ 'show', stash_name ] )
  elseif a:mode == 'patch'
    call gitsupport#cmd_stash#OpenBuffer( [ 'show', '-p', stash_name ] )
  endif
endfunction

function! s:GetStash()
	let line = getline('.')
	return matchstr( line, '^stash@{\d\+}' )
endfunction

function! s:Wrap ()
  setlocal filetype=gitsdiff
  setlocal foldmethod=syntax
	normal! zR   | " open all folds (closed by the syntax highlighting)
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

