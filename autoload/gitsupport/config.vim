"-------------------------------------------------------------------------------
"
"          File:  config.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  26.11.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! s:ApplyDefaultSetting ( varname, value )
	if ! exists( 'g:'.a:varname )
		let {'g:'.a:varname} = a:value
	endif
endfunction

function! s:GetGlobalSetting ( varname, ... )
	let lname = a:varname
	let gname = a:0 >= 1 ? a:1 : lname
	if exists( 'g:'.gname )
		let {'s:'.lname} = {'g:'.gname}
	endif
endfunction

let s:MSWIN = has("win16") || has("win32")   || has("win64")     || has("win95")
let s:UNIX	= has("unix")  || has("macunix") || has("win32unix")
let s:NEOVIM = has("nvim")

if s:MSWIN
	" MS Windows
	let s:plugin_dir = substitute( expand('<sfile>:p:h:h'), '\\', '/', 'g' )

	let s:Git_BinPath = 'C:\Program Files\Git\bin\'
else
	" Linux/Unix
	let s:plugin_dir = expand('<sfile>:p:h:h')

	let s:Git_BinPath = ''
endif

call s:GetGlobalSetting ( 'Git_BinPath' )

if s:MSWIN
	let s:Git_BinPath = substitute ( s:Git_BinPath, '[^\\/]$', '&\\', '' )

	let s:Git_Executable        = s:Git_BinPath.'git.exe'     " Git executable
	let s:Git_GitKExecutable    = s:Git_BinPath.'tclsh.exe'   " GitK executable
	let s:Git_GitKScript        = s:Git_BinPath.'gitk'        " GitK script
	let s:Git_GitBashExecutable = s:Git_BinPath.'sh.exe'
else
	let s:Git_BinPath = substitute ( s:Git_BinPath, '[^\\/]$', '&/', '' )

	let s:Git_Executable     = s:Git_BinPath.'git'      " Git executable
	let s:Git_GitKExecutable = s:Git_BinPath.'gitk'     " GitK executable
	let s:Git_GitKScript     = ''                       " GitK script (do not specify separate script by default)

	let s:Git_GitBashExecutable = ''                    " do not use GitBash
endif

call s:ApplyDefaultSetting( 'Git_AddExpandEmpty',      'no' )
call s:ApplyDefaultSetting( 'Git_CheckoutExpandEmpty', 'no' )
call s:ApplyDefaultSetting( 'Git_DiffExpandEmpty',     'no' )
call s:ApplyDefaultSetting( 'Git_ResetExpandEmpty',    'no' )

let s:Git_Env = {}
	
call s:GetGlobalSetting ( 'Git_Executable' )
call s:GetGlobalSetting ( 'Git_GitKExecutable' )
call s:GetGlobalSetting ( 'Git_GitKScript' )
call s:GetGlobalSetting ( 'Git_GitBashExecutable' )
call s:GetGlobalSetting ( 'Git_Env.LANG', 'Git_Lang' )

if ! has_key( s:Git_Env, 'LANG' )
	if s:Git_Executable =~# '^LANG=\S\+\s\S'
		let [ s:Git_Env.LANG, s:Git_Executable ] = matchlist( s:Git_Executable, '^LANG=\(\S\+\)\s\+\(.\+\)' )[ 1:2 ]
	endif
endif

function! gitsupport#config#GitExecutable ()
	return s:Git_Executable
endfunction

function! gitsupport#config#Env ()
	return s:Git_Env
endfunction

