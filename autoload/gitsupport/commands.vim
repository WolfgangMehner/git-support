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
	let git_exec = gitsupport#config#GitExecutable()
	let git_env  = gitsupport#config#Env()

	return gitsupport#run#RunDirect( git_exec, a:cmd.' '.a:q_params, 'env', git_env )
endfunction

function! gitsupport#commands#AddFromCmdLine ( q_params )
	let git_exec = gitsupport#config#GitExecutable()
	let git_env  = gitsupport#config#Env()

	if a:q_params == '' && g:Git_AddExpandEmpty == 'yes'
		let params = '-- '.expand( '%:S' )
	else
		let params = a:q_params
	endif

	return gitsupport#run#RunDirect( git_exec, 'add '.params, 'env', git_env )
endfunction

function! gitsupport#commands#RmFromCmdLine ( q_params )
	let git_exec = gitsupport#config#GitExecutable()
	let git_env  = gitsupport#config#Env()

	if a:q_params == ''
		let params = '-- '.expand( '%:S' )
	else
		let params = a:q_params
	endif

	let ret_code = gitsupport#run#RunDirect( git_exec, 'rm '.params, 'env', git_env )

	if ret_code == 0 && empty ( a:q_params ) && gitsupport#common#Question( 'Delete the current buffer as well?' ) == 1
		bdelete
		echo "deleted"
	endif
endfunction

