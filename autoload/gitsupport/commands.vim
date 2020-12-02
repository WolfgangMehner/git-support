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

function! gitsupport#commands#DirectFromCmdLine ( cmd, q_params )
  return gitsupport#run#RunDirect( '', a:cmd.' '.a:q_params, 'env_std', 1 )
endfunction

function! gitsupport#commands#AddFromCmdLine ( q_params )
	let git_env  = gitsupport#config#Env()

	if a:q_params == '' && g:Git_AddExpandEmpty == 'yes'
		let params = '-- '.expand( '%:S' )
	else
		let params = a:q_params
	endif

	return gitsupport#run#RunDirect( '', 'add '.params, 'env', git_env )
endfunction

function! gitsupport#commands#CheckoutFromCmdLine ( q_params )
	let git_env  = gitsupport#config#Env()

	if a:q_params == '' && g:Git_CheckoutExpandEmpty == 'yes'
		if ! gitsupport#common#Question( 'Check out current file?', 'highlight', 'warning' )
			echo "aborted"
			return
		endif

		let params = '-- '.expand( '%:S' )
	else
		let params = a:q_params
	endif

	return gitsupport#run#RunDirect( '', 'checkout '.params, 'env', git_env )
endfunction

function! gitsupport#commands#ResetFromCmdLine ( q_params )
	let git_env  = gitsupport#config#Env()

	if a:q_params == '' && g:Git_ResetExpandEmpty == 'yes'
		let params = '-- '.expand( '%:S' )
	else
		let params = a:q_params
	endif

	return gitsupport#run#RunDirect( '', 'reset '.params, 'env', git_env )
endfunction

function! gitsupport#commands#RmFromCmdLine ( q_params )
	let git_env  = gitsupport#config#Env()

	if a:q_params == ''
		let params = '-- '.expand( '%:S' )
	else
		let params = a:q_params
	endif

	let ret_code = gitsupport#run#RunDirect( '', 'rm '.params, 'env', git_env )

	if ret_code == 0 && empty ( a:q_params ) && gitsupport#common#Question( 'Delete the current buffer as well?' )
		bdelete
		echo "deleted"
	endif
endfunction

