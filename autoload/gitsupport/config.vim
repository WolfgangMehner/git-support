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

function! s:CheckExecutable ( exec )
  if executable( a:exec )
    return [ 1, '' ]
  else
    return [ 0, 'not executable' ]
  endif
endfunction

function! s:CheckGitExecutable ( exec )
  if !executable( a:exec )
    return [ 0, 'not executable' ]
  endif

  let cmd = shellescape( a:exec ).' --version'
  let version_info = system( cmd )

	if v:shell_error != 0
    return [ 0, 'could not obtain the git version' ]
  end

	if version_info =~? 'git version [0-9.]\+'
		let s:GitVersion = matchstr( version_info, 'git version \zs[0-9.]\+' )
	else
    return [ 0, 'could not parse the git version' ]
	endif

  return [ 1, '' ]
endfunction

let s:MSWIN = has("win16") || has("win32")   || has("win64")     || has("win95")
let s:UNIX	= has("unix")  || has("macunix") || has("win32unix")
let s:NEOVIM = has("nvim")

if s:MSWIN
	" MS Windows
	let s:plugin_dir = substitute( expand('<sfile>:p:h:h:h'), '\\', '/', 'g' )

	let s:Git_BinPath = 'C:\Program Files\Git\bin\'
else
	" Linux/Unix
	let s:plugin_dir = expand('<sfile>:p:h:h:h')

	let s:Git_BinPath = ''
endif

let s:Git_CmdLineOptionsFile = s:plugin_dir.'/git-support/data/options.txt'

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

	let s:Git_GitBashExecutable = 'xterm'
endif

call s:ApplyDefaultSetting( 'Git_AddExpandEmpty',       'no' )
call s:ApplyDefaultSetting( 'Git_CheckoutExpandEmpty',  'no' )
call s:ApplyDefaultSetting( 'Git_DiffExpandEmpty',      'no' )
call s:ApplyDefaultSetting( 'Git_ResetExpandEmpty',     'no' )
call s:ApplyDefaultSetting( 'Git_OpenFoldAfterJump',    'yes' )
call s:ApplyDefaultSetting( 'Git_StatusStagedOpenDiff', 'cached' )
call s:ApplyDefaultSetting( 'Git_Editor',               '' )

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

let [ s:GitExec_Enabled, s:GitExec_Reason ] = s:CheckGitExecutable( s:Git_Executable )
let [ s:GitBash_Enabled, s:GitBash_Reason ] = s:CheckExecutable( s:Git_GitBashExecutable )
let [ s:GitTerm_Enabled, s:GitTerm_Reason ] = [ 1, '' ]
if s:MSWIN
  let s:GitTerm_Enabled = 0
  let s:GitTerm_Reason = 'not yet available under Windows'
elseif !s:NEOVIM && !has( 'terminal' )
  let s:GitTerm_Enabled = 0
  let s:GitTerm_Reason = '+terminal feature not available'
endif

function! gitsupport#config#GitExecutable ()
  return s:Git_Executable
endfunction

function! gitsupport#config#GitBashExecutable ()
  return s:Git_GitBashExecutable
endfunction

function! gitsupport#config#Env ()
	return copy( s:Git_Env )
endfunction

let s:Features = {
      \ 'running_nvim':  s:NEOVIM,
      \ 'running_mswin': s:MSWIN,
      \ 'running_unix':  s:UNIX,
      \
      \ 'is_executable_git':  s:GitExec_Enabled,
      \ 'is_executable_bash': s:GitBash_Enabled,
      \ 'is_avaiable_term':   s:GitTerm_Enabled,
      \
      \ 'vim_has_json_decode':  has('patch-7.4.1304'),
      \ 'vim_full_job_support': has('patch-8.0.0902'),
      \ }

function! gitsupport#config#Features ()
	return s:Features
endfunction

let s:Config_DefaultValues = {
      \ 'help.format'          : 'man',
      \ 'status.relativePaths' : 'true'
      \ }

