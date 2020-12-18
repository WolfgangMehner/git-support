"-------------------------------------------------------------------------------
"
"          File:  cmd_diff.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  18.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_diff#FromCmdLine ( q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_diff#OpenBuffer( args )
endfunction

function! gitsupport#cmd_diff#OpenBuffer ( params )
  let params = a:params
  let cwd = gitsupport#services_path#GetWorkingDir()

  let [ sh_ret, base_dir ] = gitsupport#services_path#GetGitDir()
  if sh_ret != 0 || base_dir == ''
    return s:ErrorMsg( 'could not obtain the repo base directory' )
  endif

  if empty( params ) && g:Git_DiffExpandEmpty == 'yes'
    let params += [ '--', expand( '%' ) ]
  endif

  call gitsupport#run#OpenBuffer( 'Git - diff' )
  call s:Run( params, cwd )

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
  nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

  nnoremap <silent> <buffer> of     :call <SID>Jump("file")<CR>
  nnoremap <silent> <buffer> oj     :call <SID>Jump("line")<CR>

  let b:GitSupport_Param = params
  let b:GitSupport_CWD = cwd
  let b:GitSupport_BaseDir = base_dir
endfunction

function! s:Help ()
  let text =
        \  "git diff\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
        \ ."\n"
        \ ."file under cursor ...\n"
        \ ."of      : open file (edit)\n"
        \ ."oj      : open and jump to the position under the cursor\n"
        \ ."\n"
        \ ."chunk under cursor ...\n"
        \ ."ac      : add to index (add chunk)\n"
        \ ."cc      : undo change (checkout chunk)\n"
        \ ."rc      : remove from index (reset chunk)\n"
        \ ." ->       in visual mode, these maps only apply the selected lines\n"
        \ ."\n"
        \ ."for settings see:\n"
        \ ."  :help g:Git_DiffExpandEmpty"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd )
  call gitsupport#run#RunToBuffer( '', ['diff'] + a:params, 'callback', function( 's:Wrap' ), 'cwd', a:cwd )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD )
endfunction

function! s:Wrap ()
  let &l:filetype = 'gitsdiff'
  let &l:foldmethod = 'syntax'
  let &l:foldtext = 'GitS_FoldLog()'
  normal! zR   | " open all folds (closed by the syntax highlighting)
endfunction

function! s:Jump ( mode )
  let [ file_name, file_line, file_col ] = s:GetFile( a:mode )

  if file_name == ''
    return s:ErrorMsg( 'no diff under the cursor' )
  elseif file_line < 0 && a:mode == 'line'
    return s:ErrorMsg( 'no chunk under the cursor' )
  endif

  let file_name = resolve( fnamemodify( b:GitSupport_BaseDir.'/'.file_name, ':p' ) )

  if a:mode == 'file'
    call gitsupport#run#OpenFile( file_name )
  elseif a:mode == 'line'
    call gitsupport#run#OpenFile( file_name, 'line', file_line, 'column', file_col )
  endif
endfunction

function! s:GetFile ( mode )
  " :TODO:17.08.2014 15:01:WM: recognized renamed files

  let file_name = ''
  let file_line = -1
  let file_col  = -1

  let buf_pos = line('.')

  " get line and col
  if a:mode == 'line'
    let file_col = getpos( '.' )[2]
    let file_off1 = 0
    let file_off2 = 0

    while buf_pos > 0
      if getline(buf_pos) =~ '^[+ ]'
        let file_off1 += 1
        if getline(buf_pos) =~ '^[+ ][+ ]'
          let file_off2 += 1
        endif
      elseif getline(buf_pos) =~ '^@@ '
        let s_range = matchstr( getline(buf_pos), '^@@ -\d\+,\d\+ +\zs\d\+\ze,\d\+ @@' )
        let file_line = s_range - 1 + file_off1
        let file_col  = max( [ file_col-1, 1 ] )
        break
      elseif getline(buf_pos) =~ '^@@@ '
        let s_range = matchstr( getline(buf_pos), '^@@@ -\d\+,\d\+ -\d\+,\d\+ +\zs\d\+\ze,\d\+ @@@' )
        let file_line = s_range - 1 + file_off2
        let file_col  = max( [ file_col-2, 1 ] )
        break
      elseif getline(buf_pos) =~ '^diff '
        break
      endif

      let buf_pos -= 1
    endwhile
  endif

  " get file
  while buf_pos > 0
    if getline(buf_pos) =~ '^diff --git'
      let file_name = matchstr( getline(buf_pos), 'a\([/\\]\)\zs\(.*\)\ze b\1\2\s*$' )
      break
    elseif getline(buf_pos) =~ '^diff --cc'
      let file_name = matchstr( getline(buf_pos), '^diff --cc \zs.*$' )
      break
    endif

    let buf_pos -= 1
  endwhile

  return [ file_name, file_line, file_col ]
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

