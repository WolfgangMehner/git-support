"-------------------------------------------------------------------------------
"
"          File:  cmd_edit.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  19.12.2020
"      Revision:  28.12.2021
"       License:  Copyright (c) 2020-2021, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:EditFileIDs = [
      \ 'config-global', 'config-local',
      \ 'description',
      \ 'hooks',
      \ 'ignore-global', 'ignore-local', 'ignore-private',
      \ 'modules',
      \ ]

function! gitsupport#cmd_edit#EditFile ( fileid )
  let cwd = gitsupport#services_path#GetWorkingDir()

  let ret_code = 0
  let filename = ''
  let is_absolute = 0

  if a:fileid == 'config-global'
    let filename = expand( '$HOME/.gitconfig' )
  elseif a:fileid == 'config-local'
    if exists( '$GIT_CONFIG' )
      let filename = $GIT_CONFIG
    else
      let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'git/config', cwd )
    endif
  elseif a:fileid == 'description'
    let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'git/description', cwd )
  elseif a:fileid == 'hooks'
    let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'git/hooks/', cwd )
  elseif a:fileid == 'ignore-global'
    let [ ret_code, filename ] = gitsupport#config#GitConfig( 'core.excludesfile', '' )
    let is_absolute = 1
  elseif a:fileid == 'ignore-local'
    let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'top/.gitignore', cwd )
  elseif a:fileid == 'ignore-private'
    let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'git/info/exclude', cwd )
  elseif a:fileid == 'modules'
    let [ ret_code, filename ] = gitsupport#services_path#GetGitDir( 'top/.gitmodules', cwd )
  endif

  if ret_code != 0
    return s:ErrorMsg( 'could not obtain the filename' )
  elseif filename == ''
    return s:ErrorMsg ( 'no file with ID "'.a:fileid.'".' )
  else
    exe 'spl '.fnameescape( filename )
  endif
endfunction

function! gitsupport#cmd_edit#Complete ( ArgLead, CmdLine, CursorPos )
  return filter( copy( s:EditFileIDs ), 'v:val =~ "\\V\\<'.escape(a:ArgLead,'\').'\\w\\*"' )
endfunction

function! gitsupport#cmd_edit#Options ()
  return copy( s:EditFileIDs )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

