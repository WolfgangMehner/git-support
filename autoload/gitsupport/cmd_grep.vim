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
  let cwd = gitsupport#services_path#GetWorkingDir()

  if a:mode == 'top'
    let [ sh_ret, base ] = gitsupport#services_path#GetGitDir( 'top', cwd )
    if sh_ret != 0 || base == ''
      return s:ErrorMsg( 'could not obtain the repo base directory' )
    endif

    let cwd = base
  endif

  call gitsupport#run#OpenBuffer( 'Git - grep' )

  let &l:filetype = 'gitsgrep'
  let &l:foldmethod = 'syntax'
  let &l:foldlevel = 1
  let &l:foldtext = '<SNR>'.s:SID().'_FoldText()'
  if s:use_conceal
    let &l:conceallevel  = 2
    let &l:concealcursor = 'nc'
  end

  call s:Run( params, cwd, 0 )

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
        \ ."<Enter> : file under cursor: open and jump to the corresponding line\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd, restore_cursor )
  let add_args = s:use_conceal ? ['-z'] : []
  call gitsupport#run#RunToBuffer( '', ['grep'] + add_args + a:params,
        \ 'cwd', a:cwd,
        \ 'restore_cursor', a:restore_cursor )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD, 1 )
endfunction

function! s:Jump ( mode )
  let [ file_name, file_line ] = s:GetFile( '.' )

  if file_name == ''
    return s:ErrorMsg( 'no file under the cursor' )
  endif

  if b:GitSupport_CWD != ''
    let file_name = resolve( fnamemodify( b:GitSupport_CWD.'/'.file_name, ':p' ) )
  endif

  if a:mode == 'file'
    call gitsupport#run#OpenFile( file_name )
  elseif a:mode == 'line'
    call gitsupport#run#OpenFile( file_name, 'line', file_line )
  endif
endfunction

function! s:GetFile ( bufferline )
  if s:use_conceal
    let mlist = matchlist( getline(a:bufferline), '^\(\p\+\)\%x00\(\d\+\)\%x00' )
  else
    let mlist = matchlist( getline(a:bufferline), '^\([^:]\+\):\%(\(\d\+\):\)\?' )
  endif

  if empty( mlist )
    return [ '', -1 ]
  endif

  let file_name = mlist[1]
  let file_line = mlist[2]

  if file_line == ''
    return [ file_name, -1 ]
  else
    return [ file_name, str2nr( file_line ) ]
  endif
endfunction

function! s:FoldText ()
  let [ filename, line_start ] = s:GetFile( v:foldstart )
  let [ filename, line_end   ] = s:GetFile( v:foldend )

  let head = '+-'.v:folddashes.' '
  let tail = ' ('.( v:foldend - v:foldstart + 1 ).' lines) '

  if filename != ''
    return filename.':'.line_start.'-'.line_end.tail
  else
    return head.getline( v:foldstart ).tail
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

