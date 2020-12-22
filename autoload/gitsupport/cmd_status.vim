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

  let options = {
        \ 'ignored': s:ListHas( params, [ '--ignored' ] ),
        \ }

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

  nnoremap <silent> <buffer> i      :call <SID>Option("ignored")<CR>

  nnoremap <silent> <buffer> a      :call <SID>FileAction("add")<CR>
  nnoremap <silent> <buffer> c      :call <SID>FileAction("checkout")<CR>
  nnoremap <silent> <buffer> ch     :call <SID>FileAction("checkout-head")<CR>
  nnoremap <silent> <buffer> r      :call <SID>FileAction("reset")<CR>
  nnoremap <silent> <buffer> od     :call <SID>ShowDiff("default")<CR>
  nnoremap <silent> <buffer> ol     :call <SID>ShowLog()<CR>
  nnoremap <silent> <buffer> of     :call <SID>Jump()<CR>
  nnoremap <silent> <buffer> oj     :call <SID>Jump()<CR>
  nnoremap <silent> <buffer> D      :call <SID>DeleteFromDisk()<CR>

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
        \ ."\n"
        \ ."toggle ...\n"
        \ ."i       : show ignored files\n"
        \ ."\n"
        \ ."file under cursor ...\n"
        \ ."a       : add\n"
        \ ."c       : checkout\n"
        \ ."ch      : checkout HEAD\n"
        \ ."od      : open diff\n"
        \ ."of / oj : open file (edit)\n"
        \ ."ol      : open log\n"
        \ ."r       : reset\n"
        \ ."D       : delete from file system (only untracked files)\n"
        \ ."\n"
        \ ."for settings see:\n"
        \ ."  :help g:Git_StatusStagedOpenDiff\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Options, b:GitSupport_CWD, 1 )
endfunction

function! s:Option ( name )
  let b:GitSupport_Options[a:name] = 1 - b:GitSupport_Options[a:name]
  call s:Run( b:GitSupport_Options, b:GitSupport_CWD, 1 )
endfunction

function! s:Jump ()
  let file_record = s:GetFileRecord()

  if empty( file_record )
    return s:ErrorMsg( 'no file under the cursor' )
  endif

  let file_name = file_record.filename
  if b:GitSupport_BaseDir != ''
    let file_name = resolve( fnamemodify( b:GitSupport_BaseDir.'/'.file_name, ':p' ) )
  endif
  call gitsupport#run#OpenFile( file_name )
endfunction

function! s:ShowDiff ( mode )
  let file_record = s:GetFileRecord()

  if empty( file_record )
    return s:ErrorMsg( 'no file under the cursor' )
  endif

  let section = file_record.section
  let section_meta = s:Sections[ section ]
  if !s:ListHas( section_meta.actions, [ 'diff' ] )
    return s:ErrorMsg( 'can not perform action "diff" in section '.section_meta.name )
  endif

  let file_name_new = file_record.filename
  let file_name_old = file_record.filename_alt

  let args = []

  if section == 'stg'
    if g:Git_StatusStagedOpenDiff == 'cached'
      let args = [ '--cached' ]
    elseif g:Git_StatusStagedOpenDiff == 'head'
      let args = [ 'HEAD' ]
    else
      let args = []
    endif

    if file_name_new == file_name_old
      let args += [ '--', file_name_new ]
    else
      let args = [ '--find-renames' ] + args + [ '--', file_name_old, file_name_new ]
    endif
  elseif section == 'ustg' || section == 'mrg'
    let args = [ '--', file_name_new ]
  else
    return 0
  endif

  return gitsupport#cmd_diff#OpenBuffer( args, b:GitSupport_BaseDir )
endfunction

function! s:ShowLog ()
  let file_record = s:GetFileRecord()

  if empty( file_record )
    return s:ErrorMsg( 'no file under the cursor' )
  endif

  let section = file_record.section
  let section_meta = s:Sections[ section ]
  if !s:ListHas( section_meta.actions, [ 'log' ] )
    return s:ErrorMsg( 'can not perform action "log" in section '.section_meta.name )
  endif

  let file_name = file_record.filename_alt
  return gitsupport#cmd_log#OpenBuffer( [ '--stat', '--follow', '--', file_name ], [], b:GitSupport_BaseDir )
endfunction