function! gitsupport#config#GitConfig ( option, scope )
  if a:scope == '' || a:scope == 'local'
    let scope_arg = []
  elseif a:scope == 'global'
    let scope_arg = [ '--global' ]
  elseif a:scope == 'system'
    let scope_arg = [ '--system' ]
  else
    return s:ErrorMsg( 'unknown scope: '.a:scope )
  endif

  let [ ret_code, text ] = gitsupport#run#GitOutput( [ 'config', '--get' ] + scope_arg + [ a:option ] )

  " from the help:
  "   the section or key is invalid (ret=1)
  if ret_code == 1 || text == ''
    if has_key( s:Config_DefaultValues, a:option )
      return [ 0, s:Config_DefaultValues[ a:option ] ]
    endif
  endif

  return [ ret_code, text ]
endfunction

function! gitsupport#config#PrintGitDisabled ()
  return s:ImportantMsg( printf(
        \ "Git-Support not working:\nthe git executable \"%s\" is not working correctly\n(%s)", s:Git_Executable, s:GitExec_Reason ) )
endfunction

function! gitsupport#config#PrintSettings ( verbose )
  if     s:MSWIN | let sys_name = 'Windows'
  elseif s:UNIX  | let sys_name = 'UNIX'
  else           | let sys_name = 'unknown' | endif
  if    s:NEOVIM | let vim_name = 'nvim'
  else           | let vim_name = has('gui_running') ? 'gvim' : 'vim' | endif

  if s:GitExec_Enabled | let git_e_status = ' (version '.s:GitVersion.')'
  else                 | let git_e_status = ' ('.s:GitExec_Reason.')'
  endif
"  let gitk_e_status  = s:EnabledGitK     ? '' : ' (not executable)'
"  let gitk_s_status  = s:FoundGitKScript ? '' : ' (not found)'
  let gitbash_status = s:GitBash_Enabled  ? '' : ' ('.s:GitBash_Reason.')'
  let gitterm_status = s:GitTerm_Enabled  ? 'yes' : 'no (s:GitTerm_Reason)'

  let environment = ''
  for [ name, value ] in items( s:Git_Env )
		let environment .= name.'='.value.' '
  endfor
  let environment = environment[0:-2]

  let file_options_status = filereadable( s:Git_CmdLineOptionsFile ) ? '' : ' (not readable)'

  let txt = " Git-Support settings\n\n"
        \ .'     plug-in installation :  '.vim_name.' on '.sys_name."\n"
        \ .'           git executable :  '.s:Git_Executable.git_e_status."\n"
"        \ .'          gitk executable :  '.s:Git_GitKExecutable.gitk_e_status."\n"
"  if ! empty( s:Git_GitKScript )
"    let txt .= '              gitk script :  '.s:Git_GitKScript.gitk_s_status."\n"
"  endif
  let txt .= '      git bash executable :  '.s:Git_GitBashExecutable.gitbash_status."\n"
  let txt .= '         terminal support :  '.gitterm_status."\n"
  if a:verbose >= 1
    let txt .= '              environment :  '.environment."\n"
  endif
  if s:UNIX && a:verbose >= 1
    let txt .= '            xterm options :  "'.g:Xterm_Options."\"\n"
  endif
  if a:verbose >= 1
    let txt .= "\n"
          \ .'             expand empty :  add: "'.g:Git_AddExpandEmpty.'"  checkout: "'.g:Git_CheckoutExpandEmpty.'"  diff: "'.g:Git_DiffExpandEmpty.'"  reset: "'.g:Git_ResetExpandEmpty."\"\n"
          \ .'     open fold after jump :  "'.g:Git_OpenFoldAfterJump."\"\n"
          \ .'  status staged open diff :  "'.g:Git_StatusStagedOpenDiff."\"\n\n"
          \ .'    cmd-line options file :  '.s:Git_CmdLineOptionsFile.file_options_status."\n"
          \ .'            commit editor :  "'.g:Git_Editor."\"\n"
  endif
  if !s:NEOVIM && a:verbose >= 1
    let txt .= "\n"
          \ .'          Vim job support :  '.( s:Features.vim_full_job_support ? 'yes' : 'no' )."\n"
  endif
  let txt .=
        \  "________________________________________________________________________________\n"
        \ ." Git-Support, Version ".g:GitSupport_Version." / Wolfgang Mehner / wolfgang-mehner@web.de\n\n"

  if a:verbose == 2
    split GitSupport_Settings.txt
    put = txt
  else
    echo txt
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

function! s:ImportantMsg ( ... )
  echohl Search
  echo join( a:000, "\n" )
  echohl None
endfunction

