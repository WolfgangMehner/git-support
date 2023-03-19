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
"       License:  Copyright (c) 2020-2022, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_status#FromCmdLine ( q_params, cmd_mods )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_status#OpenBuffer( args, a:cmd_mods )
endfunction

function! gitsupport#cmd_status#OpenBuffer ( params, cmd_mods )
  let params = a:params
  let cwd = gitsupport#services_path#GetWorkingDir()

  let options = {
        \ 'ignored': s:ListHas( params, [ '--ignored' ] ),
        \ }

  let [ sh_ret, base_dir ] = gitsupport#services_path#GetGitDir( 'top', cwd )
  if sh_ret != 0 || base_dir == ''
    return s:ErrorMsg( 'could not obtain the repo base directory' )
  endif

  call gitsupport#run#OpenBuffer( 'Git - status', 'mods', a:cmd_mods )
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
  nnoremap <silent> <buffer> ow     :call <SID>ShowDiff("word")<CR>
  nnoremap <silent> <buffer> ol     :call <SID>ShowLog()<CR>
  nnoremap <silent> <buffer> of     :call <SID>Jump()<CR>
  nnoremap <silent> <buffer> oj     :call <SID>Jump()<CR>
  nnoremap <silent> <buffer> D      :call <SID>DeleteFromDisk()<CR>

  nnoremap <silent> <buffer> oH     :call <SID>FileAction("show_head")<CR>
  nnoremap <silent> <buffer> oI     :call <SID>FileAction("show_index")<CR>
  nnoremap <silent> <buffer> oC     :call <SID>FileAction("show_merge1")<CR>
  nnoremap <silent> <buffer> oT     :call <SID>FileAction("show_merge2")<CR>
  nnoremap <silent> <buffer> oO     :call <SID>FileAction("show_merge3")<CR>

  nnoremap <expr>   <buffer> ap     <SID>Patch("add")
  nnoremap <expr>   <buffer> cp     <SID>Patch("checkout")
  nnoremap <expr>   <buffer> rp     <SID>Patch("reset")

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
        \ ."a / ap  : add / add --patch\n"
        \ ."c / cp  : checkout / checkout --patch\n"
        \ ."ch      : checkout HEAD\n"
        \ ."od      : open diff\n"
        \ ."of / oj : open file (edit)\n"
        \ ."ol      : open log\n"
        \ ."r       : reset\n"
        \ ."r / rp  : reset / reset --patch\n"
        \ ."D       : delete from file system (only untracked files)\n"
        \ ."\n"
        \ ."changed files ...\n"
        \ ."oH      : open version from (H)ead\n"
        \ ."oI      : open version from (I)ndex\n"
        \ ."\n"
        \ ."unmerged files ...\n"
        \ ."oC      : open (C)ommon predecessor\n"
        \ ."oT      : open version from (T)his branch\n"
        \ ."oO      : open version from (O)ther branch\n"
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

  let file_name = file_record.pathname
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

  let file_name_new = file_record.pathname
  let file_name_old = file_record.pathname_original

  let args = []

  if section == 'staged'
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
  elseif section == 'unstaged' || section == 'unmerged'
    let args = [ '--', file_name_new ]
  else
    return 0
  endif

  if a:mode == 'default'
    return gitsupport#cmd_diff#OpenBuffer( args, b:GitSupport_BaseDir, '' )
  elseif a:mode == 'word'
    return gitsupport#cmd_term#Run( [ 'diff', '--word-diff=color' ] + args, b:GitSupport_BaseDir )
  endif
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

  let file_name_in_head = file_record.pathname_original
  return gitsupport#cmd_log#OpenBuffer( [ '--stat', '--follow', '--', file_name_in_head ], [], b:GitSupport_BaseDir, '' )
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

  let file_name = file_record.pathname
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
  elseif a:action =~ 'show_\w\+'
    let success = s:FileActionShow( file_name, file_record, a:action )
  else
    let success = 0
  endif

  if success
    call s:Run( b:GitSupport_Options, b:GitSupport_CWD, 1 )
  endif
