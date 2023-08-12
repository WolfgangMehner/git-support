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
let s:Features = gitsupport#config#Features()
let s:use_popups = s:use_advanced_mode && s:Features.vim_has_popups

function! gitsupport#cmd_blame#FromCmdLine ( q_params, line1, line2, count, cmd_mods )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  call gitsupport#common#ExpandWildcards( args )
  if a:count > 0 
    let range_info = [ a:line1, a:line2 ]
  else
    let range_info = []
  endif
  return gitsupport#cmd_blame#OpenBuffer( args, range_info, a:cmd_mods )
endfunction

function! gitsupport#cmd_blame#OpenBuffer ( params, range_info, cmd_mods )
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

  call gitsupport#run#OpenBuffer( 'Git - blame', 'mods', a:cmd_mods )

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
    let file_name = get( a:params, -1, '' )
    let b:GitSupport_BlameData = {
          \ 'commits': {},
          \ 'lines': [],
          \ 'filename': file_name,
          \ 'filename_repo': gitsupport#services_path#GetFullRepoPath( file_name ),
          \ }
  else
    let Callback = function( 's:Empty' )
  endif
  call gitsupport#run#RunToBuffer( '', ['blame'] + a:params,
        \ 'cwd', a:cwd,
        \ 'restore_cursor', a:restore_cursor,
        \ 'cb_textprocess', Callback )
  if s:use_popups
    call gitsupport#cursor_tracker#Add(bufnr(), 'git-blame', function('gitsupport#cmd_blame#PopupCallback'))
  endif
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
  if a:mode == 'commit'
    let commit_name = s:GetInfo( line('.'), 'commit-hash' )

    if commit_name == ''
      return s:ErrorMsg( 'no commit under the cursor' )
    endif

    return gitsupport#cmd_show#OpenBuffer( [ commit_name ], '' )
  endif
endfunction

function! s:CommitDate ( sys_time )
  return strftime( '%c', a:sys_time )
endfunction

function! s:CommitPopup ( buf_id, line )
  call deletebufline( a:buf_id, 1, '$' )

  let file_name = s:GetInfo( a:line, 'position-repo' )[0]
  if file_name == ''
    return
  endif

  let line_data = s:GetInfo( a:line, 'line' )
  let commit    = line_data.commit

  let author_mail = commit['author-mail']
  let commit_mail = commit['committer-mail']
  let author_time = commit['author-time']
  let commit_time = commit['committer-time']

  let committer_different = author_mail != commit_mail || author_time != commit_time
  let file_original_different = file_name != line_data.file_original

  let lines = []
  if commit.hash == s:NO_COMMIT_HASH
    let lines = [printf( '    %-50s', commit['author'] )]
  else
    call add( lines, printf( 'commit %s', commit.hash ) )
    call add( lines, printf( 'Author: %s %s', commit['author'], author_mail ) )
    call add( lines, printf( 'Date:   %s %s', s:CommitDate( author_time ), commit['author-tz'] ) )
    if committer_different
      call add( lines, printf( 'Commit: %s %s', commit['committer'], commit_mail ) )
      call add( lines, printf( 'Date:   %s %s', s:CommitDate( commit_time ), commit['committer-tz'] ) )
    endif
    call add( lines, '' )
    call add( lines, printf( '    %-50s', commit['summary'] ) )
    if file_original_different
      call add( lines, '' )
      call add( lines, printf( '(originally from %s)', line_data.file_original ) )
    endif
  endif

  call setbufline( a:buf_id, 1, lines )
endfunction

function! gitsupport#cmd_blame#PopupCallback(_, event)
  if a:event == 'leave'
    if has_key ( b:GitSupport_BlameData, 'commit_popup' )
      call gitsupport#popup#Close( b:GitSupport_BlameData.commit_popup.win_id )
      unlet b:GitSupport_BlameData.commit_popup
    endif
  elseif a:event == 'hold'
    if !has_key ( b:GitSupport_BlameData, 'commit_popup' )
      let [win_id, buf_id] = gitsupport#popup#Open( [], {} )
      let b:GitSupport_BlameData.commit_popup = {
            \ 'win_id': win_id,
            \ 'buf_id': buf_id,
            \ }
      call s:CommitPopup( buf_id, line('.') )
    endif
  elseif a:event == 'move'
    if has_key ( b:GitSupport_BlameData, 'commit_popup' )
      call s:CommitPopup( b:GitSupport_BlameData.commit_popup.buf_id, line('.') )
    endif
  endif
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
  elseif a:property == 'commit-hash'
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
  elseif a:property == 'position-repo'
    return [ b:GitSupport_BlameData.filename_repo, str2nr( line_data.line_final ) ]
  elseif a:property == 'line'
    return line_data
  elseif a:property == 'commit'
    return line_data.commit
  elseif a:property == 'commit-hash'
    let commit_hash = line_data.commit.hash
    if commit_hash == s:NO_COMMIT_HASH
      return ''
    else
      return commit_hash
    endif
  endif
endfunction

function! s:ProcessPorcelain(buf_nr, _)
  call s:ParsePorcelain( a:buf_nr )
  call s:RenderLines( a:buf_nr )
endfunction

let s:HEADER = 1
let s:PARSE  = 2

function! s:ParsePorcelain(buf_nr)
  let state = s:HEADER

  let blame_data = getbufvar(a:buf_nr, "GitSupport_BlameData")
  let commit  = {}
  let line    = {}
  let commits = blame_data.commits
  let lines   = blame_data.lines
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

function! s:RenderLines(buf_nr)
  call deletebufline( a:buf_nr, 1, '$' )

  let blame_data = getbufvar(a:buf_nr, "GitSupport_BlameData")
  let commits = blame_data.commits
  let lines   = blame_data.lines

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

  call deletebufline(a:buf_nr, 1)
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

