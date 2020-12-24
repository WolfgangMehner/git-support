"===============================================================================
"
"          File:  git-support.vim
" 
"   Description:  Provides access to Git's functionality from inside Vim.
" 
"                 See help file gitsupport.txt .
"
"   VIM Version:  7.4+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"  Organization:  
"       Version:  see variable g:GitSupport_Version below
"       Created:  06.10.2012
"      Revision:  18.07.2020
"       License:  Copyright (c) 2012-2020, Wolfgang Mehner
"                 This program is free software; you can redistribute it and/or
"                 modify it under the terms of the GNU General Public License as
"                 published by the Free Software Foundation, version 2 of the
"                 License.
"                 This program is distributed in the hope that it will be
"                 useful, but WITHOUT ANY WARRANTY; without even the implied
"                 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
"                 PURPOSE.
"                 See the GNU General Public License version 2 for more details.
"===============================================================================

"-------------------------------------------------------------------------------
" Basic checks.   {{{1
"-------------------------------------------------------------------------------

" need at least 7.4
if v:version < 740
	echohl WarningMsg
	echo 'The plugin git-support.vim needs Vim version >= 7.4'
	echohl None
	finish
endif

" prevent duplicate loading
" need compatible
if &cp || ( exists('g:GitSupport_Version') && ! exists('g:GitSupport_DevelopmentOverwrite') )
	finish
endif
let g:GitSupport_Version= '0.9.9-dev'     " version number of this script; do not change

"-------------------------------------------------------------------------------
" Auxiliary functions.   {{{1
"-------------------------------------------------------------------------------
"
"-------------------------------------------------------------------------------
" s:ApplyDefaultSetting : Write default setting to a global variable.   {{{2
"
" Parameters:
"   varname - name of the variable (string)
"   value   - default value (string)
" Returns:
"   -
"
" If g:<varname> does not exists, assign:
"   g:<varname> = value
"-------------------------------------------------------------------------------

function! s:ApplyDefaultSetting ( varname, value )
	if ! exists( 'g:'.a:varname )
		let {'g:'.a:varname} = a:value
	endif
endfunction

"-------------------------------------------------------------------------------
" s:AssembleCmdLine : Assembles a cmd-line with the cursor in the right place.   {{{2
"
" Parameters:
"   part1 - part left of the cursor (string)
"   part2 - part right of the cursor (string)
"   left  - used to move the cursor left (string, optional)
" Returns:
"   cmd_line - the command line (string)
"-------------------------------------------------------------------------------
"
function! s:AssembleCmdLine ( part1, part2, ... )
	if a:0 == 0 || a:1 == ''
		let left = "\<Left>"
	else
		let left = a:1
	endif
	return a:part1.a:part2.repeat( left, s:UnicodeLen( a:part2 ) )
endfunction    " ----------  end of function s:AssembleCmdLine  ----------
"
"-------------------------------------------------------------------------------
" s:ChangeCWD : Check the buffer and the CWD.   {{{2
"
" Parameters:
"   [ bufnr, dir ] - data (list: integer and string, optional)
" Returns:
"   -
"
" Example:
" First check the current working directory:
"   let data = s:CheckCWD ()
" then jump to the Git buffer:
"   call s:OpenGitBuffer ( 'Git - <name>' )
" then call this function to correctly set the directory of the buffer:
"   call s:ChangeCWD ( data )
"
" Usage:
" The function s:CheckCWD queries the working directory of the buffer your
" starting out in, which is the buffer where you called the Git command. The
" call to s:OpenGitBuffer then opens the requested buffer or jumps to it if it
" already exists. Finally, s:ChangeCWD sets the working directory of the Git
" buffer.
" The buffer 'data' is a list, containing first the number of the current buffer
" at the time s:CheckCWD was called, and second the name of the directory.
"
" When called without parameters, changes to the directory stored in
" 'b:GitSupport_CWD'.
"-------------------------------------------------------------------------------
"
function! s:ChangeCWD ( ... )
	"
	" call originated from outside the Git buffer?
	" also the case for a new buffer
	if a:0 == 0
		if ! exists ( 'b:GitSupport_CWD' )
			call s:ErrorMsg ( 'Not inside a Git buffer.' )
			return
		endif
	elseif bufnr('%') != a:1[0]
		"echomsg '2 - call from outside: '.a:1[0]
		let b:GitSupport_CWD = a:1[1]
	else
		"echomsg '2 - call from inside: '.bufnr('%')
		" noop
	endif
	"
	" change buffer
	"echomsg '3 - changing to: '.b:GitSupport_CWD
	exe	'lchdir '.fnameescape( b:GitSupport_CWD )
endfunction    " ----------  end of function s:ChangeCWD  ----------
"
"-------------------------------------------------------------------------------
" s:CheckCWD : Check the buffer and the CWD.   {{{2
"
" Parameters:
"   -
" Returns:
"   [ bufnr, dir ] - data (list: integer and string)
"
" Usage: see s:ChangeCWD
"-------------------------------------------------------------------------------
"
function! s:CheckCWD ()
	"echomsg '1 - calling from: '.getcwd()
	return [ bufnr('%'), getcwd() ]
endfunction    " ----------  end of function s:CheckCWD  ----------
"
"-------------------------------------------------------------------------------
" s:ErrorMsg : Print an error message.   {{{2
"
" Parameters:
"   line1 - a line (string)
"   line2 - a line (string)
"   ...   - ...
" Returns:
"   -
"-------------------------------------------------------------------------------

function! s:ErrorMsg ( ... )
	echohl WarningMsg
	for line in a:000
		echomsg line
	endfor
	echohl None
endfunction    " ----------  end of function s:ErrorMsg  ----------

"-------------------------------------------------------------------------------
" s:EscapeCurrent : Escape the name of the current file for the shell,   {{{2
"     and prefix it with "--".
"
" Parameters:
"   -
" Returns:
"   file_argument - the escaped filename (string)
"-------------------------------------------------------------------------------
"
function! s:EscapeCurrent ()
	return '-- '.shellescape ( expand ( '%' ) )
endfunction    " ----------  end of function s:EscapeCurrent  ----------
"
"-------------------------------------------------------------------------------
" s:GetGlobalSetting : Get a setting from a global variable.   {{{2
"
" Parameters:
"   varname - name of the variable (string)
"   glbname - name of the global variable (string, optional)
" Returns:
"   -
"
" If 'glbname' is given, it is used as the name of the global variable.
" Otherwise the global variable will also be named 'varname'.
"
" If g:<glbname> exists, assign:
"   s:<varname> = g:<glbname>
"-------------------------------------------------------------------------------

function! s:GetGlobalSetting ( varname, ... )
	let lname = a:varname
	let gname = a:0 >= 1 ? a:1 : lname
	if exists( 'g:'.gname )
		let {'s:'.lname} = {'g:'.gname}
	endif
endfunction

"-------------------------------------------------------------------------------
" s:ImportantMsg : Print an important message.   {{{2
"
" Parameters:
"   line1 - a line (string)
"   line2 - a line (string)
"   ...   - ...
" Returns:
"   -
"-------------------------------------------------------------------------------

function! s:ImportantMsg ( ... )
	echohl Search
	echo join ( a:000, "\n" )
	echohl None
endfunction    " ----------  end of function s:ImportantMsg  ----------

"-------------------------------------------------------------------------------
" s:Redraw : Redraw depending on whether a GUI is running.   {{{2
"
" Example:
"   call s:Redraw ( 'r!', '' )
" Clear the screen and redraw in a terminal, do nothing when a GUI is running.
"
" Parameters:
"   cmd_term - redraw command in terminal mode (string)
"   cmd_gui -  redraw command in GUI mode (string)
" Returns:
"   -
"-------------------------------------------------------------------------------

function! s:Redraw ( cmd_term, cmd_gui )
	if has('gui_running')
		let cmd = a:cmd_gui
	else
		let cmd = a:cmd_term
	endif

	let cmd = substitute ( cmd, 'r\%[edraw]', 'redraw', '' )
	if cmd != ''
		silent exe cmd
	endif
endfunction    " ----------  end of function s:Redraw  ----------

