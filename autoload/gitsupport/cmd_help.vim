"-------------------------------------------------------------------------------
"
"          File:  cmd_help.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  19.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:Features = gitsupport#config#Features()

let s:UseHtmlHelp = 0
if s:Features.is_executable_git
  let [ ret_code, help_format ] = gitsupport#config#GitConfig( 'help.format', '' )
  if ret_code == 0
    let s:UseHtmlHelp = help_format == 'html' || help_format == 'web'
  end
endif

let help_data = gitsupport#data#LoadData( 'basic' )
let s:HelpTopics = get( help_data, 'commands', [] )
      \          + get( help_data, 'additional_help_topics', [] )

function! gitsupport#cmd_help#ShowHelp ( topic )
  return gitsupport#cmd_help#OpenBuffer( a:topic )
endfunction

function! gitsupport#cmd_help#OpenBuffer ( topic )
  if s:UseHtmlHelp
    return gitsupport#run#RunDirect( '', ['help', a:topic], 'env_std', 1 )
  else
    call gitsupport#run#OpenBuffer( 'Git - help', 'topic', a:topic )

    " :WORKAROUND:05.04.2016 21:05:WM: setting the filetype changes the global tabstop
    let ts_save = &g:tabstop
    let &l:filetype = 'man'
    let &g:tabstop = ts_save

    call s:Run( a:topic )

    command! -nargs=0 -buffer  Help   :call <SID>Help()
    nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
    nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>

    let b:GitSupport_Param = [ a:topic ]
  endif
endfunction

function! s:Help ()
  let text =
        \  "git help\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( topic )
  let env = gitsupport#config#Env()
  if s:Features.running_unix && winwidth(winnr()) > 0
    let env.MANWIDTH = ''.winwidth(winnr())
  endif
  call gitsupport#run#RunToBuffer( '', ['help', a:topic], 'env', env )
endfunction

function! gitsupport#cmd_help#Complete ( ArgLead, CmdLine, CursorPos )
  return filter( copy( s:HelpTopics ), 'v:val =~ "\\V\\<'.escape(a:ArgLead,'\').'\\w\\*"' )
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

