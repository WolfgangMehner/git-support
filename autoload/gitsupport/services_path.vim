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

function! gitsupport#services_path#GetWorkingDir (  )
  if &l:filetype ==# 'netrw'
    return b:netrw_curdir
  endif

  return ''
endfunction

function! gitsupport#services_path#GetGitDir ( ... )
  if a:0 == 0 || a:1 == '' || a:1 ==# 'top'
    return gitsupport#run#GitOutput( [ 'rev-parse', '--show-toplevel' ] )
  elseif a:1 =~ '^top/'
    let [ ret_code, base_dir ] = gitsupport#run#GitOutput( [ 'rev-parse', '--show-toplevel' ] )

    if ret_code == 0
      let text = substitute( a:1, 'top', escape( base_dir, '\&' ), '' )
      return [ 0, fnamemodify( text, ':p' ) ]
    else
      return [ ret_code, base_dir ]
    endif
  elseif a:1 =~ '^git/'
    let [ ret_code, git_dir ] = gitsupport#run#GitOutput( [ 'rev-parse', '--git-dir' ] )

    if ret_code == 0
      let text = substitute( a:1, 'git', escape( git_dir, '\&' ), '' )
      return [ 0, fnamemodify( text, ':p' ) ]
    else
      return [ ret_code, git_dir ]
    endif
  else
    return s:ErrorMsg( 'unknown option: "'.a:1.'"' )
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