endfunction

function! s:FileActionAdd ( file_name, file_record )
  let filename = a:file_record.pathname
  let section = a:file_record.section
  let status = a:file_record.status
  let highl = 'normal'

  if section == 'unstaged' && status ==? 'M'
    let qst  = 'Add file'
    let args = [ 'add' ]
  elseif section == 'unstaged' && status ==? 'D'
    let qst  = 'Remove file'
    let args = [ 'rm' ]
  elseif section == 'unmerged'
    let qst  = 'Mark resolution for file'
    let args = [ 'add' ]
  elseif section == 'untracked'
    let qst  = 'Add untracked file'
    let args = [ 'add' ]
  elseif section == 'ignored'
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
  let filename = a:file_record.pathname
  let section = a:file_record.section
  let status = a:file_record.status

  if section == 'unstaged' && status =~? '[MD]'
    if gitsupport#common#Question( 'Checkout file "'.filename.'"?', 'highlight', 'warning' )
      return gitsupport#run#RunDirect( '', [ 'checkout', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  endif
  return 0
endfunction

function! s:FileActionCheckoutHead ( file_name, file_record )
  let filename = a:file_record.pathname
  let section = a:file_record.section
  let status = a:file_record.status

  if ( section == 'staged' || section == 'unstaged' ) && status =~? '[MAD]'
    if gitsupport#common#Question( 'Checkout file "'.filename.' and change both the index and working tree copy"?', 'highlight', 'warning' )
      return gitsupport#run#RunDirect( '', [ 'checkout', 'HEAD', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  endif
  return 0
endfunction

function! s:FileActionReset ( file_name, file_record )
  let filename = a:file_record.pathname
  let section = a:file_record.section
  let status = a:file_record.status

  if section == 'staged' && status =~? '[MADC]'
    if gitsupport#common#Question( 'Reset file "'.filename.'"?', 'highlight', 'normal' )
      return gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  elseif section == 'staged' && status ==? 'R'
    let filename_old = a:file_record.pathname_original
    if gitsupport#common#Question( 'Reset the old file "'.filename_old.'"?' )
      call gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename_old ],
            \ 'cwd', b:GitSupport_BaseDir )
    endif
    if gitsupport#common#Question( 'Reset the new file "'.filename.'"?' )
      call gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir )
    endif
    if gitsupport#common#Question( 'Undo the rename?' )
      call rename( filename, filename_old )
    endif
    return 1
  elseif section == 'unmerged'
    if gitsupport#common#Question( 'Reset conflicted file "'.filename.'"?', 'highlight', 'normal' )
      return gitsupport#run#RunDirect( '', [ 'reset', '-q', '--', filename ],
            \ 'cwd', b:GitSupport_BaseDir
            \ ) == 0
    endif
  endif
  return 0
endfunction

function! s:FileActionShow(file_name, file_record, action)
  let filename = a:file_record.pathname

  if a:action == 'show_head'
    call gitsupport#cmd_show#OpenBuffer([a:file_record.hash_head], '')
  elseif a:action == 'show_index'
    call gitsupport#cmd_show#OpenBuffer([a:file_record.hash_index], '')
  elseif a:action == 'show_merge1'
    call gitsupport#cmd_show#OpenBuffer([a:file_record.hash_merge1], '')
  elseif a:action == 'show_merge2'
    call gitsupport#cmd_show#OpenBuffer([a:file_record.hash_merge2], '')
  elseif a:action == 'show_merge3'
    call gitsupport#cmd_show#OpenBuffer([a:file_record.hash_merge3], '')
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

  let file_name = file_record.pathname
  if b:GitSupport_BaseDir != ''
    let file_name = resolve( fnamemodify( b:GitSupport_BaseDir.'/'.file_name, ':p' ) )
  endif

  if gitsupport#common#Question( 'Delete file "'.file_name.'" from harddisk?', 'highlight', 'warning' )
    if delete ( file_name ) == 0
      call s:Run( b:GitSupport_Options, b:GitSupport_CWD, 1 )
    endif
  endif