function! s:FileAction ( action )
  let file_record = s:GetFileRecord()

  if empty( file_record )
    return s:ErrorMsg( 'no file under the cursor' )
  endif

  let section = s:Sections[ file_record.section ]
  if !s:ListHas( section.actions, [ a:action ] )
    return s:ErrorMsg( 'can not perform action "'.a:action.'" in section '.section.name )
  endif

  let file_name = file_record.filename
  if b:GitSupport_BaseDir != ''
    let file_name = resolve( fnamemodify( b:GitSupport_BaseDir.'/'.file_name, ':p' ) )
  endif

  if a:action == 'add'
    let success = s:FileActionAdd( file_name, file_record )
  elseif a:action == 'checkout'
    let success = s:FileActionCheckout( file_name, file_record )
  elseif a:action == 'checkout-head'
    let success = s:FileActionCheckoutHead( file_name, file_record )
  elseif a:action == 'reset'
    let success = s:FileActionReset( file_name, file_record )
  else
    let success = 0
  endif

  if success
    call s:Run( b:GitSupport_Options, b:GitSupport_CWD, 1 )
  endif
endfunction

function! s:FileActionAdd ( file_name, file_record )
  let filename = a:file_record.filename
  let section = a:file_record.section
  let status = a:file_record.status
  let highl = 'normal'

  if section == 'ustg' && status ==? 'M'
    let qst  = 'Add file'
    let args = [ 'add' ]
  elseif section == 'ustg' && status ==? 'D'
    let qst  = 'Remove file'
    let args = [ 'rm' ]
  elseif section == 'mrg'
    let qst  = 'Mark resolution for file'
    let args = [ 'add' ]
  elseif section == 'utrk'
    let qst  = 'Add untracked file'
    let args = [ 'add' ]
  elseif section == 'ign'
    let qst  = 'Add ignored file'
    let args = [ 'add', '-f' ]
    let highl = 'warning'
  else
    return 0
  endif

  if gitsupport#common#Question( qst.' "'.filename.'"?', 'highlight', highl )
    return gitsupport#run#RunDirect( '', args + [ '--', filename ],
          \ 'cwd', b:GitSupport_BaseDir
          \ ) == 0
  else
    return 0
  endif
endfunction

function! s:FileActionCheckout ( file_name, file_record )
  let filename = a:file_record.filename
  let section = a:file_record.section
  let status = a:file_record.status

  if section == 'ustg' && status =~? '[MD]'
    if gitsupport#common#Question( 'Checkout file "'.filename.'"?', 'highlight', 'warning' )
      return gitsupport#run#RunDirect( '', [ 'checkout', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  endif
  return 0
endfunction

function! s:FileActionCheckoutHead ( file_name, file_record )
  let filename = a:file_record.filename
  let section = a:file_record.section
  let status = a:file_record.status

  if ( section == 'stg' || section == 'ustg' ) && status =~? '[MAD]'
    if gitsupport#common#Question( 'Checkout file "'.filename.' and change both the index and working tree copy"?', 'highlight', 'warning' )
      return gitsupport#run#RunDirect( '', [ 'checkout', 'HEAD', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  endif
  return 0
endfunction

function! s:FileActionReset ( file_name, file_record )
  let filename = a:file_record.filename
  let section = a:file_record.section
  let status = a:file_record.status

  if section == 'stg' && status =~? '[MADC]'
    if gitsupport#common#Question( 'Reset file "'.filename.'"?', 'highlight', 'normal' )
      return gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  elseif section == 'stg' && status ==? 'R'
    let filename_old = a:file_record.filename_alt
    if gitsupport#common#Question( 'Reset the old file "'.filename_old.'"?' )
      call gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename_old ],
            \ 'cwd', b:GitSupport_BaseDir ) == 0
    endif
    if gitsupport#common#Question( 'Reset the new file "'.filename.'"?' )
      call gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir ) == 0
    endif
    if gitsupport#common#Question( 'Undo the rename?' )
      call rename( filename, filename_old )
    endif
    return 1
  elseif section == 'mrg'
    if gitsupport#common#Question( 'Reset conflicted file "'.filename.'"?', 'highlight', 'normal' )
      return gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  endif
  return 0
endfunction

function! s:DeleteFromDisk ()
  if !exists( '*delete' )
    return s:ErrorMsg ( 'Can not delete files from harddisk.' )
  endif

  let file_record = s:GetFileRecord()

  if empty( file_record )
    return s:ErrorMsg( 'no file under the cursor' )
  endif

  let section = file_record.section
  let section_meta = s:Sections[ section ]
  if !s:ListHas( section_meta.actions, [ 'delete' ] )
    return s:ErrorMsg( 'can not perform action "delete" in section '.section_meta.name )
  endif

  let file_name = file_record.filename
  if b:GitSupport_BaseDir != ''
    let file_name = resolve( fnamemodify( b:GitSupport_BaseDir.'/'.file_name, ':p' ) )
  endif

  if gitsupport#common#Question( 'Delete file "'.file_name.'" from harddisk?', 'highlight', 'warning' )
    if delete ( file_name ) == 0
      call s:Run( b:GitSupport_Options, b:GitSupport_CWD, 1 )
    endif
  endif
endfunction

function! s:GetFileRecord ()
  let line_nr = line('.')
  return get( b:GitSupport_LineIndex, line_nr, {} )
