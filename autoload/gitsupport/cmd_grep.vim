"-------------------------------------------------------------------------------
"
"          File:  cmd_grep.vim
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

if has( 'conceal' )
  let s:use_conceal = 1
else
  let s:use_conceal = 0
endif

function! gitsupport#cmd_grep#FromCmdLine ( mode, q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_grep#OpenBuffer( a:mode, args )
endfunction

function! gitsupport#cmd_grep#OpenBuffer ( mode, params )
  let params = a:params

  if a:mode == 'top'
    let [ sh_ret, base ] = gitsupport#services_cwd#GetGitDir()

    " could not get top-level?
    if sh_ret != 0 || base == '' | return | endif

    let cwd = base
  else
    let cwd = gitsupport#services_cwd#Get()
  endif

  call gitsupport#run#OpenBuffer( 'Git - grep' )
  call s:Run( params, cwd )

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
  nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

  nnoremap <silent> <buffer> of      :call <SID>Jump("file")<CR>
  nnoremap <silent> <buffer> oj      :call <SID>Jump("line")<CR>
  nnoremap <silent> <buffer> <Enter> :call <SID>Jump("line")<CR>

  let b:GitSupport_Param = params
  let b:GitSupport_CWD = cwd
endfunction

function! s:Help ()
  let text =
        \  "git grep\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
        \ ."\n"
        \ ."line under cursor ...\n"
        \ ."of      : file under cursor: open file (edit)\n"
        \ ."oj      : file under cursor: open and jump to the corresponding line\n"
        \ ."<Enter> : file under cursor: open and jump to the corresponding line"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd )
  let add_args = s:use_conceal ? ['-z'] : []
  call gitsupport#run#RunToBuffer( '', ['grep'] + add_args + a:params, 'callback', function( 's:Wrap' ), 'cwd', a:cwd )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD )
endfunction

function! s:Wrap ()
  let &l:filetype = 'gitsgrep'
  let &l:foldtext = '<SNR>'.s:SID().'_Grep_FoldText()'
  if s:use_conceal
    let &l:conceallevel  = 2
    let &l:concealcursor = 'nc'
  end
endfunction

function! s:Jump ( mode )
  let [ f_name, f_line ] = s:GetFile()

  if f_name == ''
    return s:ErrorMsg( 'no file under the cursor' )
  endif

  if a:mode == 'file'
  elseif a:mode == 'line'
  endif
endfunction

function! s:GetFile ()
  if has( 'conceal' )
    let mlist = matchlist( getline('.'), '^\(\p\+\)\%x00\(\d\+\)\%x00' )
  else
    let mlist = matchlist( getline('.'), '^\([^:]\+\):\%(\(\d\+\):\)\?' )
  endif

  if empty( mlist )
    return [ '', -1 ]
  endif

  let f_name = mlist[1]
  let f_line = mlist[2]

  if f_line == ''
    return [ f_name, -1 ]
  else
    return [ f_name, str2nr( f_line ) ]
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

function! s:SID ()
  return matchstr( expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$' )
endfunction