endfunction

function! s:Patch ( operation )
  let file_record = s:GetFileRecord()
  let file_name   = ''
  if has_key( file_record, 'pathname' )
    let file_name = shellescape( file_record.pathname )
  endif
  return gitsupport#common#AssembleCmdLine( ':GitTerm '.a:operation.' -p -- '.file_name, '' )
endfunction

function! s:GetFileRecord()
  let line_nr = line('.')
  return get(b:GitSupport_StatusData.line_index, line_nr, {})
endfunction

let s:H2 = '  '
let s:H8 = '        '

let s:Sections = {
      \ 'staged':  { 'name': 'staged' },
      \ 'unstaged': { 'name': 'unstaged' },
      \ 'unmerged':  { 'name': 'unmerged' },
      \ 'untracked': { 'name': 'untracked' },
      \ 'ignored':  { 'name': 'ignored' },
      \ }
let s:Sections.staged.actions    = ['reset', 'checkout-head',           'diff', 'log', 'show_head', 'show_index',]
let s:Sections.unstaged.actions  = ['add', 'checkout', 'checkout-head', 'diff', 'log', 'show_head', 'show_index',]
let s:Sections.unmerged.actions  = ['add', 'reset',                     'diff', 'log', 'show_merge1', 'show_merge2', 'show_merge3',]
let s:Sections.untracked.actions = ['add', 'delete',]
let s:Sections.ignored.actions   = ['add', 'delete',]

let s:Sections.staged.headers = [
      \ 'Changes to be committed:',
      \ s:H2.'(use map "r" or ":GitReset HEAD <file>" to unstage)',
      \ ]
let s:Sections.unstaged.headers = [
      \ 'Changes not staged for commit:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to update what will be committed)',
      \ s:H2.'(use map "c" or ":GitCheckout -- <file>" to discard changes in working directory)',
      \ ]
let s:Sections.unmerged.headers = [
      \ 'Unmerged paths:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to mark resolution)',
      \ ]
let s:Sections.untracked.headers = [
      \ 'Untracked files:',
      \ s:H2.'(use map "a" or ":GitAdd <file>" to include in what will be committed)',
      \ ]
let s:Sections.ignored.headers = [
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
      \ 'untracked': '',
      \ 'ignored': '',
      \ }

function! s:Run(options, cwd, restore_cursor)
  " run
  let params = ['-z', '--porcelain=2', '--branch']
  if a:options.ignored
    let params += ['--ignored']
  endif

  let [ret_code, status] = gitsupport#run#RunDirect('', ['status'] + params, 'cwd', a:cwd, 'mode', 'return')
  let list_status = split(status, '[\x00\x01]')

  let status_data = {
        \ 'branch': {'commit': '', 'head': '', 'upstream': '', 'ahead': 0, 'behind': 0},
        \ 'staged': [],
        \ 'unstaged': [],
        \ 'unmerged': [],
        \ 'untracked': [],
        \ 'ignored': [],
        \ 'line_index': {},
        \ }

  while !empty(list_status)
    let line = remove(list_status, 0)
    let indicator = line[0]

    if indicator == '#'
      call s:ProcessMetadata(status_data, line)
    elseif indicator == '1'
      call s:ProcessTrackedFile(status_data, line, '')
    elseif indicator == '2'
      let file2 = remove(list_status, 0)
      call s:ProcessTrackedFile(status_data, line, file2)
    elseif indicator == 'u'
      call s:ProcessUnmergedFile(status_data, line)
    elseif indicator == '?' || indicator == '!'
      call s:ProcessUntrackedFile(status_data, line, indicator == '!')
    endif
  endwhile

  " print
  let &l:modifiable = 1

  if a:restore_cursor
    let restore_pos = gitsupport#common#BufferGetPosition()
  else
    let restore_pos = []
  endif
  call gitsupport#common#BufferWipe()

  call s:PrintBranch(status_data.branch)
  call s:PrintFileSection(status_data.staged, s:Sections.staged.headers)
  call s:PrintFileSection(status_data.unstaged, s:Sections.unstaged.headers)
  call s:PrintFileSection(status_data.unmerged, s:Sections.unmerged.headers)
  call s:PrintFileSection(status_data.untracked, s:Sections.untracked.headers)
  call s:PrintFileSection(status_data.ignored, s:Sections.ignored.headers)
  call s:PrintNothingToCommit(status_data)
  call s:AddFold(1, line('$'))

  for key in ['staged', 'unstaged', 'unmerged', 'untracked', 'ignored']
    call s:BuildIndex(status_data.line_index, status_data[key])
  endfor

  let b:GitSupport_StatusData = status_data

  call gitsupport#common#BufferSetPosition(restore_pos)

  let &l:foldlevel = 2          " open folds closed by manual creation
  let &l:modifiable = 0