endfunction

let s:H2 = '  '
let s:H8 = '        '

let s:Sections = {
      \ 'stg':  { 'name': 'staged' },
      \ 'ustg': { 'name': 'unstaged' },
      \ 'mrg':  { 'name': 'conflict' },
      \ 'utrk': { 'name': 'untracked' },
      \ 'ign':  { 'name': 'ignored' },
      \ }
let s:Sections.stg.actions  = [ 'reset', 'checkout-head',           'diff', 'log', ]
let s:Sections.ustg.actions = [ 'add', 'checkout', 'checkout-head', 'diff', 'log', ]
let s:Sections.mrg.actions  = [ 'add', 'reset',                     'diff', 'log', ]
let s:Sections.utrk.actions = [ 'add', 'delete', ]
let s:Sections.ign.actions  = [ 'add', 'delete', ]

let s:Sections.stg.headers = [
      \ 'Changes to be committed:',
      \ s:H2.'(use map "r" or ":GitReset HEAD <file>" to unstage)',
      \ ]
let s:Sections.ustg.headers = [
      \ 'Changes not staged for commit:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to update what will be committed)',
      \ s:H2.'(use map "c" or ":GitCheckout -- <file>" to discard changes in working directory)',
      \ ]
let s:Sections.mrg.headers = [
      \ 'Unmerged paths:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to mark resolution)',
      \ ]
let s:Sections.utrk.headers = [
      \ 'Untracked files:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to include in what will be committed)',
      \ ]
let s:Sections.ign.headers = [
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

  if a:options.ignored
    let params += [ '--ignored' ]
  endif

  if a:restore_cursor
    let restore_pos = gitsupport#common#BufferGetPosition()
  else
    let restore_pos = []
  endif
  call gitsupport#common#BufferWipe()

  let [ ret_code, status ] = gitsupport#run#RunDirect( '', ['status'] + params, 'cwd', a:cwd, 'mode', 'return' )
  let list_status = split( status, '\m[\n\r]\+' )

  call setline( 1, [ 'On branch TODO', '' ] )

  let list_index        = s:ProcessSection( s:IsStaged( list_status ),    'stg' )
  let list_working_tree = s:ProcessSection( s:IsNotStaged( list_status ), 'ustg' )
  let list_conflict     = s:ProcessSection( s:IsConflict( list_status ),  'mrg' )
  let list_untracked    = s:ProcessSection( s:IsUntracked( list_status ), 'utrk' )
  let list_ignored      = s:ProcessSection( s:IsIgnored( list_status ),   'ign' )

  call s:PrintSection( list_index,        s:Sections.stg.headers )
  call s:PrintSection( list_working_tree, s:Sections.ustg.headers )
  call s:PrintSection( list_conflict,     s:Sections.mrg.headers )
  call s:PrintSection( list_untracked,    s:Sections.utrk.headers )
  call s:PrintSection( list_ignored,      s:Sections.ign.headers )
  call s:AddFold( 1, line('$') )

  let b:GitSupport_LineIndex = {}
  call s:BuildIndex( b:GitSupport_LineIndex, list_index )
  call s:BuildIndex( b:GitSupport_LineIndex, list_working_tree )
  call s:BuildIndex( b:GitSupport_LineIndex, list_conflict )
  call s:BuildIndex( b:GitSupport_LineIndex, list_untracked )
  call s:BuildIndex( b:GitSupport_LineIndex, list_ignored )

  call gitsupport#common#BufferSetPosition( restore_pos )

  let &l:foldlevel = 2          " open folds closed by manual creation
endfunction

function! s:ProcessSection ( list_status, section )
  let is_staged   = a:section == 'stg'
  let is_unstaged = a:section == 'ustg'
  let is_conflict = a:section == 'mrg'
  let list_section = []

  for val in a:list_status
    let [ status, status_alt, filename ] = s:SplitHeader( val )

    let record = {
          \ 'filename': filename,
          \ 'filename_alt': filename,
          \ 'status': status,
          \ 'section': a:section,
          \ }

    if is_staged
      if status == 'R'
        let mlist = matchlist( f_name, '^\(.*\) -> \(.*\)$' )
        if !empty( mlist )
          record.filename     = mlist[2]
          record.filename_alt = mlist[1]
        endif
      endif
    elseif is_unstaged
      let status = status_alt
    elseif is_conflict
      let record.status  = 'U'
      let record.status1 = status
      let record.status2 = status_alt
    endif
    call add( list_section, record )
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

function! s:IsConflict ( list_status )
  return filter( copy( a:list_status ), 'v:val =~ "^\\(U.\\|.U\\|AA\\|DD\\)"' )
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

function! s:ListHas ( list, items )
  for item in a:items
    if index( a:list, item ) >= 0
      return 1
    endif
  endfor
  return 0
endfunction

