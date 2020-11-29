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