"-------------------------------------------------------------------------------
" s:Question : Ask the user a question.   {{{2
"
" Parameters:
"   prompt    - prompt, shown to the user (string)
"   highlight - "normal" or "warning" (string, default "normal")
" Returns:
"   retval - the user input (integer)
"
" The possible values of 'retval' are:
"    1 - answer was yes ("y")
"    0 - answer was no ("n")
"   -1 - user aborted ("ESC" or "CTRL-C")
"-------------------------------------------------------------------------------
"
function! s:Question ( text, ... )
	"
	let ret = -2
	"
	" highlight prompt
	if a:0 == 0 || a:1 == 'normal'
		echohl Search
	elseif a:1 == 'warning'
		echohl Error
	else
		echoerr 'Unknown option : "'.a:1.'"'
		return
	endif
	"
	" question
	echo a:text.' [y/n]: '
	"
	" answer: "y", "n", "ESC" or "CTRL-C"
	while ret == -2
		let c = nr2char( getchar() )
		"
		if c == "y"
			let ret = 1
		elseif c == "n"
			let ret = 0
		elseif c == "\<ESC>" || c == "\<C-C>"
			let ret = -1
		endif
	endwhile
	"
	" reset highlighting
	echohl None
	"
	return ret
endfunction    " ----------  end of function s:Question  ----------

"-------------------------------------------------------------------------------
" s:SID : Return the <SID>.   {{{2
"
" Parameters:
"   -
" Returns:
"   SID - the SID of the script (string)
"-------------------------------------------------------------------------------

