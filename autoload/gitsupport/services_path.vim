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

function! gitsupport#services_path#GetGitDir (  )
  return gitsupport#run#GitOutput( [ 'rev-parse', '--show-toplevel' ] )
endfunction

