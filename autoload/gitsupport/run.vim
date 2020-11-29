"-------------------------------------------------------------------------------
"
"          File:  run.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  23.11.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! s:ErrorMsg ( ... )
	echohl WarningMsg
	for line in a:000
		echomsg line
	endfor
	echohl None
endfunction

function! s:ImportantMsg ( ... )
	echohl Search
	echo join ( a:000, "\n" )
	echohl None
endfunction

function! s:WarningMsg ( ... )
	echohl WarningMsg
	echo join ( a:000, "\n" )
	echohl None
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

function! s:SetDir ( dir )
	if a:dir != ''
		return s:GetCurrentDir()
		call s:ChangeDir( a:dir )
	else
		return ''
	endif
endfunction

function! s:ResetDir ( saved_dir )
	if a:saved_dir != ''
		call s:ChangeDir( a:saved_dir )
	endif
endfunction

function! s:GetEnvStr ( env )
	let env_str = ''
	for [ name, value ] in items( a:env )
		let env_str .= name.'='.shellescape( value ).' '
	endfor
	return env_str
endfunction

function! gitsupport#run#RunDirect ( cmd, params, ... )

	" options
	let opts = {
				\   'env': {},
				\   'cwd': '',
				\   'mode': 'print',
				\ }

	if ! gitsupport#common#ParseOptions( opts, a:000 )
		return
	endif

	let cmd = s:GetEnvStr( opts.env ) . shellescape( a:cmd )

	if type( a:params ) == type( [] ) 
		let cmd .= ' ' . join( a:params, ' ' )
	elseif a:params != ''
		let cmd .= ' ' . a:params
	endif

	let saved_dir = s:SetDir( opts.cwd )

	try
		let text = system( cmd )
	catch /.*/
		call s:WarningMsg (
					\ "internal error " . v:exception,
					\ "   occurred at " . v:throwpoint )
		return [ 255, '' ]
	finally
		call s:ResetDir( saved_dir )
	endtry

	if opts.mode == 'return'
		return [ v:shell_error, substitute( text, '\_s*$', '', '' ) ]
	elseif v:shell_error != 0
		echo ">" cmd "< failed:\n\n".text             | " failure
	elseif text =~ '^\_s*$'
		echo "ran successfully"                       | " success
	else
		echo "ran successfully:\n".text               | " success
	endif
	return v:shell_error
endfunction

let s:all_jobs = []

"function! gitsupport#run#Run ( cmd, params, ... )
"
"	let job_id = job_start(
"				\ [a:cmd] + a:params,
"				\ {} )
"
"	echo ch_info( job_getchannel( job_id ) )
"
"	let text = ''
"
"	while job_status( job_id ) ==# 'run'
"		let line = ch_read( job_id )
"		let text .= line."\n"
"	endwhile
"
"	while ch_status( job_id ) !=# 'closed'
"		let line = ch_read( job_id )
"		let text .= line."\n"
"	endwhile
"
"	"let text = substitute( text, '\n\n*$', '\n', '' )
"	echo text
"
"	return
"endfunction

function! gitsupport#run#RunToBuffer ( cmd, params, ... )

	let job_id = job_start(
				\ [a:cmd] + a:params,
				\ {
				\   'in_io': 'null',
				\   'out_io': 'buffer',
				\   'out_buf': bufnr(),
				\ } )

	call insert( s:all_jobs, job_id )

endfunction

function! gitsupport#run#OpenBuffer( name, ... )

	" options
	let opts = {
				\   'showdir': 0,
				\   'reuse_ontab': 1,
				\   'reuse_other': 0,
				\   'topic': '',
				\ }

	if ! gitsupport#common#ParseOptions( opts, a:000 )
		return
	endif

	if opts.showdir 
		let btype = 'nowrite'                       " like 'nofile', but the directory is shown in the buffer list
	else
		let btype = 'nofile'
	endif

	echo opts

	if 1 
		return
	endif

	let buf_name  = a:name
	let buf_regex = a:name
	if opts.topic != ''
		let buf_name  .= ' ('.opts.topic.')'
		let buf_regex .= ' ([a-zA-Z0-9 :_-]\+)'
	endif
	let buf_regex = '{'.buf_regex.','.buf_regex.' -[0-9]\+-'.'}'

	" a buffer like this already opened on the current tab page?
	if opts.reuse_ontab && bufwinnr( buf_regex ) != -1
		" yes -> go to the window containing the buffer
		exe bufwinnr( buf_regex ).'wincmd w'
		call s:RenameBuffer( buf_name )
		return 0
	endif

	" no -> open a new window
	aboveleft new

	" buffer exists elsewhere?
	if opts.reuse_other && bufnr( buf_regex ) != -1
		" yes -> reuse it
		silent exe 'edit #'.bufnr( buf_regex )
		call s:RenameBuffer( buf_name )
		return 0
	endif

	" no -> settings of the new buffer
	let &l:buftype   = opts.showdir ? 'nowrite' : 'nofile'
	let &l:bufhidden = 'wipe'
	let &l:swapfile  = 0
	let &l:tabstop   = 8
	call s:RenameBuffer( buf_name )

	return 1
endfunction

function! s:RenameBuffer ( name )
	if bufname( '%' ) =~# '\V'.a:name.'\$'
		return
	elseif bufname( '%' ) =~# '\V'.a:name.' -\[0-9]\+-\$'
		return
	endif

	let buf_name = a:name
	if bufnr( buf_name ) != -1
		let nr = 2
		while bufnr( buf_name.' -'.nr.'-' ) != -1
			let nr += 1
		endwhile
		let buf_name = buf_name.' -'.nr.'-'
	endif
	silent exe 'keepalt file '.fnameescape( buf_name )
endfunction

