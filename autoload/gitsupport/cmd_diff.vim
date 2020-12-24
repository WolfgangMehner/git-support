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
  return gitsupport#cmd_diff#OpenBuffer( args, '' )
endfunction

function! gitsupport#cmd_diff#OpenBuffer ( params, dir_hint )
  let params = a:params
  let cwd = gitsupport#services_path#GetWorkingDir( a:dir_hint )

  let [ sh_ret, base_dir ] = gitsupport#services_path#GetGitDir( 'top', cwd )
  if sh_ret != 0 || base_dir == ''
    return s:ErrorMsg( 'could not obtain the repo base directory' )
  endif

  if empty( params ) && g:Git_DiffExpandEmpty == 'yes'
    let params += [ '--', expand( '%' ) ]
  endif

  call gitsupport#run#OpenBuffer( 'Git - diff' )
  call s:Run( params, cwd, 0 )

  let &l:filetype = 'gitsdiff'
  let &l:foldmethod = 'syntax'
  let &l:foldlevel = 2
  let &l:foldtext = 'GitS_FoldLog()'

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
  nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

  nnoremap <silent> <buffer> of     :call <SID>Jump("file")<CR>
  nnoremap <silent> <buffer> oj     :call <SID>Jump("line")<CR>

  nnoremap <silent> <buffer> ac     :call <SID>ChunkAction("add","n")<CR>
  vnoremap <silent> <buffer> ac     :call <SID>ChunkAction("add","v")<CR>
  nnoremap <silent> <buffer> cc     :call <SID>ChunkAction("checkout","n")<CR>
  vnoremap <silent> <buffer> cc     :call <SID>ChunkAction("checkout","v")<CR>
  nnoremap <silent> <buffer> rc     :call <SID>ChunkAction("reset","n")<CR>
  vnoremap <silent> <buffer> rc     :call <SID>ChunkAction("reset","v")<CR>

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
        \ ."  :help g:Git_DiffExpandEmpty\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd, restore_cursor )
  call gitsupport#run#RunToBuffer( '', ['diff'] + a:params,
        \ 'cwd', a:cwd,
        \ 'restore_cursor', a:restore_cursor )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD, 1 )
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

function! s:ChunkAction ( action, mode ) range
  if s:ChunkHandler( a:action, a:mode, a:firstline, a:lastline )
    call s:Update()
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

function! s:GetChunk ( line )
  " the positions in the buffer
  let pos_save = getpos( '.' )
  call cursor( a:line, 1 )

  let header_pos = search( '\m\_^diff ', 'bcnW' )         " the position of the diff header
  let chunk_pos  = search( '\m\_^@@ ', 'bcnW' )           " the start of the chunk
  let chunk_end  = search( '\m\_^@@ \|\_^diff ', 'nW' )   " ... the end

  call setpos( '.', pos_save )

  if header_pos == 0 || chunk_pos == 0
    return [ '', '', 'no valid chunk selected', 0 ]
  elseif chunk_end == 0
    " found the other two positions
    " -> the end of the chunk must be the end of the file
    let chunk_end = line('$')+1
  endif

  " get the diff header
  let diff_head = getline(header_pos)

  while 1
    let header_pos += 1
    let line = getline( header_pos )

    if line =~# '\m\_^\%(diff\|@@\) '
      break
    endif

    let diff_head .= "\n".line
  endwhile

  " get the chunk
  let chunk_head = getline( chunk_pos )
  let chunk_text = join( getline( chunk_pos+1, chunk_end-1 ), "\n" )

  return [ diff_head, chunk_head, chunk_text, chunk_pos ]
endfunction

function! s:VisualChunk ( diff_head, chunk_head, chunk_text, reverse, v_start, v_end )
  " error message from 's:GetChunk'?
  if a:diff_head == ''
    return [ a:diff_head, a:chunk_head, a:chunk_text ]
  endif

  let v_start = a:v_start - 1                   " convert to indices
  let v_end   = a:v_end   - 1                   " ...
  let lines = split( a:chunk_text, '\n' )

  if v_start < 0 || v_end >= len( lines )
    return [ '', '', 'visual selection crosses chunk boundary' ]
  elseif a:chunk_head =~ '^@@@'
    return [ '', '', 'can not handle this type of chunk' ]
  endif

  let n_add_off = 0
  let n_rm_off  = 0

  for i in range( len(lines)-1, v_end+1, -1 ) + range( v_start-1, 0, -1 )
    let line = lines[i]

    if line =~ '^-' && ! a:reverse
      let lines[i] = substitute( line, '^-', ' ', '' )
      let n_add_off += 1                        " we add one more line
    elseif line =~ '^+' && ! a:reverse
      call remove( lines, i )
      let n_add_off -= 1                        " we add one less line
    elseif line =~ '^-' && a:reverse
      call remove( lines, i )
      let n_rm_off -= 1                         " we remove one less line
    elseif line =~ '^+' && a:reverse
      let lines[i] = substitute( line, '^+', ' ', '' )
      let n_rm_off += 1                         " we remove one more line
    endif
  endfor

  let mlist = matchlist( a:chunk_head, '^@@ -\(\d\+\),\(\d\+\) +\(\d\+\),\(\d\+\) @@\s\?\(.*\)' )

  if empty( mlist )
    return [ '', '', 'can not parse the chunk header' ]
  else
    let [ l_rm, n_rm, l_add, n_add ] = mlist[1:4]
    let n_rm  += n_rm_off
    let n_add += n_add_off
    let chunk_head = printf( '@@ -%d,%d +%d,%d @@ %s', l_rm, n_rm, l_add, n_add, mlist[5] )
  endif

  return [ a:diff_head, chunk_head, join( lines, "\n" ) ]
endfunction

function! s:ChunkHandler ( action, mode, v_start, v_end )
  " get the chunk under the cursor/visual selection
  if a:mode == 'n'
    let [ diff_head, chunk_head, chunk_text, chunk_pos ] = s:GetChunk( getpos('.')[1] )
  elseif a:mode == 'v'
    let reverse = a:action == 'add' ? 0 : 1
    let [ diff_head, chunk_head, chunk_text, chunk_pos ] = s:GetChunk( a:v_start )
    let [ diff_head, chunk_head, chunk_text            ] = s:VisualChunk( diff_head, chunk_head, chunk_text, reverse, a:v_start - chunk_pos, a:v_end - chunk_pos )
  endif

  " error while extracting chunk?
  if diff_head == ''
    return s:ErrorMsg( chunk_text )
  endif

  " apply the patch, depending on the action
  if a:action == 'add'
    let params = [ 'apply', '--cached', '--', '-' ]
  elseif a:action == 'checkout'
    let params = [ 'apply', '-R', '--', '-' ]
  elseif a:action == 'reset'
    let params = [ 'apply', '--cached', '-R', '--', '-' ]
  endif

  let chunk = diff_head."\n".chunk_head."\n".chunk_text."\n"
  let [ ret_code, error_msg ] = gitsupport#run#RunDirect( '', params, 'stdin', chunk, 'cwd', b:GitSupport_BaseDir, 'env_std', 1, 'mode', 'return' )

  " check the result
  if ret_code != 0
    echo "applying the chunk failed:\n\n".error_msg         | " failure
  elseif error_msg =~ '^\_s*$'
    echo "chunk applied successfully"                       | " success
  else
    echo "chunk applied successfully:\n".error_msg          | " success
  endif

  return ret_code == 0
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

