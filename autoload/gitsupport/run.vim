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

let s:NEOVIM = has("nvim")

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
    let saved_dir = s:GetCurrentDir()
    call s:ChangeDir( a:dir )
    return saved_dir
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

function! gitsupport#run#GitOutput ( params )
  return gitsupport#run#RunDirect( '', a:params, 'env_std', 1, 'mode', 'return' )
endfunction

function! gitsupport#run#RunDirect ( cmd, params, ... )

	" options
	let opts = {
				\   'env': {},
				\   'env_std': 0,
				\   'cwd': '',
				\   'mode': 'print',
				\ }

	if ! gitsupport#common#ParseOptions( opts, a:000 )
		return
	endif

  if type( a:params ) == type( [] )
    let cmd = join( a:params, ' ' )
  elseif a:params != ''
    let cmd = a:params
  endif

  if opts.mode == 'confirm' && ! gitsupport#common#Question( 'execute "git '.cmd.'"?' )
    echo "aborted"
    return
  endif

  if a:cmd == ''
    let cmd = shellescape( gitsupport#config#GitExecutable() ).' '.cmd
  else
    let cmd = shellescape( a:cmd ).' '.cmd
  endif

  if opts.env_std
    let cmd = s:GetEnvStr( gitsupport#config#Env() ) . cmd
  else
    let cmd = s:GetEnvStr( opts.env ) . cmd
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

function! gitsupport#run#RunToBuffer ( cmd, params, ... )

  " options
  let opts = {
        \ 'env': {},
        \ 'env_std': 0,
        \ 'cwd': '',
        \ 'keep': 0,
        \ 'callback': function( 's:Empty' ),
        \ 'restore_cursor': 0,
        \ }

  if ! gitsupport#common#ParseOptions( opts, a:000 )
    return
  endif

  " pause syntax highlighting (for speed)
  if &syntax != ''
    setlocal syntax=OFF
  endif

  if opts.restore_cursor
    let opts.restore_cursor = gitsupport#common#BufferGetPosition()
  else
    let opts.restore_cursor = []
  endif
  if ! opts.keep
    call gitsupport#common#BufferWipe()
  endif

  if a:cmd == ''
    let cmd = gitsupport#config#GitExecutable()
  else
    let cmd = a:cmd
  endif

  if opts.env_std
    let opts.env = gitsupport#config#Env()
  endif

  if s:NEOVIM
    call gitsupport#run_nvim#JobRun( cmd, a:params, opts )
  else
    call gitsupport#run_vim#JobRun( cmd, a:params, opts )
  endif
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

function! gitsupport#run#OpenFile ( filename, ... )

  " options
  let opts = {
        \ 'line': -1,
        \ 'column': -1,
        \ 'open_fold': g:Git_OpenFoldAfterJump == 'yes',
        \ }

  if ! gitsupport#common#ParseOptions( opts, a:000 )
    return
  endif

  let filename = a:filename

  if bufwinnr( '^'.filename.'$' ) == -1
    " open buffer
    belowright new
    exe "edit ".fnameescape( filename )
  else
    " jump to window
    exe bufwinnr( '^'.filename.'$' ).'wincmd w'
  endif

  if opts.line != -1
    " jump to line
    let pos = getpos( '.' )
    let pos[1] = opts.line
    if opts.column != -1
      let pos[2] = opts.column
    endif
    call setpos( '.', pos )
  endif

  if foldlevel('.') && opts.open_fold
    normal! zv
  endif
endfunction

function! s:Empty ()
endfunction

