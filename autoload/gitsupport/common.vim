"-------------------------------------------------------------------------------
"
"          File:  common.vim
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

function! s:ErrorMsg ( ... )
	echohl WarningMsg
	for line in a:000
		echomsg line
	endfor
	echohl None
endfunction

function! gitsupport#common#ParseOptions ( opts, args )

	let opts = a:opts
	let vargs = a:args
	let nargs = len( a:args )

	let idx = 0
	while idx < nargs
		let key = vargs[idx]
		if ! has_key( opts, key )
			call s:ErrorMsg( 'unknown option: '.key )
			return 0
		elseif idx+1 >= nargs
			call s:ErrorMsg( 'value missing: '.key )
			return 0
		elseif type( vargs[idx+1] ) != type( opts[key] )
			call s:ErrorMsg( 'value has wrong type: '.key )
			return 0
		endif

		let opts[key] = vargs[idx+1]
		let idx += 2
	endwhile
	return 1
endfunction

function! gitsupport#common#ParseShellParseArgs ( line )

	let list = []
	let curr = ''

	let line = a:line

	while line != ''

		if match ( line, '^\s' ) != -1
			" non-escaped space -> finishes current argument
			let line = matchstr ( line, '^\s\+\zs.*' )
			if curr != ''
				call add ( list, curr )
				let curr = ''
			endif
		elseif match ( line, "^'" ) != -1
			" start of a single-quoted string, parse past next single quote
			let mlist = matchlist ( line, "^'\\([^']*\\)'\\(.*\\)" )
			if empty ( mlist )
				throw "ShellParseArgs:Syntax:no matching quote '"
			endif
			let curr .= mlist[1]
			let line  = mlist[2]
		elseif match ( line, '^"' ) != -1
			" start of a double-quoted string, parse past next double quote
			let mlist = matchlist ( line, '^"\(\%([^\"]\|\\.\)*\)"\(.*\)' )
			if empty ( mlist )
				throw 'ShellParseArgs:Syntax:no matching quote "'
			endif
			let curr .= substitute ( mlist[1], '\\\([\"]\)', '\1', 'g' )
			let line  = mlist[2]
		elseif match ( line, '^\\' ) != -1
			" escape sequence outside of a string, parse one additional character
			let mlist = matchlist ( line, '^\\\(.\)\(.*\)' )
			if empty ( mlist )
				throw 'ShellParseArgs:Syntax:single backspace \'
			endif
			let curr .= mlist[1]
			let line  = mlist[2]
		else
			" otherwise parse up to next special char.: space, backslash, quote
			let mlist = matchlist ( line, '^\([^[:space:]\\''"]\+\)\(.*\)' )
			let curr .= mlist[1]
			let line  = mlist[2]
		endif
	endwhile

	" add last argument
	if curr != ''
		call add ( list, curr )
	endif

	return list
endfunction

function! gitsupport#common#Question ( text, ... )

	" options
	let opts = {
				\   'highlight': 'normal',
				\ }

	if ! gitsupport#common#ParseOptions( opts, a:000 )
		return
	endif

	" highlight prompt
	if opts.highlight == 'normal'
		echohl Search
	elseif opts.highlight == 'warning'
		echohl Error
	else
		return s:ErrorMsg( 'unknown highlight: '.opts.highlight )
	endif

	" question
	echo a:text.' [y/n]: '

	" answer: "y", "n", "ESC" or "CTRL-C"
	let ret = -2

	while ret == -2
		let c = nr2char( getchar() )

		if c ==? "y"
			let ret = 1
		elseif c ==? "n"
			let ret = 0
		elseif c == "\<ESC>" || c == "\<C-C>"
			let ret = -1
		endif
	endwhile

	" reset highlighting
	echohl None

	return ret == 1
endfunction

