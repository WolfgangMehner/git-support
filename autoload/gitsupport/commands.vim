"-------------------------------------------------------------------------------
"
"          File:  commands.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  29.11.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#commands#FromCmdLine ( mode, cmd )
  if a:mode == 'direct'
    return gitsupport#run#RunDirect( '', a:cmd, 'env_std', 1 )
  elseif a:mode == 'buffer'
    return s:BufferFromCmdLine( a:cmd )
  endif
endfunction

function! s:BufferFromCmdLine ( args )
  let args = gitsupport#common#ParseShellParseArgs( a:args )
  let cwd = gitsupport#services_path#GetWorkingDir()

  call gitsupport#run#OpenBuffer( 'Git - '.get( args, 0, 'git' ) )
  call gitsupport#run#RunToBuffer( '', args, 'cwd', cwd, 'env_std', 1 )

  command! -nargs=0 -buffer  Help   :call <SID>Help()
  nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
  nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
endfunction

function! s:Help ()
	let text =
				\  "git buffer\n\n"
				\ ."S-F1    : help\n"
				\ ."q       : close\n"
	echo text
endfunction

function! s:Quit ()
	close
endfunction

function! gitsupport#commands#AddFromCmdLine ( q_params )
  if a:q_params == '' && g:Git_AddExpandEmpty == 'yes'
    let params = '-- '.expand( '%:S' )
  else
    let params = a:q_params
  endif

  return gitsupport#run#RunDirect( '', 'add '.params, 'env_std', 1 )
endfunction

function! gitsupport#commands#CheckoutFromCmdLine ( q_params )
  if a:q_params == '' && g:Git_CheckoutExpandEmpty == 'yes'
    if ! gitsupport#common#Question( 'Check out current file?', 'highlight', 'warning' )
      echo "aborted"
      return
    endif

    let params = '-- '.expand( '%:S' )
  else
    let params = a:q_params
  endif

  return gitsupport#run#RunDirect( '', 'checkout '.params, 'env_std', 1 )
endfunction

function! gitsupport#commands#ResetFromCmdLine ( q_params )
  if a:q_params == '' && g:Git_ResetExpandEmpty == 'yes'
    let params = '-- '.expand( '%:S' )
  else
    let params = a:q_params
  endif

  return gitsupport#run#RunDirect( '', 'reset '.params, 'env_std', 1 )
endfunction

function! gitsupport#commands#RmFromCmdLine ( q_params )
  if a:q_params == ''
    let params = '-- '.expand( '%:S' )
  else
    let params = a:q_params
  endif

  let ret_code = gitsupport#run#RunDirect( '', 'rm '.params, 'env_std', 1 )

  if ret_code == 0 && empty ( a:q_params ) && gitsupport#common#Question( 'Delete the current buffer as well?' )
    bdelete
    echo "deleted"
  endif
endfunction

