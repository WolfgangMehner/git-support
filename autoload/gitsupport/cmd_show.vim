"-------------------------------------------------------------------------------
"
"          File:  cmd_show.vim
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

let s:RevisionNames = {
			\ ':'   : 'STAGED',
			\ ':0:' : 'STAGED',
			\ ':1:' : 'COMMON_ANCESTOR',
			\ ':2:' : 'TARGET_BRANCH',
			\ ':3:' : 'SOURCE_BRANCH',
			\ }

function! gitsupport#cmd_show#FromCmdLine ( q_params )
	let args = gitsupport#common#ParseShellParseArgs( a:q_params )
	return gitsupport#cmd_show#OpenBuffer ( args )
endfunction

function! gitsupport#cmd_show#OpenBuffer ( params )
	let params = a:params

	if empty( params )
		let [ last_arg, obj_type ] = [ 'HEAD', 'commit' ]
	else
		let [ last_arg, obj_type ] = s:AnalyseObject ( params[-1] )
	endif

	" BLOB: treat separately
	if obj_type == 'blob'
		if last_arg =~ '\_^:[0123]:\|\_^:[^/]'
			let obj_src = s:RevisionNames[ matchstr( last_arg, '\_^:[0123]:\|\_^:' ) ]
			let last_arg = substitute( last_arg, '\_^:[0123]:\|\_^:', obj_src.'.', '' )
		endif

		let last_arg = substitute( last_arg, ':', '.', '' )
		let last_arg = substitute( last_arg, '/', '.', 'g' )

		call gitsupport#run#OpenBuffer( last_arg )
		call gitsupport#run#RunToBuffer( '', ['show'] + params )

		nnoremap          <buffer> sh     :call <SID>HelpBlob()<CR>
		nnoremap          <buffer> <S-F1> :call <SID>HelpBlob()<CR>
		nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>

		"filetype detect
		return
	else
    call gitsupport#run#OpenBuffer( 'Git - show' )
    call s:Run( params )

		nnoremap          <buffer> sh     :call <SID>Help()<CR>
		nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
		nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
		nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

		let b:GitSupport_Param = params
	endif
endfunction

function! s:AnalyseObject( obj_name )
	let [ ret_code, obj_type ] = gitsupport#run#GitOutput( [ 'cat-file', "-t", shellescape( a:obj_name ) ] )

	if ret_code == 0
		return [ a:obj_name, obj_type ]
	else
		return [ '', '' ]
	endif
endfunction

function! s:Help ()
	let text =
				\  "git show\n\n"
				\ ."sh S-F1 : help\n"
				\ ."q       : close\n"
				\ ."u       : update"
	echo text
endfunction

function! s:HelpBlob ()
	let text =
				\  "git show (blob)\n\n"
				\ ."sh S-F1 : help\n"
				\ ."q       : close\n"
				\ ."u       : update"
	echo text
endfunction

function! s:Quit ()
	close
endfunction

function! s:Run ( params )
  call gitsupport#run#RunToBuffer( '', ['show'] + a:params, 'callback', function( 's:Wrap' ) )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param )
endfunction

function! s:Wrap ()
  setlocal filetype=gitslog
  setlocal foldtext=GitS_FoldLog()
endfunction
