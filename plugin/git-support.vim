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

let s:Features = gitsupport#config#Features()

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
else
	let s:Git_BinPath = substitute ( s:Git_BinPath, '[^\\/]$', '&/', '' )
	"
	let s:Git_Executable     = s:Git_BinPath.'git'         " Git executable
endif
"
call s:GetGlobalSetting ( 'Git_Executable' )
call s:GetGlobalSetting ( 'Git_LoadMenus' )
call s:GetGlobalSetting ( 'Git_RootMenu' )
call s:GetGlobalSetting ( 'Git_CustomMenu' )

let s:Enabled         = 1           " Git enabled?
let s:DisabledMessage = "Git-Support not working:"
let s:DisabledReason  = ""

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
let [ s:Git_Executable,     s:Enabled,     s:DisabledReason    ] = s:CheckExecutable( 'git',  s:Git_Executable )

" custom commands   {{{2

if s:Features.is_executable_git
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

  command  -nargs=* -complete=file -bang      Git                :call gitsupport#commands#FromCmdLine('<bang>'=='!'?'buffer':'direct',<q-args>)
  command! -nargs=* -complete=file            GitRun             :call gitsupport#commands#FromCmdLine('direct',<q-args>)
  command! -nargs=* -complete=file            GitBuf             :call gitsupport#commands#FromCmdLine('buffer',<q-args>)
  command! -nargs=* -complete=file            GitK               :call gitsupport#cmd_gitk#FromCmdLine(<q-args>)
  command! -nargs=* -complete=file            GitTerm            :call gitsupport#cmd_term#FromCmdLine(<q-args>)

  command! -nargs=1 -complete=customlist,gitsupport#cmd_edit#Complete     GitEdit             :call gitsupport#cmd_edit#EditFile(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#cmd_help#Complete     GitHelp             :call gitsupport#cmd_help#ShowHelp(<q-args>)

  command! -nargs=? -bang  GitSupportSettings  :call gitsupport#config#PrintSettings(('<bang>'=='!')+str2nr(<q-args>))
  command! -nargs=0        GitSupportHelp      :call gitsupport#plugin#help("gitsupport")
endif

if s:MSWIN
  command! -nargs=* -complete=file            GitBash            :call gitsupport#cmd_gitbash#FromCmdLine(<q-args>)
endif

if ! s:Features.is_executable_git
  command  -nargs=* -bang  Git      :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitRun   :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitBuf   :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitHelp  :call gitsupport#config#PrintGitDisabled()

  command! -nargs=? -bang  GitSupportSettings  :call gitsupport#config#PrintSettings(('<bang>'=='!')+str2nr(<q-args>))
  command! -nargs=0        GitSupportHelp      :call gitsupport#plugin#help("gitsupport")
endif

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
	elseif line =~ '^\a.*:$'
		" we assume a line in the status comment block and try to guess the number of lines (=files)
		" :TODO:20.03.2013 19:30:WM: (might be something else)
		let filesstart = v:foldstart+1
		let filesend   = v:foldend
		while filesstart < v:foldend && getline(filesstart) =~ '\_^\s*\_$\|\_^\s\+('
			let filesstart += 1
		endwhile
		while filesend > v:foldstart && getline(filesend) =~ '^\s*$'
			let filesend -= 1
		endwhile
		return line.' '.( filesend - filesstart + 1 ).' files '
	else
		return head.line.tail
	endif
endfunction    " ----------  end of function GitS_FoldLog  ----------

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
		exe ahead.'help\ (custom\ menu)<TAB>:GitSupportHelp   :call gitsupport#plugin#help("gitsupport-menus")<CR>'

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

	exe shead.'help\ (Git-Support)<TAB>:GitSupportHelp     :call gitsupport#plugin#help("gitsupport")<CR>'
	exe shead.'plug-in\ settings<TAB>:GitSupportSettings   :call gitsupport#config#PrintSettings(0)<CR>'

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
