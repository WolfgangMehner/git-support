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

let s:NO_COMMIT_HASH = repeat( '0', 40 )
let s:DATE_FORMAT_TIME_THRESHOLD = 100 * ( 24 * 60 * 60 )   " 100 days

let s:use_advanced_mode = 1

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
  if s:use_advanced_mode
    let params = [ '--porcelain' ] + params
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
  if s:use_advanced_mode
    let Callback = function( 's:ProcessPorcelain' )
    let b:GitSupport_BlameData = {
          \ 'commits': {},
          \ 'lines': [],
          \ 'filename': get( a:params, -1, '' ),
          \ }
  else
    let Callback = function( 's:Empty' )
  endif
  call gitsupport#run#RunToBuffer( '', ['blame'] + a:params,
        \ 'cwd', a:cwd,
        \ 'restore_cursor', a:restore_cursor,
        \ 'callback', Callback )
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
  if s:use_advanced_mode
    return s:GetInfoAdvanded( a:line_nr, a:property )
  else
    return s:GetInfoBasic( a:line_nr, a:property )
  endif
endfunction

function! s:GetInfoBasic ( line_nr, property )

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
      return ''
    else
      return commit
    endif
  endif
endfunction

function! s:GetInfoAdvanded ( line_nr, property )
  if a:line_nr < 1 || a:line_nr > len( b:GitSupport_BlameData.lines )
    return [ '', '-1' ]
  endif

  let line_data = b:GitSupport_BlameData.lines[ a:line_nr - 1 ]

  if a:property == 'position'
    return [ b:GitSupport_BlameData.filename, str2nr( line_data.line_final ) ]
  elseif a:property == 'commit'
    let commit_hash = line_data.commit.hash
    if commit_hash == s:NO_COMMIT_HASH
      return ''
    else
      return commit_hash
    endif
  endif
endfunction

function! s:ProcessPorcelain ( buf_nr, status )
  call s:ParsePorcelain( a:buf_nr )
  call s:RenderLines( a:buf_nr )
endfunction

let s:HEADER = 1
let s:PARSE  = 2

function! s:ParsePorcelain ( buf_nr )
  let state = s:HEADER

  let commit  = {}
  let line    = {}
  let commits = b:GitSupport_BlameData.commits
  let lines   = b:GitSupport_BlameData.lines
  let line_original = -1
  let line_final    = -1

  for line_raw in getbufline( a:buf_nr, 1, '$' )
    if state == s:HEADER
      let state = s:PARSE
      let mlist = matchlist( line_raw, '\(\x\+\)\s\+\(\d\+\)\s\+\(\d\+\)' )

      if empty( mlist )
        break
      endif

      let [ commit_sha, line1, line2 ] = mlist[1:3]

      if has_key( commits, commit_sha )
        let commit = commits[ commit_sha ]
      else
        let commit = { 'hash': commit_sha, }
        let commits[ commit_sha ] = commit
      endif

      let line = {
            \ 'commit':        commit,
            \ 'line_original': str2nr( line1 ),
            \ 'line_final':    str2nr( line2 ),
            \ }
      call add( lines, line )
    elseif state == s:PARSE

      if line_raw[0] == "\t"
        " With some combinations of parameters (e.g. '-C -M') more than one
        " filename might appear per commit, if lines originate from different
        " files in the same commit. We use the commit data structure as a
        " buffer for the 'filename' property, but store it per line.
        let line.file_original = commit.filename
        let line.str = line_raw[1:]
        let state = s:HEADER
      else
        let mlist = matchlist( line_raw, '\(\S\+\)\s\+\(.\+\)' )

        if len( mlist ) >= 2
          let commit[ mlist[1] ] = mlist[2]
        endif
      endif
    endif
  endfor
endfunction

function! s:RenderLines ( buf_nr )
  let &l:modifiable = 1
  call deletebufline( a:buf_nr, 1, '$' )

  let commits = b:GitSupport_BlameData.commits
  let lines   = b:GitSupport_BlameData.lines

  for line in lines
    let commit = line.commit
    let a_time = str2nr( commit['author-time'] )
    if localtime() - a_time > s:DATE_FORMAT_TIME_THRESHOLD
      let time_str = strftime( '%x', a_time )
    else
      let time_str = strftime( '%b %d %H:%M', a_time )
    endif
    call appendbufline( a:buf_nr, '$', printf( '%s %12s %s', commit.hash[0:6], time_str, line.str ) )
  endfor

  normal! gg"_dd
  let &l:modifiable = 0
endfunction

function! s:Empty ( ... )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