endfunction

function! s:ProcessMetadata(status_data, line)
  " # branch.oid <commit> | (initial)        Current commit.
  " # branch.head <branch> | (detached)      Current branch.
  " # branch.upstream <upstream_branch>      If upstream is set.
  " # branch.ab +<ahead> -<behind>           If upstream is set and the commit is present.

  let mlist = matchlist(a:line, '. \(\w\+\)\.\(\w\+\) \(.*\)')
  let [section, key, content] = mlist[1:3]

  if section == 'branch'
    let branch = a:status_data.branch
    if key == 'oid'
      let branch.commit = content
    elseif key == 'head'
      let branch.head = content
    elseif key == 'upstream'
      let branch.upstream = content
    elseif key == 'ab'
      let mlist = matchlist(content, '+\(\d\+\) -\(\d\+\)')
      let branch.ahead = str2nr(mlist[1])
      let branch.behind = str2nr(mlist[2])
    endif
  endif
endfunction

function! s:ProcessSubmodule(submodule_string)
  if a:submodule_string == 'N'
    return {}
  else
    return {
          \ 'commit_changed': a:submodule_string[1] == 'C',
          \ 'staged_changes': a:submodule_string[2] == 'M',
          \ 'unstaged_changes': a:submodule_string[3] == 'U',
          \ }
  endif
endfunction

function! s:ProcessTrackedFile(status_data, line, pathname_original)
  " 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
  " 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>

  let rename = a:line[0] == '2'
  if rename
    let mlist = matchlist(a:line, '\d \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(.\+\)')
    let [change_indicators, submodule, mode_head, mode_index, mode_working, hash_head, hash_index, rename_str, pathname] = mlist[1:9]
    let rename_op = rename_str[0]
    let similarity_score = str2nr(rename_str[1:])
  else
    let mlist = matchlist(a:line, '\d \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(\S\+\) \(.\+\)')
    let [change_indicators, submodule, mode_head, mode_index, mode_working, hash_head, hash_index, pathname] = mlist[1:8]
    let rename_op = ''
    let similarity_score = 0
  endif

  let status_staged = change_indicators[0]
  let status_unstaged = change_indicators[1]

  let record = {
        \ 'pathname': pathname,
        \ 'pathname_original': rename ? a:pathname_original : pathname,
        \ 'status': ' ',
        \ 'section': '',
        \ 'submodule': s:ProcessSubmodule(submodule),
        \ 'hash_head': hash_head,
        \ 'hash_index': hash_index,
        \ }

  if status_staged != '.'
    let record_s = copy(record)
    let record_s.status = status_staged
    let record_s.section = 'staged'
    call insert(a:status_data.staged, record_s)
  endif
  if status_unstaged != '.'
    let record_u = copy(record)
    let record_u.status = status_unstaged
    let record_u.section = 'unstaged'
    call insert(a:status_data.unstaged, record_u)
  endif
