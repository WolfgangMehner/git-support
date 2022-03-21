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
"      Revision:  14.09.2021
"       License:  Copyright (c) 2012-2021, Wolfgang Mehner
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
" Basic checks
"-------------------------------------------------------------------------------

" need at least 7.4
if v:version < 740
  echohl WarningMsg
  echo 'The plugin git-support.vim needs Vim version >= 7.4'
  echohl None
  finish
endif

" need compatible
if &cp
  finish
endif
let g:GitSupport_Version = '0.9.9-dev'     " version number of this script; do not change

"-------------------------------------------------------------------------------
" Modul setup
"-------------------------------------------------------------------------------

let s:Features = gitsupport#config#Features()

" custom commands

if s:Features.is_executable_git
  command! -nargs=* -complete=file                                                  GitAdd             :call gitsupport#commands#AddFromCmdLine(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete -range=-1  GitBlame           :call gitsupport#cmd_blame#FromCmdLine(<q-args>,<line1>,<line2>,<count>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitBranch          :call gitsupport#cmd_branch#FromCmdLine(<q-args>)
  command! -nargs=* -complete=file                                                  GitCheckout        :call gitsupport#commands#CheckoutFromCmdLine(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitCommit          :call gitsupport#cmd_commit#FromCmdLine('direct',<q-args>)
  command! -nargs=? -complete=file                                                  GitCommitFile      :call gitsupport#cmd_commit#FromCmdLine('file',<q-args>)
  command! -nargs=0                                                                 GitCommitMerge     :call gitsupport#cmd_commit#FromCmdLine('merge','')
  command! -nargs=+                                                                 GitCommitMsg       :call gitsupport#cmd_commit#FromCmdLine('msg',<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitDiff            :call gitsupport#cmd_diff#FromCmdLine(<q-args>)
  command! -nargs=*                                                                 GitFetch           :call gitsupport#commands#FromCmdLine('direct','fetch '.<q-args>)
  command! -nargs=+ -complete=file                                                  GitGrep            :call gitsupport#cmd_grep#FromCmdLine('cwd',<q-args>)
  command! -nargs=+ -complete=file                                                  GitGrepTop         :call gitsupport#cmd_grep#FromCmdLine('top',<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete -range=-1  GitLog             :call gitsupport#cmd_log#FromCmdLine(<q-args>,<line1>,<line2>,<count>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitMerge           :call gitsupport#commands#FromCmdLine('direct','merge '.<q-args>)
  command! -nargs=* -complete=file                                                  GitMv              :call gitsupport#commands#FromCmdLine('direct','mv '.<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitPull            :call gitsupport#commands#FromCmdLine('direct','pull '.<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitPush            :call gitsupport#commands#FromCmdLine('direct','push '.<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitRemote          :call gitsupport#cmd_remote#FromCmdLine(<q-args>)
  command! -nargs=* -complete=file                                                  GitReset           :call gitsupport#commands#ResetFromCmdLine(<q-args>)
  command! -nargs=* -complete=file                                                  GitRm              :call gitsupport#commands#RmFromCmdLine(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitShow            :call gitsupport#cmd_show#FromCmdLine(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitStash           :call gitsupport#cmd_stash#FromCmdLine(<q-args>)
  command! -nargs=*                                                                 GitSlist           :call gitsupport#cmd_stash#FromCmdLine('list '.<q-args>)
  command! -nargs=? -complete=customlist,gitsupport#commandline#Complete            GitStatus          :call gitsupport#cmd_status#FromCmdLine(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitTag             :call gitsupport#cmd_tag#FromCmdLine(<q-args>)

  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete -bang      Git                :call gitsupport#commands#FromCmdLine('<bang>'=='!'?'buffer':'direct',<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitRun             :call gitsupport#commands#FromCmdLine('direct',<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitBuf             :call gitsupport#commands#FromCmdLine('buffer',<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitK               :call gitsupport#cmd_gitk#FromCmdLine(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#commandline#Complete            GitTerm            :call gitsupport#cmd_term#FromCmdLine(<q-args>)

  command! -nargs=1 -complete=customlist,gitsupport#cmd_edit#Complete     GitEdit             :call gitsupport#cmd_edit#EditFile(<q-args>)
  command! -nargs=* -complete=customlist,gitsupport#cmd_help#Complete     GitHelp             :call gitsupport#cmd_help#ShowHelp(<q-args>,"<mods>")

  command! -nargs=? -bang  GitSupportSettings  :call gitsupport#config#PrintSettings(('<bang>'=='!')+str2nr(<q-args>))
  command! -nargs=0        GitSupportHelp      :call gitsupport#plugin#help("gitsupport")
endif

if s:Features.running_mswin
  command! -nargs=0  GitBash  :call gitsupport#cmd_gitbash#FromCmdLine()
endif

if ! s:Features.is_executable_git
  command  -nargs=* -bang  Git      :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitRun   :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitBuf   :call gitsupport#config#PrintGitDisabled()
  command! -nargs=*        GitHelp  :call gitsupport#config#PrintGitDisabled()

  command! -nargs=? -bang  GitSupportSettings  :call gitsupport#config#PrintSettings(('<bang>'=='!')+str2nr(<q-args>))
  command! -nargs=0        GitSupportHelp      :call gitsupport#plugin#help("gitsupport")
endif

" optional menus

call gitsupport#menus#Add()

" syntax highlighting

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
endfunction

augroup GitSupport
  autocmd VimEnter,ColorScheme * call s:HighlightingDefaults()
augroup END

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

" }}}1
"-------------------------------------------------------------------------------