function! s:SID ()
	return matchstr ( expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$' )
endfunction    " ----------  end of function s:SID  ----------

"-------------------------------------------------------------------------------
" s:StandardRun : execute 'git <cmd> ...'   {{{2
"
" Parameters:
"   cmd     - the Git command to run (string), this is not the Git executable!
"   param   - the parameters (string)
"   flags   - all set flags (string)
"   allowed - all allowed flags (string, default: 'cet')
" Returns:
"   [ ret, text ] - the status code and text produced by the command (string),
"                   only if the flag 't' is set
"
" Flags are characters. The parameter 'flags' is a concatenation of all set
" flags, the parameter 'allowed' is a concatenation of all allowed flags.
"
" Flags:
"   c - ask for confirmation
"   e - expand empty 'param' to current buffer
"   t - return the text instead of echoing it
"-------------------------------------------------------------------------------
"
function! s:StandardRun( cmd, param, flags, ... )
	"
	if a:0 == 0
		let flag_check = '[^cet]'
	else
		let flag_check = '[^'.a:1.']'
	endif
	"
	if a:flags =~ flag_check
		return s:ErrorMsg ( 'Unknown flag "'.matchstr( a:flags, flag_check ).'".' )
	endif
	"
	if a:flags =~ 'e' && empty( a:param ) | let param = s:EscapeCurrent()
	else                                  | let param = a:param
	endif
	"
	let cmd = s:Git_Executable.' '.a:cmd.' '.param
	"
	if a:flags =~ 'c' && s:Question ( 'Execute "git '.a:cmd.' '.param.'"?' ) != 1
		echo "aborted"
		return
	endif
	"
	let text = system ( cmd )
	"
	if a:flags =~ 't'
		return [ v:shell_error, substitute ( text, '\_s*$', '', '' ) ]
	elseif v:shell_error != 0
		echo "\"".cmd."\" failed:\n\n".text           | " failure
	elseif text =~ '^\_s*$'
		echo "ran successfully"                       | " success
	else
		echo "ran successfully:\n".text               | " success
	endif
	"
endfunction    " ----------  end of function s:StandardRun  ----------
"
"-------------------------------------------------------------------------------
" s:UnicodeLen : Number of characters in a Unicode string.   {{{2
"
" Parameters:
"   str - a string (string)
" Returns:
"   len - the length (integer)
"
" Returns the correct length in the presence of Unicode characters which take
" up more than one byte.
"-------------------------------------------------------------------------------
"
function! s:UnicodeLen ( str )
	return len(split(a:str,'.\zs'))
endfunction    " ----------  end of function s:UnicodeLen  ----------
"
"-------------------------------------------------------------------------------
" s:VersionLess : Compare two version numbers.   {{{2
"
" Parameters:
"   v1 - 1st version number (string)
"   v2 - 2nd version number (string)
" Returns:
"   less - true, if v1 < v2 (string)
"-------------------------------------------------------------------------------
"
function! s:VersionLess ( v1, v2 )
	"
	let l1 = matchlist( a:v1, '^\(\d\+\)\.\(\d\+\)\%(\.\(\d\+\)\)\?\%(\.\(\d\+\)\)\?' )
	let l2 = matchlist( a:v2, '^\(\d\+\)\.\(\d\+\)\%(\.\(\d\+\)\)\?\%(\.\(\d\+\)\)\?' )
	"
	if empty( l1 ) || empty( l2 )
		echoerr 'Can not compare version numbers "'.a:v1.'" and "'.a:v2.'".'
		return
	endif
	"
	for i in range( 1, 4 )
		" all previous numbers have been identical!
		if empty(l2[i])
			" l1[i] is empty as well or "0"  -> versions are the same
			" l1[i] is not empty             -> v1 can not be less
			return 0
		elseif empty(l1[i])
			" only l1[i] is empty -> v2 must be larger, unless l2[i] is "0"
			return l2[i] != 0
		elseif str2nr(l1[i]) != str2nr( l2[i] )
			return str2nr(l1[i]) < str2nr( l2[i] )
		endif
	endfor
	"
	echoerr 'Something went wrong while comparing "'.a:v1.'" and "'.a:v2.'".'
	return -1
endfunction    " ----------  end of function s:VersionLess  ----------

"-------------------------------------------------------------------------------
" s:WarningMsg : Print a warning/error message.   {{{2
"
" Parameters:
"   line1 - a line (string)
"   line2 - a line (string)
"   ...   - ...
" Returns:
"   -
"-------------------------------------------------------------------------------

function! s:WarningMsg ( ... )
	echohl WarningMsg
	echo join ( a:000, "\n" )
	echohl None
endfunction    " ----------  end of function s:WarningMsg  ----------

" }}}2
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
" Custom menus.   {{{1
"-------------------------------------------------------------------------------
"
"-------------------------------------------------------------------------------
" s:GenerateCustomMenu : Generate custom menu entries.   {{{2
"
" Parameters:
"   prefix - defines the menu the entries will be placed in (string)
"   data   - custom menu entries (list of lists of strings)
" Returns:
"   -
"
" See :help g:Git_CustomMenu for a description of the format 'data' uses.
"-------------------------------------------------------------------------------
"
function! s:GenerateCustomMenu ( prefix, data )
	"
	for [ entry_l, entry_r, cmd ] in a:data
		" escape special characters and assemble entry
		let entry_l = escape ( entry_l, ' |\' )
		let entry_l = substitute ( entry_l, '\.\.', '\\.', 'g' )
		let entry_r = escape ( entry_r, ' .|\' )
		"
		if entry_r == '' | let entry = a:prefix.'.'.entry_l
		else             | let entry = a:prefix.'.'.entry_l.'<TAB>'.entry_r
		endif
		"
		if cmd == ''
			let cmd = ':'
		endif
		"
		let silent = '<silent> '
		"
		" prepare command
		if cmd =~ '<CURSOR>'
			let mlist = matchlist ( cmd, '^\(.\+\)<CURSOR>\(.\{-}\)$' )
			let cmd = s:AssembleCmdLine ( mlist[1], mlist[2], '<Left>' )
			let silent = ''
		elseif cmd =~ '<EXECUTE>$'
			let cmd = substitute ( cmd, '<EXECUTE>$', '<CR>', '' )
		endif
		"
		let cmd = substitute ( cmd, '<WORD>',   '<cword>', 'g' )
		let cmd = substitute ( cmd, '<FILE>',   '<cfile>', 'g' )
		let cmd = substitute ( cmd, '<BUFFER>', '%',       'g' )
		"
		exe 'anoremenu '.silent.entry.'      '.cmd
		exe 'vnoremenu '.silent.entry.' <C-C>'.cmd
	endfor
	"
endfunction    " ----------  end of function s:GenerateCustomMenu  ----------
" }}}2
"-------------------------------------------------------------------------------
"
"-------------------------------------------------------------------------------
" Modul setup.   {{{1
"-------------------------------------------------------------------------------
"
"-------------------------------------------------------------------------------
" command lists, help topics   {{{2
"
let s:GitCommands = [
			\ 'add',               'add--interactive',         'am',                'annotate',           'apply',
			\ 'archive',           'bisect',                   'bisect--helper',    'blame',              'branch',
			\ 'bundle',            'cat-file',                 'check-attr',        'checkout',           'checkout-index',
			\ 'check-ref-format',  'cherry',                   'cherry-pick',       'citool',             'clean',
			\ 'clone',             'commit',                   'commit-tree',       'config',             'count-objects',
			\ 'credential-cache',  'credential-cache--daemon', 'credential-store',  'daemon',             'describe',
			\ 'diff',              'diff-files',               'diff-index',        'difftool',           'difftool--helper',
			\ 'diff-tree',         'fast-export',              'fast-import',       'fetch',              'fetch-pack',
			\ 'filter-branch',     'fmt-merge-msg',            'for-each-ref',      'format-patch',       'fsck',
			\ 'fsck-objects',      'gc',                       'get-tar-commit-id', 'grep',               'gui',
			\ 'gui--askpass',      'hash-object',              'help',              'http-backend',       'http-fetch',
			\ 'http-push',         'imap-send',                'index-pack',        'init',               'init-db',
			\ 'instaweb',          'log',                      'lost-found',        'ls-files',           'ls-remote',
			\ 'ls-tree',           'mailinfo',                 'mailsplit',         'merge',              'merge-base',
			\ 'merge-file',        'merge-index',              'merge-octopus',     'merge-one-file',     'merge-ours',
			\ 'merge-recursive',   'merge-resolve',            'merge-subtree',     'mergetool',          'merge-tree',
			\ 'mktag',             'mktree',                   'mv',                'name-rev',           'notes',
			\ 'pack-objects',      'pack-redundant',           'pack-refs',         'patch-id',           'peek-remote',
			\ 'prune',             'prune-packed',             'pull',              'push',               'quiltimport',
			\ 'read-tree',         'rebase',                   'receive-pack',      'reflog',             'relink',
			\ 'remote',            'remote-ext',               'remote-fd',         'remote-ftp',         'remote-ftps',
			\ 'remote-http',       'remote-https',             'remote-testgit',    'repack',             'replace',
			\ 'repo-config',       'request-pull',             'rerere',            'reset',              'revert',
			\ 'rev-list',          'rev-parse',                'rm',                'send-pack',          'shell',
			\ 'sh-i18n--envsubst', 'shortlog',                 'show',              'show-branch',        'show-index',
			\ 'show-ref',          'stage',                    'stash',             'status',             'stripspace',
			\ 'submodule',         'symbolic-ref',             'tag',               'tar-tree',           'unpack-file',
			\ 'unpack-objects',    'update-index',             'update-ref',        'update-server-info', 'upload-archive',
			\ 'upload-pack',       'var',                      'verify-pack',       'verify-tag',         'web--browse',
			\ 'whatchanged',       'write-tree',
			\ ]

"-------------------------------------------------------------------------------
" == Platform specific items ==   {{{2
"-------------------------------------------------------------------------------

let s:MSWIN = has("win16") || has("win32")   || has("win64")     || has("win95")
let s:UNIX	= has("unix")  || has("macunix") || has("win32unix")

let s:NEOVIM = has("nvim")

if s:MSWIN
	"
	"-------------------------------------------------------------------------------
	" MS Windows
	"-------------------------------------------------------------------------------
	"
	if match(      substitute( expand('<sfile>'), '\\', '/', 'g' ),
				\   '\V'.substitute( expand('$HOME'),   '\\', '/', 'g' ) ) == 0
		" user installation assumed
		let s:installation = 'local'
	else
		" system wide installation
		let s:installation = 'system'
	endif
	"
	let s:plugin_dir = substitute( expand('<sfile>:p:h:h'), '\\', '/', 'g' )
	"
else
	"
	"-------------------------------------------------------------------------------
	" Linux/Unix
	"-------------------------------------------------------------------------------
	"
	if match( expand('<sfile>'), '\V'.resolve(expand('$HOME')) ) == 0
		" user installation assumed
		let s:installation = 'local'
	else
		" system wide installation
		let s:installation = 'system'
	endif
	"
	let s:plugin_dir = expand('<sfile>:p:h:h')
	"
endif

"-------------------------------------------------------------------------------
" == Various settings ==   {{{2
"-------------------------------------------------------------------------------

let s:Git_NextGen = 0
call s:GetGlobalSetting ( 'Git_NextGen' )

call gitsupport#config#GitExecutable()

let s:Git_LoadMenus      = 'yes'    " load the menus?
let s:Git_RootMenu       = '&Git'   " name of the root menu
"
let s:Git_CmdLineOptionsFile = s:plugin_dir.'/git-support/data/options.txt'
"
if ! exists ( 's:MenuVisible' )
	let s:MenuVisible = 0           " menus are not visible at the moment
endif
"
let s:Git_CustomMenu = [
			\ [ '&grep, word under cursor',  ':GitGrepTop', ':GitGrepTop <WORD><EXECUTE>' ],
			\ [ '&grep, version x..y',       ':GitGrepTop', ':GitGrepTop -i "Version[^[:digit:]]\+<CURSOR>"' ],
			\ [ '-SEP1-',                    '',            '' ],
			\ [ '&log, grep commit msg..',   ':GitLog',     ':GitLog -i --grep="<CURSOR>"' ],
			\ [ '&log, grep diff word',      ':GitLog',     ':GitLog -p -S "<CURSOR>"' ],
			\ [ '&log, grep diff line',      ':GitLog',     ':GitLog -p -G "<CURSOR>"' ],
			\ [ '-SEP2-',                    '',            '' ],
			\ [ '&merge, fast-forward only', ':GitMerge',   ':GitMerge --ff-only <CURSOR>' ],
			\ [ '&merge, no commit',         ':GitMerge',   ':GitMerge --no-commit <CURSOR>' ],
			\ [ '&merge, abort',             ':GitMerge',   ':GitMerge --abort<EXECUTE>' ],
			\ ]
"
if s:MSWIN
	let s:Git_BinPath = 'C:\Program Files\Git\bin\'
else
	let s:Git_BinPath = ''
endif
"
call s:GetGlobalSetting ( 'Git_BinPath' )
"
if s:MSWIN
	let s:Git_BinPath = substitute ( s:Git_BinPath, '[^\\/]$', '&\\', '' )
	"
	let s:Git_Executable     = s:Git_BinPath.'git.exe'     " Git executable
	let s:Git_GitKExecutable = s:Git_BinPath.'tclsh.exe'   " GitK executable
	let s:Git_GitKScript     = s:Git_BinPath.'gitk'        " GitK script
else
	let s:Git_BinPath = substitute ( s:Git_BinPath, '[^\\/]$', '&/', '' )
	"
	let s:Git_Executable     = s:Git_BinPath.'git'         " Git executable
	let s:Git_GitKExecutable = s:Git_BinPath.'gitk'        " GitK executable
	let s:Git_GitKScript     = ''                          " GitK script (do not specify separate script by default)
endif
"
call s:GetGlobalSetting ( 'Git_Executable' )
call s:GetGlobalSetting ( 'Git_GitKExecutable' )
call s:GetGlobalSetting ( 'Git_GitKScript' )
call s:GetGlobalSetting ( 'Git_LoadMenus' )
call s:GetGlobalSetting ( 'Git_RootMenu' )
call s:GetGlobalSetting ( 'Git_CustomMenu' )

let s:Enabled         = 1           " Git enabled?
let s:DisabledMessage = "Git-Support not working:"
let s:DisabledReason  = ""
"
let s:EnabledGitK        = 1        " gitk enabled?
let s:DisableGitKMessage = "gitk not avaiable:"
let s:DisableGitKReason  = ""
"
let s:EnabledGitBash        = 1     " git bash enabled?
let s:DisableGitBashMessage = "git bash not avaiable:"
let s:DisableGitBashReason  = ""

" :TODO:25.09.2017 19:06:WM: enable Windows, check how to start jobs with arguments under Windows
let s:EnabledGitTerm = has ( 'terminal' ) && ! s:MSWIN || has ( 'nvim' )

let s:FoundGitKScript  = 1
let s:GitKScriptReason = ""
"
let s:GitVersion    = ""            " Git Version
"
" git bash
if s:MSWIN
	let s:Git_GitBashExecutable = s:Git_BinPath.'sh.exe'
	call s:GetGlobalSetting ( 'Git_GitBashExecutable' )
else
	if exists ( 'g:Xterm_Executable' )
		let s:Git_GitBashExecutable = g:Xterm_Executable
	else
		let s:Git_GitBashExecutable = 'xterm'
	endif
	call s:GetGlobalSetting ( 'Git_GitBashExecutable' )
	call s:ApplyDefaultSetting ( 'Xterm_Options', '-fa courier -fs 12 -geometry 80x24' )
endif
"
" check git executable   {{{2
"
function! s:CheckExecutable ( name, exe )
	"
	let executable = a:exe
	let enabled = 1
	let reason  = ""
	"
	if executable =~ '^LANG=\S\+\s\+\S'
		let [ lang, executable ] = matchlist ( executable, '^\(LANG=\S\+\)\s\+\(.\+\)$' )[1:2]
		if ! executable ( executable )
			let enabled = 0
			let reason = a:name." not executable: ".executable
		endif
		let executable = lang.' '.shellescape( executable )
	elseif executable =~ '^\(["'']\)\zs.\+\ze\1'
		if ! executable ( matchstr ( executable, '^\(["'']\)\zs.\+\ze\1' ) )
			let enabled = 0
			let reason = a:name." not executable: ".executable
		endif
	else
		if ! executable ( executable )
			let enabled = 0
			let reason = a:name." not executable: ".executable
		endif
		let executable = shellescape( executable )
	endif
	"
	return [ executable, enabled, reason ]
endfunction    " ----------  end of function s:CheckExecutable  ----------
"
function! s:CheckFile ( shortname, filename, esc )
	"
	let filename = a:filename
	let found    = 1
	let message  = ""
	"
	if ! filereadable ( filename )
		let found = 0
		let message = a:shortname." not found: ".filename
	endif
	let filename = shellescape( filename )
	"
	return [ filename, found, message ]
endfunction    " ----------  end of function s:CheckFile  ----------
"
let [ s:Git_Executable,     s:Enabled,     s:DisabledReason    ] = s:CheckExecutable( 'git',  s:Git_Executable )
let [ s:Git_GitKExecutable, s:EnabledGitK, s:DisableGitKReason ] = s:CheckExecutable( 'gitk', s:Git_GitKExecutable )
if ! empty ( s:Git_GitKScript )
	let [ s:Git_GitKScript, s:FoundGitKScript, s:GitKScriptReason ] = s:CheckFile( 'gitk script', s:Git_GitKScript, 1 )
endif
let [ s:Git_GitBashExecutable, s:EnabledGitBash, s:DisableGitBashReason ] = s:CheckExecutable ( 'git bash', s:Git_GitBashExecutable )
"
" check Git version   {{{2

" added in 1.7.2:
" - "git status --ignored"
" - "git status -s -b"
let s:HasStatusIgnore = 1
let s:HasStatusBranch = 1

" changed in 1.8.0:
" - "git branch --set-upstream" is deprecated,
"   use "git branch --set-upstream-to="
let s:HasBranchSetUpstreamTo = 1

" changed in 1.8.5:
" - output of "git status" without leading "#" char.
let s:HasStatus185Format = 1

if s:Enabled
	let s:GitVersion = s:StandardRun( '', ' --version', 't' )[1]
	if s:GitVersion =~? 'git version [0-9.]\+'
		let s:GitVersion = matchstr( s:GitVersion, 'git version \zs[0-9.]\+' )

		if s:VersionLess ( s:GitVersion, '1.7.2' )
			let s:HasStatusIgnore = 0
			let s:HasStatusBranch = 0
		endif

		if s:VersionLess ( s:GitVersion, '1.8.0' )
			let s:HasBranchSetUpstreamTo = 0
		endif

		if s:VersionLess ( s:GitVersion, '1.8.5' )
			let s:HasStatus185Format = 0
		endif

	else
		call s:ErrorMsg ( 'Can not obtain the version number of Git.' )
	endif
endif

" standard help text   {{{2
"
let s:HelpTxtStd  = "S-F1    : help\n"
let s:HelpTxtStd .= "q       : close\n"
let s:HelpTxtStd .= "u       : update"
"
let s:HelpTxtStdNoUpdate  = "S-F1    : help\n"
let s:HelpTxtStdNoUpdate .= "q       : close"

" custom commands   {{{2

if s:Enabled
  command! -nargs=* -complete=file            GitAdd             :call gitsupport#commands#AddFromCmdLine(<q-args>)
  command! -nargs=* -complete=file -range=-1  GitBlame           :call gitsupport#cmd_blame#FromCmdLine(<q-args>,<line1>,<line2>,<count>)
  command! -nargs=* -complete=file            GitBranch          :call gitsupport#cmd_branch#FromCmdLine(<q-args>)
  command! -nargs=* -complete=file            GitCheckout        :call gitsupport#commands#CheckoutFromCmdLine(<q-args>)
  command! -nargs=* -complete=file            GitCommit          :call gitsupport#cmd_commit#FromCmdLine('direct',<q-args>)
  command! -nargs=? -complete=file            GitCommitFile      :call gitsupport#cmd_commit#FromCmdLine('file',<q-args>)
  command! -nargs=0                           GitCommitMerge     :call gitsupport#cmd_commit#FromCmdLine('merge','')
  command! -nargs=+                           GitCommitMsg       :call gitsupport#cmd_commit#FromCmdLine('msg',<q-args>)
  command! -nargs=* -complete=file            GitDiff            :call gitsupport#cmd_diff#FromCmdLine(<q-args>)
  command! -nargs=*                           GitFetch           :call gitsupport#commands#FromCmdLine('direct','fetch '.<q-args>)
  command! -nargs=+ -complete=file            GitGrep            :call gitsupport#cmd_grep#FromCmdLine('cwd',<q-args>)
  command! -nargs=+ -complete=file            GitGrepTop         :call gitsupport#cmd_grep#FromCmdLine('top',<q-args>)
  command! -nargs=* -complete=file -range=-1  GitLog             :call gitsupport#cmd_log#FromCmdLine(<q-args>,<line1>,<line2>,<count>)
  command! -nargs=*                           GitMerge           :call gitsupport#commands#FromCmdLine('direct','merge '.<q-args>)
  command! -nargs=* -complete=file            GitMv              :call gitsupport#commands#FromCmdLine('direct','mv '.<q-args>)
  command! -nargs=*                           GitPull            :call gitsupport#commands#FromCmdLine('direct','pull '.<q-args>)
  command! -nargs=*                           GitPush            :call gitsupport#commands#FromCmdLine('direct','push '.<q-args>)
  command! -nargs=* -complete=file            GitRemote          :call gitsupport#cmd_remote#FromCmdLine(<q-args>)
  command! -nargs=* -complete=file            GitReset           :call gitsupport#commands#ResetFromCmdLine(<q-args>)
  command! -nargs=* -complete=file            GitRm              :call gitsupport#commands#RmFromCmdLine(<q-args>)
  command! -nargs=* -complete=file            GitShow            :call gitsupport#cmd_show#FromCmdLine(<q-args>)
  command! -nargs=*                           GitStash           :call gitsupport#cmd_stash#FromCmdLine(<q-args>)
  command! -nargs=*                           GitSlist           :call gitsupport#cmd_stash#FromCmdLine('list '.<q-args>)
  command! -nargs=? -complete=file            GitStatus          :call gitsupport#cmd_status#FromCmdLine(<q-args>)
  command! -nargs=*                           GitTag             :call gitsupport#cmd_tag#FromCmdLine(<q-args>)

  command! -nargs=* -complete=file            GitTerm            :call gitsupport#cmd_term#FromCmdLine(<q-args>)

  command! -nargs=1 -complete=customlist,gitsupport#cmd_edit#Complete     GitEdit             :call gitsupport#cmd_edit#EditFile(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#cmd_help#Complete     GitHelp             :call gitsupport#cmd_help#ShowHelp(<q-args>)
endif

if s:Enabled && s:Git_NextGen
	command  -nargs=* -complete=file -bang      Git       :call gitsupport#commands#FromCmdLine('<bang>'=='!'?'buffer':'direct',<q-args>)
	command! -nargs=* -complete=file            GitRun    :call gitsupport#commands#FromCmdLine('direct',<q-args>)
	command! -nargs=* -complete=file            GitBuf    :call gitsupport#commands#FromCmdLine('buffer',<q-args>)
endif

if s:Enabled && ! s:Git_NextGen
	command  -nargs=* -complete=file -bang                           Git                :call GitS_Run(<q-args>,'<bang>'=='!'?'b':'')
	command! -nargs=* -complete=file                                 GitRun             :call GitS_Run(<q-args>,'')
	command! -nargs=* -complete=file                                 GitBuf             :call GitS_Run(<q-args>,'b')
endif

if s:Enabled
	command! -nargs=* -complete=file                                 GitK               :call <SID>GitK(<q-args>)
	command! -nargs=* -complete=file                                 GitBash            :call <SID>GitBash(<q-args>)
	command! -nargs=0                                                GitSupportHelp     :call <SID>PluginHelp("gitsupport")
	command! -nargs=?                -bang                           GitSupportSettings :call <SID>PluginSettings(('<bang>'=='!')+str2nr(<q-args>))
else
  command  -nargs=* -bang  Git      :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitRun   :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitBuf   :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitHelp  :call gitsupport#config#PrintGitDisabled()
	command! -nargs=0                                                GitSupportHelp     :call <SID>PluginHelp("gitsupport")
	command! -nargs=?                -bang                           GitSupportSettings :call <SID>PluginSettings(('<bang>'=='!')+str2nr(<q-args>))
endif
"
" syntax highlighting   {{{2

function! s:HighlightingDefaults ()
	highlight default link GitComment     Comment
	highlight default      GitHeading     term=bold       cterm=bold       gui=bold
	highlight default link GitHighlight1  Identifier
	highlight default link GitHighlight2  PreProc
	highlight default      GitHighlight3  term=underline  cterm=underline  gui=underline
	highlight default link GitWarning     WarningMsg
	highlight default link GitSevere      ErrorMsg

	highlight default link GitAdd         DiffAdd
	highlight default link GitRemove      DiffDelete
	highlight default link GitConflict    DiffText
endfunction    " ----------  end of function s:HighlightingDefaults  ----------

augroup GitSupport
	autocmd VimEnter,ColorScheme * call s:HighlightingDefaults()
augroup END

" }}}2
"-------------------------------------------------------------------------------
"
"-------------------------------------------------------------------------------
" s:OpenGitBuffer : Put output in a read-only buffer.   {{{1
"
" Parameters:
"   buf_name - name of the buffer (string)
" Returns:
"   opened -  true, if a new buffer was opened (integer)
"
" If a buffer called 'buf_name' already exists, jump to that buffer. Otherwise,
" open a buffer of the given name an set it up as a "temporary" buffer. It is
" deleted after the window is closed.
"
" Settings:
" - noswapfile
" - bufhidden=wipe
" - tabstop=8
" - foldmethod=syntax
"-------------------------------------------------------------------------------
"
function! s:OpenGitBuffer ( buf_name )

	" a buffer like this already opened on the current tab page?
	if bufwinnr ( a:buf_name ) != -1
		" yes -> go to the window containing the buffer
		exe bufwinnr( a:buf_name ).'wincmd w'
		return 0
	endif

	" no -> open a new window
	aboveleft new

	" buffer exists elsewhere?
	if bufnr ( a:buf_name ) != -1
		" yes -> settings of the new buffer
		silent exe 'edit #'.bufnr( a:buf_name )
		return 0
	else
		" no -> settings of the new buffer
		silent exe 'file '.escape( a:buf_name, ' ' )
		setlocal noswapfile
		setlocal bufhidden=wipe
		setlocal tabstop=8
		setlocal foldmethod=syntax
	endif

	return 1
endfunction    " ----------  end of function s:OpenGitBuffer  ----------
"
"-------------------------------------------------------------------------------
" s:UpdateGitBuffer : Put output in a read-only buffer.   {{{1
"
" Parameters:
"   command - the command to run (string)
"   stay    - if true, return to the old position in the buffer
"             (integer, default: 0)
" Returns:
"   success - true, if the command was run successfully (integer)
"
" The output of the command is used to replace the text in the current buffer.
" If 'stay' is true, return to the same line the cursor was placed in before
" the update. After updating, 'modified' is cleared.
"-------------------------------------------------------------------------------
"
function! s:UpdateGitBuffer ( command, ... )
	"
	if a:0 == 1 && a:1
		" return to old position
		let pos_window = line('.') - winline() + 1
		let pos_cursor = line('.')
	else
		let pos_window = 1
		let pos_cursor = 1
	endif
	"
	" delete the previous contents
	setlocal modifiable
	setlocal noro
	silent exe '1,$delete _'
	"
	" pause syntax highlighting (for speed)
	if &syntax != ''
		setlocal syntax=OFF
	endif
	"
	" insert the output of the command
	silent exe 'r! '.a:command
	"
	" delete the first line (empty) and go to position
	normal! gg"_dd
	silent exe 'normal! '.pos_window.'zt'
	silent exe ':'.pos_cursor
	"
	" restart syntax highlighting
	if &syntax != ''
		setlocal syntax=ON
	endif
	"
	" open all folds (closed by the syntax highlighting)
	normal! zR
	"
	" read-only again
	setlocal ro
	setlocal nomodified
	setlocal nomodifiable
	"
	return v:shell_error == 0
endfunction    " ----------  end of function s:UpdateGitBuffer  ----------
"
"-------------------------------------------------------------------------------
" GitS_FoldLog : fold text for 'git diff/log/show/status'   {{{1
"
" :WARNING:18.12.2020 12:19:WM: currently used by next gen modules,
"   waiting for further refactoring
"-------------------------------------------------------------------------------
"
function! GitS_FoldLog ()
	let line = getline( v:foldstart )
	let head = '+-'.v:folddashes.' '
	let tail = ' ('.( v:foldend - v:foldstart + 1 ).' lines) '
	"
	if line =~ '^tag'
		" search for the first line which starts with a space,
		" this is the first line of the commit message
		return head.'tag - '.substitute( line, '^tag\s\+', '', '' ).tail
	elseif line =~ '^commit'
		" search for the first line which starts with a space,
		" this is the first line of the commit message
		let pos = v:foldstart
		while pos <= v:foldend
			if getline(pos) =~ '^\s\+\S'
				break
			endif
			let pos += 1
		endwhile
		if pos > v:foldend | let pos = v:foldstart | endif
		return head.'commit - '.substitute( getline(pos), '^\s\+', '', '' ).tail
	elseif line =~ '^diff'
	  " take the filename from (we also consider backslashes):
		"   diff --git a/<file> b/<file>
		let file = matchstr ( line, 'a\([/\\]\)\zs\(.*\)\ze b\1\2\s*$' )
		if file != ''
			return head.'diff - '.file.tail
		else
			return head.line.tail
		endif
	elseif ! s:HasStatus185Format && line =~ '^#\s\a.*:$'
				\ || s:HasStatus185Format && line =~ '^\a.*:$'
		" we assume a line in the status comment block and try to guess the number of lines (=files)
		" :TODO:20.03.2013 19:30:WM: (might be something else)
		"
		let prefix = s:HasStatus185Format ? '' : '#'
		"
		let filesstart = v:foldstart+1
		let filesend   = v:foldend
		while filesstart < v:foldend && getline(filesstart) =~ '\_^'.prefix.'\s*\_$\|\_^'.prefix.'\s\+('
			let filesstart += 1
		endwhile
		while filesend > v:foldstart && getline(filesend) =~ '^'.prefix.'\s*$'
			let filesend -= 1
		endwhile
		return line.' '.( filesend - filesstart + 1 ).' files '
	else
		return head.line.tail
	endif
endfunction    " ----------  end of function GitS_FoldLog  ----------

"-------------------------------------------------------------------------------
" GitS_Run : execute 'git ...'   {{{1
"
" Flags: -> s:StandardRun
"-------------------------------------------------------------------------------
"
function! GitS_Run( param, flags )
	"
	if a:flags =~ 'b'
		call GitS_RunBuf ( 'update', a:param )
	else
		return s:StandardRun ( '', a:param, a:flags, 'bc' )
	endif
	"
endfunction    " ----------  end of function GitS_Run  ----------
"
"-------------------------------------------------------------------------------
" GitS_RunBuf : execute 'git ...'   {{{1
"-------------------------------------------------------------------------------
"
function! GitS_RunBuf( action, ... )
	"
	if a:action == 'help'
		echo s:HelpTxtStd
		return
	elseif a:action == 'quit'
		close
		return
	elseif a:action == 'update'
		"
		if a:1 =~ '^!'
			let subcmd = matchstr ( a:1, '[a-z][a-z\-]*' )
		else
			let param  = a:1
			let subcmd = matchstr ( a:1, '[a-z][a-z\-]*' )
		endif
		"
	else
		echoerr 'Unknown action "'.a:action.'".'
		return
	endif
	"
	let buf = s:CheckCWD ()
	"
	if s:OpenGitBuffer ( 'Git - git '.subcmd )
		"
		let b:GitSupport_RunBufFlag = 1
		"
		exe 'nnoremap          <buffer> <S-F1> :call GitS_RunBuf("help")<CR>'
		exe 'nnoremap <silent> <buffer> q      :call GitS_RunBuf("quit")<CR>'
		exe 'nnoremap <silent> <buffer> u      :call GitS_RunBuf("update","!'.subcmd.'")<CR>'
	endif
	"
	call s:ChangeCWD ( buf )
	"
	if ! exists ( 'param' )
		let param = b:GitSupport_Param
	else
		let b:GitSupport_Param = param
	endif
	"
	let cmd = s:Git_Executable.' '.param
	"
	call s:UpdateGitBuffer ( cmd )
	"
endfunction    " ----------  end of function GitS_RunBuf  ----------
"
"-------------------------------------------------------------------------------
" s:GitK : execute 'gitk ...'   {{{1
"-------------------------------------------------------------------------------

function! s:GitK( param )

	" :TODO:10.12.2013 20:14:WM: graphics available?
	if s:EnabledGitK == 0
		return s:ErrorMsg ( s:DisableGitKMessage, s:DisableGitKReason )
	elseif s:FoundGitKScript == 0
		return s:ErrorMsg ( s:DisableGitKMessage, s:GitKScriptReason )
	endif

	let param = escape( a:param, '%#' )

	if s:NEOVIM
		call jobstart ( s:Git_GitKExecutable.' '.s:Git_GitKScript.' '.param, { 'detach' : 1 } )
	elseif s:MSWIN
		" :TODO:02.01.2014 13:00:WM: Windows: try the shell command 'start'
		silent exe '!start '.s:Git_GitKExecutable.' '.s:Git_GitKScript.' '.param
	else
		silent exe '!'.s:Git_GitKExecutable.' '.s:Git_GitKScript.' '.param.' &'
	endif

endfunction    " ----------  end of function s:GitK  ----------

"-------------------------------------------------------------------------------
" s:GitBash : execute 'xterm git ...' or "git bash"   {{{1
"-------------------------------------------------------------------------------

function! s:GitBash( param )

	" :TODO:10.12.2013 20:14:WM: graphics available?
	if s:EnabledGitBash == 0
		return s:ErrorMsg ( s:DisableGitBashMessage, s:DisableGitBashReason )
	endif

	let title = 'git '.matchstr( a:param, '\S\+' )
	let param = escape( a:param, '%#' )

	if s:MSWIN && param =~ '^\s*$'
		" no parameters: start interactive mode in background
		silent exe '!start '.s:Git_GitBashExecutable.' --login -i'
	elseif s:MSWIN
		" otherwise: block editor and execute command
		silent exe '!'.s:Git_GitBashExecutable.' --login -c '.shellescape ( 'git '.param )
	else
		" UNIX: execute command in background, wait for confirmation afterwards
		if s:Git_GitBashExecutable =~ '\cxterm'
			let title = ' -title '.shellescape( title )
		else
			let title = ''
		endif

		if s:NEOVIM
			let job_id = jobstart ( s:Git_GitBashExecutable.' '.g:Xterm_Options.title
						\ .' -e '.shellescape( s:Git_Executable.' '.param.' ; echo "" ; read -p "  ** PRESS ENTER **  " dummy ' ),
						\ { 'detach' : 1 } )
		else
			silent exe '!' s:Git_GitBashExecutable g:Xterm_Options title
						\  '-e ' shellescape( s:Git_Executable.' '.param.' ; echo "" ; read -p "  ** PRESS ENTER **  " dummy ' ) '&'
		endif

		call s:Redraw ( 'r!', '' )                  " redraw in terminal
	endif

endfunction    " ----------  end of function s:GitBash  ----------

"-------------------------------------------------------------------------------
" s:PluginHelp : Plug-in help.   {{{1
"-------------------------------------------------------------------------------

function! s:PluginHelp( topic )
	try
		silent exe 'help '.a:topic
	catch
		exe 'helptags '.s:plugin_dir.'/doc'
		silent exe 'help '.a:topic
	endtry
endfunction    " ----------  end of function s:PluginHelp  ----------

"-------------------------------------------------------------------------------
" s:PluginSettings : Print the settings on the command line.   {{{1
"-------------------------------------------------------------------------------
"
function! s:PluginSettings( verbose )
	"
	if     s:MSWIN | let sys_name = 'Windows'
	elseif s:UNIX  | let sys_name = 'UNIX'
	else           | let sys_name = 'unknown' | endif
	if    s:NEOVIM | let vim_name = 'nvim'
	else           | let vim_name = has('gui_running') ? 'gvim' : 'vim' | endif

	if s:Enabled | let git_e_status = ' (version '.s:GitVersion.')'
	else         | let git_e_status = ' (not executable)'
	endif
	let gitk_e_status  = s:EnabledGitK     ? '' : ' (not executable)'
	let gitk_s_status  = s:FoundGitKScript ? '' : ' (not found)'
	let gitbash_status = s:EnabledGitBash  ? '' : ' (not executable)'
	"
	let file_options_status = filereadable ( s:Git_CmdLineOptionsFile ) ? '' : ' (not readable)'
	"
	let	txt = " Git-Support settings\n\n"
				\ .'     plug-in installation :  '.s:installation.' in '.vim_name.' on '.sys_name."\n"
				\ .'           git executable :  '.s:Git_Executable.git_e_status."\n"
				\ .'          gitk executable :  '.s:Git_GitKExecutable.gitk_e_status."\n"
	if ! empty ( s:Git_GitKScript )
		let txt .=
					\  '              gitk script :  '.s:Git_GitKScript.gitk_s_status."\n"
	endif
	let txt .=
				\  '      git bash executable :  '.s:Git_GitBashExecutable.gitbash_status."\n"
	if s:UNIX && a:verbose >= 1
		let txt .= '            xterm options :  "'.g:Xterm_Options."\"\n"
	endif
	if a:verbose >= 1
		let	txt .= "\n"
					\ .'             expand empty :  checkout: "'.g:Git_CheckoutExpandEmpty.'" ; diff: "'.g:Git_DiffExpandEmpty.'" ; reset: "'.g:Git_ResetExpandEmpty."\"\n"
					\ .'     open fold after jump :  "'.g:Git_OpenFoldAfterJump."\"\n"
					\ .'  status staged open diff :  "'.g:Git_StatusStagedOpenDiff."\"\n\n"
					\ .'    cmd-line options file :  '.s:Git_CmdLineOptionsFile.file_options_status."\n"
"					\ .'            commit editor :  "'.g:Git_Editor."\"\n"
	endif
	let txt .=
				\  "________________________________________________________________________________\n"
				\ ." Git-Support, Version ".g:GitSupport_Version." / Wolfgang Mehner / wolfgang-mehner@web.de\n\n"
	"
	if a:verbose == 2
		split GitSupport_Settings.txt
		put = txt
	else
		echo txt
	endif
endfunction    " ----------  end of function s:PluginSettings  ----------
"
"-------------------------------------------------------------------------------
" s:LoadCmdLineOptions : Load s:CmdLineOptions   {{{1
"-------------------------------------------------------------------------------
"
function! s:LoadCmdLineOptions ()
	"
	let s:CmdLineOptions = {}
	let current_list     = []
	"
	if ! filereadable ( s:Git_CmdLineOptionsFile )
		return
	endif
	"
	for line in readfile ( s:Git_CmdLineOptionsFile )
		let name = matchstr ( line, '^\s*\zs.*\S\ze\s*$' )
		"
		if line =~ '^\S'
			let current_list = []
			let s:CmdLineOptions[ name ] = current_list
		else
			call add ( current_list, name )
		endif
	endfor
endfunction    " ----------  end of function s:LoadCmdLineOptions  ----------
"
call s:LoadCmdLineOptions ()
"
"-------------------------------------------------------------------------------
" s:CmdLineComplete : Command line completion.   {{{1
"
" Parameters:
"   mode     - the mode (string)
"   backward - move backwards in the list of replacements (integer, optional);
"              move forward otherwise
" Returns:
"   cmd_line - the new command line (string)
"
" Mode is one of:
"   branch  command  remote  tag
"-------------------------------------------------------------------------------
function! s:CmdLineComplete ( mode, ... )
	"
	let forward = 1
	"
	if a:0 >= 1 && a:1 == 1
		let forward = 0
	endif
	"
	let cmdline = getcmdline()
	let cmdpos  = getcmdpos() - 1
	"
	let cmdline_tail = strpart ( cmdline, cmdpos )
	let cmdline_head = strpart ( cmdline, 0, cmdpos )

	" split at blanks
	let idx = match ( cmdline_head, '[^[:blank:]]*$' )

	" prefixed by --option=
	if a:mode != 'command' && -1 != match ( strpart ( cmdline_head, idx ), '^--[^=]\+=' )
		let idx2 = matchend ( strpart ( cmdline_head, idx ), '^--[^=]\+=' )
		if idx2 >= 0
			let idx += idx2
		endif
	endif

	" for a branch or tag, split at a "..", "...", or ":"
	if a:mode == 'branch' || a:mode == 'tag'
		let idx2 = matchend ( strpart ( cmdline_head, idx ), '\.\.\.\?\|:' )
		if idx2 >= 0
			let idx += idx2
		endif
	endif
	"
	let cmdline_pre = strpart ( cmdline_head, 0, idx )
	"
	" not a word, skip completion
	if idx < 0
		return cmdline_head.cmdline_tail
	endif
	"
	" s:vars initial if first time or changed cmdline
	if ! exists('b:GitSupport_NewCmdLine') || cmdline_head != b:GitSupport_NewCmdLine || a:mode != b:GitSupport_CurrentMode
		"
		let b:GitSupport_NewCmdLine  = ''
		let b:GitSupport_CurrentMode = a:mode
		"
		let b:GitSupport_WordPrefix = strpart ( cmdline_head, idx )
		let b:GitSupport_WordMatch  = escape ( b:GitSupport_WordPrefix, '\' )
		let b:GitSupport_WordList   = [ b:GitSupport_WordPrefix ]
		let b:GitSupport_WordIndex  = 0
		"
		if a:mode == 'branch'
			let [ suc, txt ] = s:StandardRun ( 'branch', '-a', 't' )
			"
			for part in split( txt, "\n" ) + [ 'HEAD', 'ORIG_HEAD', 'FETCH_HEAD', 'MERGE_HEAD' ]
				" remove leading whitespaces, "*" (current branch), and "remotes/"
				" remove trailing "-> ..." (as in "origin/HEAD -> origin/master")
				let branch = matchstr( part, '^[ *]*\%(remotes\/\)\?\zs.\{-}\ze\%(\s*->.*\)\?$' )
				if -1 != match( branch, '\V\^'.b:GitSupport_WordMatch )
					call add ( b:GitSupport_WordList, branch )
				endif
			endfor
		elseif a:mode == 'command'
			let suc      = 0                          " initialized variable 'suc' needed below
			let use_list = s:GitCommands
			let sub_cmd  = matchstr ( cmdline_pre,
						\       '\c\_^Git\%(!\|Run\|Buf\|Bash\|Term\)\?\s\+\zs[a-z\-]\+\ze\s'
						\ .'\|'.'\c\_^Git\zs[a-z]\+\ze\s' )
			"
			if sub_cmd != ''
				let sub_cmd = tolower ( sub_cmd )
				if has_key ( s:CmdLineOptions, sub_cmd )
					let use_list = get ( s:CmdLineOptions, sub_cmd, s:GitCommands )
				endif
			endif
				"
			for part in use_list
				if -1 != match( part, '\V\^'.b:GitSupport_WordMatch )
					call add ( b:GitSupport_WordList, part )
				endif
			endfor
		elseif a:mode == 'remote'
			let [ suc, txt ] = s:StandardRun ( 'remote', '', 't' )
			"
			for part in split( txt, "\n" )
				if -1 != match( part, '\V\^'.b:GitSupport_WordMatch )
					call add ( b:GitSupport_WordList, part )
				endif
			endfor
		elseif a:mode == 'tag'
			let [ suc, txt ] = s:StandardRun ( 'tag', '', 't' )
			"
			for part in split( txt, "\n" )
				if -1 != match( part, '\V\^'.b:GitSupport_WordMatch )
					call add ( b:GitSupport_WordList, part )
				endif
			endfor
		else
			return cmdline_head.cmdline_tail
		endif
		"
		if suc != 0
			return cmdline_head.cmdline_tail
		endif
		"
	endif
	"
	if forward
		let b:GitSupport_WordIndex = ( b:GitSupport_WordIndex + 1 ) % len( b:GitSupport_WordList )
	else
		let b:GitSupport_WordIndex = ( b:GitSupport_WordIndex - 1 + len( b:GitSupport_WordList ) ) % len( b:GitSupport_WordList )
	endif
	"
	let word = b:GitSupport_WordList[ b:GitSupport_WordIndex ]
	"
	" new cmdline
	let b:GitSupport_NewCmdLine = cmdline_pre.word
	"
	" overcome map silent
	" (silent map together with this trick seems to look prettier)
	call feedkeys(" \<bs>")
	"
	" set new cmdline cursor postion
	call setcmdpos ( len(b:GitSupport_NewCmdLine)+1 )
	"
	return b:GitSupport_NewCmdLine.cmdline_tail
	"
endfunction    " ----------  end of function s:CmdLineComplete  ----------
"
"-------------------------------------------------------------------------------
" s:InitMenus : Initialize menus.   {{{1
"-------------------------------------------------------------------------------
"
function! s:InitMenus()

	if ! has ( 'menu' )
		return
	endif

	let ahead = 'anoremenu '.s:Git_RootMenu.'.'

	exe ahead.'Git       :echo "This is a menu header!"<CR>'
	exe ahead.'-Sep00-   :'

	" Commands   {{{2
	let ahead = 'anoremenu '.s:Git_RootMenu.'.&git\ \.\.\..'
	let vhead = 'vnoremenu '.s:Git_RootMenu.'.&git\ \.\.\..'

	exe ahead.'Commands<TAB>Git :echo "This is a menu header!"<CR>'
	exe ahead.'-Sep00-          :'

	exe ahead.'&add<TAB>:GitAdd           :GitAdd<space>'
	exe ahead.'&blame<TAB>:GitBlame       :GitBlame<space>'
	exe vhead.'&blame<TAB>:GitBlame       :GitBlame<space>'
	exe ahead.'&branch<TAB>:GitBranch     :GitBranch<space>'
	exe ahead.'&checkout<TAB>:GitCheckout :GitCheckout<space>'
	exe ahead.'&commit<TAB>:GitCommit     :GitCommit<space>'
	exe ahead.'&diff<TAB>:GitDiff         :GitDiff<space>'
	exe ahead.'&fetch<TAB>:GitFetch       :GitFetch<space>'
	exe ahead.'&grep<TAB>:GitGrep         :GitGrep<space>'
	exe ahead.'&help<TAB>:GitHelp         :GitHelp<space>'
	exe ahead.'&log<TAB>:GitLog           :GitLog<space>'
	exe ahead.'&merge<TAB>:GitMerge       :GitMerge<space>'
	exe ahead.'&mv<TAB>:GitMv             :GitMv<space>'
	exe ahead.'&pull<TAB>:GitPull         :GitPull<space>'
	exe ahead.'&push<TAB>:GitPush         :GitPush<space>'
	exe ahead.'&remote<TAB>:GitRemote     :GitRemote<space>'
	exe ahead.'&rm<TAB>:GitRm             :GitRm<space>'
	exe ahead.'&reset<TAB>:GitReset       :GitReset<space>'
	exe ahead.'&show<TAB>:GitShow         :GitShow<space>'
	exe ahead.'&stash<TAB>:GitStash       :GitStash<space>'
	exe ahead.'&status<TAB>:GitStatus     :GitStatus<space>'
	exe ahead.'&tag<TAB>:GitTag           :GitTag<space>'

	exe ahead.'-Sep01-                      :'
	exe ahead.'run\ git&k<TAB>:GitK         :GitK<space>'
	exe ahead.'run\ git\ &bash<TAB>:GitBash :GitBash<space>'

	" Current File   {{{2
	let shead = 'anoremenu <silent> '.s:Git_RootMenu.'.&file.'
	let vhead = 'vnoremenu <silent> '.s:Git_RootMenu.'.&file.'

	exe shead.'Current\ File<TAB>Git :echo "This is a menu header!"<CR>'
	exe shead.'-Sep00-               :'

	exe shead.'&add<TAB>:GitAdd               :GitAdd -- %<CR>'
	exe shead.'&blame<TAB>:GitBlame           :GitBlame -- %<CR>'
	exe vhead.'&blame<TAB>:GitBlame           :GitBlame -- %<CR>'
	exe shead.'&checkout<TAB>:GitCheckout     :GitCheckout -- %<CR>'
	exe shead.'&diff<TAB>:GitDiff             :GitDiff -- %<CR>'
	exe shead.'&diff\ --cached<TAB>:GitDiff   :GitDiff --cached -- %<CR>'
	exe shead.'&log<TAB>:GitLog               :GitLog --stat -- %<CR>'
	exe shead.'r&m<TAB>:GitRm                 :GitRm -- %<CR>'
	exe shead.'&reset<TAB>:GitReset           :GitReset -q -- %<CR>'

	" Specials   {{{2
	let ahead = 'anoremenu          '.s:Git_RootMenu.'.s&pecials.'
	let shead = 'anoremenu <silent> '.s:Git_RootMenu.'.s&pecials.'

	exe ahead.'Specials<TAB>Git :echo "This is a menu header!"<CR>'
	exe ahead.'-Sep00-          :'

	exe ahead.'&commit,\ msg\ from\ file<TAB>:GitCommitFile   :GitCommitFile<space>'
	exe shead.'&commit,\ msg\ from\ merge<TAB>:GitCommitMerge :GitCommitMerge<CR>'
	exe ahead.'&commit,\ msg\ from\ cmdline<TAB>:GitCommitMsg :GitCommitMsg<space>'
	exe ahead.'-Sep01-          :'

	exe ahead.'&grep,\ use\ top-level\ dir<TAB>:GitGrepTop       :GitGrepTop<space>'
	exe shead.'&stash\ list<TAB>:GitSlist                        :GitSlist<CR>'

	" Custom Menu   {{{2
	if ! empty ( s:Git_CustomMenu )

		let ahead = 'anoremenu          '.s:Git_RootMenu.'.&custom.'
		let ahead = 'anoremenu <silent> '.s:Git_RootMenu.'.&custom.'

		exe ahead.'Custom<TAB>Git :echo "This is a menu header!"<CR>'
		exe ahead.'-Sep00-        :'

		call s:GenerateCustomMenu ( s:Git_RootMenu.'.custom', s:Git_CustomMenu )

		exe ahead.'-HelpSep-                                  :'
		exe ahead.'help\ (custom\ menu)<TAB>:GitSupportHelp   :call <SID>PluginHelp("gitsupport-menus")<CR>'

	endif

	" Edit   {{{2
	let ahead = 'anoremenu          '.s:Git_RootMenu.'.&edit.'
	let shead = 'anoremenu <silent> '.s:Git_RootMenu.'.&edit.'

	exe ahead.'Edit File<TAB>Git :echo "This is a menu header!"<CR>'
	exe ahead.'-Sep00-          :'

	for fileid in gitsupport#cmd_edit#Options()
		let filepretty = substitute ( fileid, '-', '\\ ', 'g' )
		exe shead.'&'.filepretty.'<TAB>:GitEdit   :GitEdit '.fileid.'<CR>'
	endfor

	" Help   {{{2
	let ahead = 'anoremenu          '.s:Git_RootMenu.'.help.'
	let shead = 'anoremenu <silent> '.s:Git_RootMenu.'.help.'

	exe ahead.'Help<TAB>Git :echo "This is a menu header!"<CR>'
	exe ahead.'-Sep00-      :'

	exe shead.'help\ (Git-Support)<TAB>:GitSupportHelp     :call <SID>PluginHelp("gitsupport")<CR>'
	exe shead.'plug-in\ settings<TAB>:GitSupportSettings   :call <SID>PluginSettings(0)<CR>'

	" Main Menu - open buffers   {{{2
	let ahead = 'anoremenu          '.s:Git_RootMenu.'.'
	let shead = 'anoremenu <silent> '.s:Git_RootMenu.'.'

	exe ahead.'-Sep01-                      :'

	exe ahead.'&run\ git<TAB>:Git           :Git<space>'
	exe shead.'&branch<TAB>:GitBranch       :GitBranch<CR>'
	exe ahead.'&help\ \.\.\.<TAB>:GitHelp   :GitHelp<space>'
	exe shead.'&log<TAB>:GitLog             :GitLog<CR>'
	exe shead.'&remote<TAB>:GitRemote       :GitRemote<CR>'
	exe shead.'&stash\ list<TAB>:GitSlist   :GitSlist<CR>'
	exe shead.'&status<TAB>:GitStatus       :GitStatus<CR>'
	exe shead.'&tag<TAB>:GitTag             :GitTag<CR>'
	" }}}2

endfunction    " ----------  end of function s:InitMenus  ----------
"
"-------------------------------------------------------------------------------
" s:ToolMenu : Add or remove tool menu entries.   {{{1
"-------------------------------------------------------------------------------
"
function! s:ToolMenu( action )
	"
	if ! has ( 'menu' )
		return
	endif
	"
	if a:action == 'setup'
		anoremenu <silent> 40.1000 &Tools.-SEP100- :
		anoremenu <silent> 40.1080 &Tools.Load\ Git\ Support   :call Git_AddMenus()<CR>
	elseif a:action == 'loading'
		aunmenu   <silent> &Tools.Load\ Git\ Support
		anoremenu <silent> 40.1080 &Tools.Unload\ Git\ Support :call Git_RemoveMenus()<CR>
	elseif a:action == 'unloading'
		aunmenu   <silent> &Tools.Unload\ Git\ Support
		anoremenu <silent> 40.1080 &Tools.Load\ Git\ Support   :call Git_AddMenus()<CR>
	endif
	"
endfunction    " ----------  end of function s:ToolMenu  ----------
"
"-------------------------------------------------------------------------------
" Git_AddMenus : Add menus.   {{{1
"-------------------------------------------------------------------------------
"
function! Git_AddMenus()
	if s:MenuVisible == 0
		" initialize if not existing
		call s:ToolMenu ( 'loading' )
		call s:InitMenus ()
		" the menu is now visible
		let s:MenuVisible = 1
	endif
endfunction    " ----------  end of function Git_AddMenus  ----------
"
"-------------------------------------------------------------------------------
" Git_RemoveMenus : Remove menus.   {{{1
"-------------------------------------------------------------------------------
"
function! Git_RemoveMenus()
	if s:MenuVisible == 1
		" destroy if visible
		call s:ToolMenu ( 'unloading' )
		if has ( 'menu' )
			exe 'aunmenu <silent> '.s:Git_RootMenu
		endif
		" the menu is now invisible
		let s:MenuVisible = 0
	endif
endfunction    " ----------  end of function Git_RemoveMenus  ----------
"
"-------------------------------------------------------------------------------
" Setup maps.   {{{1
"-------------------------------------------------------------------------------
"
let s:maps = [
			\ [ 'complete branch',  'g:Git_MapCompleteBranch',  '<C-\>e<SID>CmdLineComplete("branch")<CR>'  ],
			\ [ 'complete command', 'g:Git_MapCompleteCommand', '<C-\>e<SID>CmdLineComplete("command")<CR>' ],
			\ [ 'complete remote',  'g:Git_MapCompleteRemote',  '<C-\>e<SID>CmdLineComplete("remote")<CR>'  ],
			\ [ 'complete tag',     'g:Git_MapCompleteTag',     '<C-\>e<SID>CmdLineComplete("tag")<CR>'     ],
			\ ]
"
for [ name, map_var, cmd ] in s:maps
	if exists ( map_var )
		try
			silent exe 'cnoremap <silent> '.{map_var}.' '.cmd
		catch /.*/
			call s:ErrorMsg ( 'Error while creating the map "'.name.'", with lhs "'.{map_var}.'":', v:exception )
		finally
		endtry
	endif
endfor
"
"-------------------------------------------------------------------------------
" Setup menus.   {{{1
"-------------------------------------------------------------------------------
"
" tool menu entry
call s:ToolMenu ( 'setup' )
"
" load the menu right now?
if s:Git_LoadMenus == 'yes'
	call Git_AddMenus ()
endif
" }}}1
"-------------------------------------------------------------------------------
"
" =====================================================================================
"  vim: foldmethod=marker