endfunction

function! s:ProcessUnmergedFile(status_data, line)
  " u <xy> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>

  let mlist = matchlist(a:line, 'u \(\S\+\) \(\S\+\) \(\S\+ \S\+ \S\+ \S\+\) \(\S\+ \S\+ \S\+\) \(.\+\)')
  let [change_indicators, submodule, modes, hashs, pathname] = mlist[1:5]
  let [mode_stage1, mode_stage2, mode_stage3, mode_working] = split(modes, '\s\+')
  let [hash_stage1, hash_stage2, hash_stage3] = split(hashs, '\s\+')

  let record = {
        \ 'pathname': pathname,
        \ 'pathname_original': pathname,
        \ 'status': 'U',
        \ 'section': 'unmerged',
        \ 'by_us': change_indicators[0],
        \ 'by_them': change_indicators[1],
        \ 'submodule': s:ProcessSubmodule(submodule),
        \ 'hash_merge1': hash_stage1,
        \ 'hash_merge2': hash_stage2,
        \ 'hash_merge3': hash_stage3,
        \ }
  call insert(a:status_data.unmerged, record)
endfunction

function! s:ProcessUntrackedFile(status_data, line, is_ignored)
  " ? <path>
  " ! <path>
  let pathname = matchstr(a:line, '\S\s\+\zs.*')
  let status = a:is_ignored ? 'ignored' : 'untracked'
  call insert(a:status_data[status], {
        \ 'pathname': pathname,
        \ 'status': status,
        \ 'section': status,
        \ })
endfunction

function! s:PrintBranch(branch_info)
  let lines = []
  let lines += ['On branch '.(a:branch_info.head)]

  let upstream = get(a:branch_info, 'upstream', '')
  if upstream != ''
    let ahead = get(a:branch_info, 'ahead', 0)
    let behind = get(a:branch_info, 'behind', 0)
    if ahead == 0 && behind == 0
      let trackig_info = '[up-to-date]'
    elseif ahead > 0 && behind == 0
      let trackig_info = '[ahead '.ahead.']'
    elseif ahead > 0 && behind > 0
      let trackig_info = '[ahead '.ahead.', behind '.behind.']'
    elseif ahead == 0 && behind > 0
      let trackig_info = '[behind '.behind.']'
    endif
    let lines += ['Tracking '.upstream.' '.trackig_info]
  endif

  let commit = get(a:branch_info, 'commit', '')
  if commit == '(initial)'
    let lines += ['', 'No commits yet']
  endif

  call setline(1, lines + [''])
endfunction

function! s:BuildIndex(line_index, list_section)
  for record in a:list_section
    let a:line_index[record.line_printed] = record
  endfor
endfunction

function! s:PrintFileSection(list_section, headers)
  let line_nr = line('$')+1
  let line_first = line_nr

  if !empty(a:list_section)
    call setline(line_nr, a:headers + [''])
    let line_nr += len(a:headers) + 1

    for record in a:list_section
      call setline(line_nr, s:H8 . s:GetStatusString(record.status) . record.pathname)
      let record.line_printed = line_nr
      let line_nr += 1
    endfor

    call setline(line_nr, [''])
    call s:AddFold(line_first, line_nr)
  endif
endfunction

function! s:PrintNothingToCommit(status_data)
  let changes = len(a:status_data.staged) + len(a:status_data.unstaged) + len(a:status_data.unmerged) + len(a:status_data.untracked)
  if changes > 0
    return 0
  endif

  let line_nr = line('$')+1
  call setline(line_nr, ['nothing to commit, working directory clean', ''])
  return 1
endfunction

function! s:GetStatusString ( status )
  return get( s:status_strings, a:status, s:status_strings[' '] )
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

