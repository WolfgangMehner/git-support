"-------------------------------------------------------------------------------
"
"          File:  services_path.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  07.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#services_path#GetWorkingDir ( ... )
  let dir_hint = get( a:000, 0, '' )

  if dir_hint != ''
    return dir_hint
  elseif exists( 'b:GitSupport_CWD' )
    return b:GitSupport_CWD
  elseif &l:filetype ==# 'netrw'
    return b:netrw_curdir
  endif

  return ''
endfunction

function! s:GetOutput ( params, cwd )
  return gitsupport#run#RunDirect( '', a:params,
        \ 'cwd', a:cwd,
        \ 'env_std', 1,
        \ 'mode', 'return' )
endfunction

function! gitsupport#services_path#GetGitDir ( ... )
  let path = get( a:000, 0, 'top' )
  let cwd  = get( a:000, 1, '' )

  if path ==# 'top'
    return s:GetOutput( [ 'rev-parse', '--show-toplevel' ], cwd )
  elseif path =~ '^top/'
    let [ ret_code, base_dir ] = s:GetOutput( [ 'rev-parse', '--show-toplevel' ], cwd )

    if ret_code == 0
      let text = substitute( path, 'top', escape( base_dir, '\&' ), '' )
      return [ 0, fnamemodify( text, ':p' ) ]
    else
      return [ ret_code, base_dir ]
    endif
  elseif path =~ '^git/'
    let [ ret_code, git_dir ] = s:GetOutput( [ 'rev-parse', '--git-dir' ], cwd )

    if ret_code == 0
      let text = substitute( path, 'git', escape( git_dir, '\&' ), '' )
      return [ 0, fnamemodify( text, ':p' ) ]
    else
      return [ ret_code, git_dir ]
    endif
  else
    return s:ErrorMsg( 'unknown option: "'.path.'"' )
  endif
endfunction

function! gitsupport#services_path#SetDir ( dir )
  if a:dir != ''
    let saved_dir = s:GetCurrentDir()
    call s:ChangeDir( a:dir )
    return saved_dir
  else
    return ''
  endif
endfunction

function! gitsupport#services_path#ResetDir ( saved_dir )
  if a:saved_dir != ''
    call s:ChangeDir( a:saved_dir )
  endif
endfunction

function! s:ChangeDir ( dir )
  let cmd = 'cd'

  if haslocaldir()
    let cmd = 'lchdir'
  endif

  exec cmd fnameescape( a:dir )
endfunction

function! s:GetCurrentDir (  )
  return getcwd()
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

