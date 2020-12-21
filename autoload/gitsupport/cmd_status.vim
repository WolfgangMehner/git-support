"-------------------------------------------------------------------------------
"
"          File:  cmd_status.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  20.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_status#FromCmdLine ( q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_status#OpenBuffer( args )
endfunction

function! gitsupport#cmd_status#OpenBuffer ( params )
  let params = a:params
  let cwd = gitsupport#services_path#GetWorkingDir()

  let options = {}

  let [ sh_ret, base_dir ] = gitsupport#services_path#GetGitDir()
  if sh_ret != 0 || base_dir == ''
    return s:ErrorMsg( 'could not obtain the repo base directory' )
  endif

  call gitsupport#run#OpenBuffer( 'Git - status' )
  call s:Run( options, cwd, 0 )

  let &l:filetype = 'gitsstatus'
  let &l:foldmethod = 'manual'
  let &l:foldlevel = 2

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
  nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

"  nnoremap <silent> <buffer> of     :call <SID>Jump("file")<CR>
"  nnoremap <silent> <buffer> oj     :call <SID>Jump("line")<CR>

  let b:GitSupport_Param = params
  let b:GitSupport_Options = options
  let b:GitSupport_CWD = cwd
  let b:GitSupport_BaseDir = base_dir
endfunction

function! s:Help ()
  let text =
        \  "git status\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
"        \ ."\n"
"        \ ."file under cursor ...\n"
"        \ ."of      : open file (edit)\n"
"        \ ."\n"
"        \ ."for settings see:\n"
"        \ ."  :help g:Git_DiffExpandEmpty"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Options, b:GitSupport_CWD, 1 )
endfunction

let s:H2 = '  '
let s:H8 = '        '

let s:HeadersIndex = [
      \ 'Changes to be committed:',
      \ s:H2.'(use map "r" or ":GitReset HEAD <file>" to unstage)',
      \ ]
let s:HeadersWorkingTree = [
      \ 'Changes not staged for commit:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to update what will be committed)',
      \ s:H2.'(use map "c" or ":GitCheckout -- <file>" to discard changes in working directory)',
      \ ]
let s:HeadersUntracked = [
      \ 'Untracked files:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to include in what will be committed)',
      \ ]
let s:HeadersIgnored = [
      \ 'Ignored files:',
      \ s:H2.'(use map "a" or ":GitAdd -f <file>" to include in what will be committed)',
      \ ]

let s:status_strings = {
      \ 'M': 'modified:   ',
      \ 'A': 'added:      ',
      \ 'D': 'deleted:    ',
      \ 'R': 'renamed:    ',
      \ 'C': 'copied:     ',
      \ 'U': 'unmerged:   ',
      \ ' ': '            ',
      \ '?': '',
      \ '!': '',
      \ }

function! s:Run ( options, cwd, restore_cursor )
  let params = [ '--porcelain' ]

  if a:restore_cursor
    let restore_pos = gitsupport#common#BufferGetPosition()
  else
    let restore_pos = []
  endif
  call gitsupport#common#BufferWipe()

  let [ ret_code, status ] = gitsupport#run#RunDirect( '', ['status'] + params, 'cwd', a:cwd, 'mode', 'return' )
  let list_status = split( status, '\m[\n\r]\+' )

  call setline( 1, [ 'On branch TODO', '' ] )

  let list_index        = s:ProcessSection( s:IsStaged( list_status ),    's' )
  let list_working_tree = s:ProcessSection( s:IsNotStaged( list_status ), 'w' )
  let list_untracked    = s:ProcessSection( s:IsUntracked( list_status ), 'u' )
  let list_ignored      = s:ProcessSection( s:IsIgnored( list_status ),   'i' )

  call s:PrintSection( list_index,        s:HeadersIndex )
  call s:PrintSection( list_working_tree, s:HeadersWorkingTree )
  call s:PrintSection( list_untracked,    s:HeadersUntracked )
  call s:PrintSection( list_ignored,      s:HeadersIgnored )
  call s:AddFold( 1, line('$') )

  let b:GitSupport_LineIndex = {}
  call s:BuildIndex( b:GitSupport_LineIndex, list_index )
  call s:BuildIndex( b:GitSupport_LineIndex, list_working_tree )
  call s:BuildIndex( b:GitSupport_LineIndex, list_untracked )
  call s:BuildIndex( b:GitSupport_LineIndex, list_ignored )

  call gitsupport#common#BufferSetPosition( restore_pos )
endfunction

function! s:ProcessSection ( list_status, type )
  let use_second_column = a:type == 'w'
  let list_section = []

  for val in a:list_status
    let [ status, status_alt, filename ] = s:SplitHeader( val )
    if use_second_column
      let status = status_alt
    endif

    let record = {
          \ 'filename': filename,
          \ 'status': status,
          \ 'type': a:type,
          \ }

    call insert( list_section, record )
  endfor

  return list_section
endfunction

function! s:BuildIndex ( line_index, list_section )
  for record in a:list_section
    let a:line_index[ record.line_printed ] = record
  endfor
endfunction

function! s:PrintSection ( list_section, headers )
  let line_nr = line('$')+1
  let line_first = line_nr

  if !empty( a:list_section )
    call setline( line_nr, a:headers + [''] )
    let line_nr += len( a:headers ) + 1

    for record in a:list_section
      call setline( line_nr, s:H8 . s:GetStatusString(record.status) . record.filename )
      let record.line_printed = line_nr
      let line_nr += 1
    endfor

    call setline( line_nr, [''] )
    call s:AddFold( line_first, line_nr )
  endif
endfunction

function! s:GetStatusString ( status )
  return get( s:status_strings, a:status, s:status_strings[' '] )
endfunction

function! s:SplitHeader ( status_line )
  return matchlist( a:status_line, '\(.\)\(.\) \(.*\)' )[1:3]
endfunction

function! s:IsStaged ( list_status )
  return filter( copy( a:list_status ), 'v:val =~ "^[MADRC]."' )
endfunction

function! s:IsNotStaged ( list_status )
  return filter( copy( a:list_status ), 'v:val =~ "^.[MD]"' )
endfunction

function! s:IsUntracked ( list_status )
  return filter( copy( a:list_status ), 'v:val =~ "^??"' )
endfunction

function! s:IsIgnored ( list_status )
  return filter( copy( a:list_status ), 'v:val =~ "^!!"' )
endfunction

function! s:AddFold ( line_first, line_last )
  silent exec printf( ':%d,%dfold', a:line_first, a:line_last )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

