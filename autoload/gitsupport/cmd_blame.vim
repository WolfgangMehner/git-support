"-------------------------------------------------------------------------------
"
"          File:  cmd_blame.vim
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

function! gitsupport#cmd_blame#FromCmdLine ( q_params, line1, line2, count )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  if a:count > 0 
    let range_info = [ a:line1, a:line2 ]
  else
    let range_info = []
  endif
  return gitsupport#cmd_blame#OpenBuffer( args, range_info )
endfunction

function! gitsupport#cmd_blame#OpenBuffer ( params, range_info )
  let params = a:params
  let cwd = gitsupport#services_path#GetWorkingDir()

  if empty( params )
    let params = [ '--', expand( '%' ) ]
  endif
  if len( a:range_info ) == 2
    let params = [ '-L', a:range_info[0].','.a:range_info[1] ] + params
  endif

  call gitsupport#run#OpenBuffer( 'Git - blame' )

  let &l:filetype = 'gitsblame'

  call s:Run( params, cwd, 0 )

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
  nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

  nnoremap <silent> <buffer> of     :call <SID>Jump("file")<CR>
  nnoremap <silent> <buffer> oj     :call <SID>Jump("line")<CR>
  nnoremap <silent> <buffer> cs     :call <SID>Show("commit")<CR>

  let b:GitSupport_Param = params
  let b:GitSupport_CWD = cwd
endfunction

function! s:Help ()
  let text =
        \  "git blame\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
        \ ."\n"
        \ ."line under cursor ...\n"
        \ ."of      : file under cursor: open file (edit)\n"
        \ ."oj      : file under cursor: open and jump to the corresponding line\n"
        \ ."\n"
        \ ."commit under cursor ...\n"
        \ ."cs      : show\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd, restore_cursor )
  call gitsupport#run#RunToBuffer( '', ['blame'] + a:params,
        \ 'cwd', a:cwd,
        \ 'restore_cursor', a:restore_cursor )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD, 1 )
endfunction

function! s:Jump ( mode )
  let [ file_name, file_line ] = s:GetInfo( line('.'), 'position' )

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

function! s:Show ( mode )
  let commit_name = s:GetInfo( line('.'), 'commit' )

  if commit_name == ''
    return s:ErrorMsg( 'no commit under the cursor' )
  endif

  return gitsupport#cmd_show#OpenBuffer( [ commit_name ] )
endfunction

function! s:GetInfo ( line_nr, property )

  " LINE:
  "   [^] commit [ofile] (INFO line)
  " The token 'ofile' appears if the file has been renamed in the meantime.
  " INFO: (not used)
  "   author date time timezone
  let line_str = getline( a:line_nr )
  let mlist = matchlist( line_str, '^\^\?\(\x\+\)\s\+\%([^(]\{-}\s\+\)\?(\([^)]\+\)\s\(\d\+\))' )

  if empty( mlist )
    let [ commit, info, file_line ] = [ '', '', '-1' ]
  else
    let [ commit, info, file_line ] = mlist[1:3]
  endif

  if a:property == 'position' 
    let file_name = get( b:GitSupport_Param, -1, '' )

    return [ file_name, str2nr( file_line ) ]
  elseif a:property == 'commit' 
    if info =~? '^Not Committed Yet '
      return 'NEW'
    else
      return commit
    endif
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

