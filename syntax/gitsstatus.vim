" Vim syntax file
" Language: git output : status (uses: diff)
" Maintainer: Wolfgang Mehner <wolfgang-mehner@web.de>
" Last Change: 19.03.2013

if exists("b:current_syntax")
	finish
endif

" use 'GitDiffRegion' as a top-level category
runtime! syntax/gitsdiff.vim
unlet b:current_syntax

syn sync minlines=50
syn case match

"-------------------------------------------------------------------------------
" Syntax
"-------------------------------------------------------------------------------

" top-level categories:
" - GitStatusHashRegion
" - GitStatusBareRegion
" - GitStagedRegion
" - GitModifiedRegion
" - GitUntrackedRegion
" - GitIgnoredRegion
" - GitUntrackedRegion
" imported:
" - GitDiffRegion

syn region GitStatusHashRegion  start=/^#/ end=/^#\@!/ contains=GitStagedRegion,GitModifiedRegion,GitUntrackedRegion,GitIgnoredRegion,GitUnmergedRegion fold
syn region GitStatusBareRegion  start=/^[^#]\%1l/ end=/^\%(diff\)\@=/ contains=GitStatusTrackingLine,GitStagedRegion,GitModifiedRegion,GitUntrackedRegion,GitIgnoredRegion,GitUnmergedRegion fold

syn match  GitStatusTrackingLine     "^Tracking .*" contained contains=GitStatusTrackingCurrent,GitStatusTrackingDiverge
syn match  GitStatusTrackingDiverge  "\[\zs.\+\ze\]" contained
syn match  GitStatusTrackingCurrent  "\[\zsup-to-date\ze]" contained

syn region GitStagedRegion      start=/^# Changes to be committed:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeader,GitStatusComment,GitStagedFile  contained
syn region GitStagedRegion      start=/^Changes to be committed:/ end=/^\%(\w\)\@=/ contains=GitStatusHeader,GitStatusComment,GitStagedFile  contained
syn match  GitStagedFile        "^#\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained
syn match  GitStagedFile        "^\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained

syn region GitModifiedRegion    start=/^# Changes not staged for commit:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeader,GitStatusComment,GitModifiedFile  contained
syn region GitModifiedRegion    start=/^Changes not staged for commit:/ end=/^\%(\w\)\@=/ contains=GitStatusHeader,GitStatusComment,GitModifiedFile  contained
syn match  GitModifiedFile      "^#\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained
syn match  GitModifiedFile      "^\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained

syn region GitUntrackedRegion   start=/^# Untracked files:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeader,GitStatusComment,GitUntrackedFile  contained
syn region GitUntrackedRegion   start=/^Untracked files:/ end=/^\%(\w\)\@=/ contains=GitStatusHeader,GitStatusComment,GitUntrackedFile  contained
syn match  GitUntrackedFile     "^#\s\+\zs[^([:space:]].*$" contained
syn match  GitUntrackedFile     "^\s\+\zs[^([:space:]].*$" contained

syn region GitIgnoredRegion     start=/^# Ignored files:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeader,GitStatusComment,GitIgnoredFile  contained
syn region GitIgnoredRegion     start=/^Ignored files:/ end=/^\%(\w\)\@=/ contains=GitStatusHeader,GitStatusComment,GitIgnoredFile  contained
syn match  GitIgnoredFile       "^#\s\+\zs[^([:space:]].*$" contained
syn match  GitIgnoredFile       "^\s\+\zs[^([:space:]].*$" contained

syn region GitUnmergedRegion    start=/^# Unmerged paths:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeader,GitStatusComment,GitUnmergedFile  contained
syn region GitUnmergedRegion    start=/^Unmerged paths:/ end=/^\%(\w\)\@=/ contains=GitStatusHeader,GitStatusComment,GitUnmergedFile  contained
syn match  GitUnmergedFile      "^#\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained
syn match  GitUnmergedFile      "^\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained

syn match  GitStatusHeader      "^# \zs.\+:$"         contained
syn match  GitStatusHeader      "^[^#[:space:]].*:$"  contained
syn match  GitStatusComment     "^#\s\+\zs([^)]*)$"   contained
syn match  GitStatusComment     "^\s\+\zs([^)]*)$"    contained

"-------------------------------------------------------------------------------
" Highlight
"-------------------------------------------------------------------------------

highlight default link GitStatusTrackingDiverge  GitRemove

highlight default link GitStatusHeader    GitHeading
highlight default link GitStatusComment   GitComment
highlight default link GitStagedFile      GitAdd
highlight default link GitModifiedFile    GitRemove
highlight default link GitUntrackedFile   GitRemove
highlight default link GitIgnoredFile     GitRemove
highlight default link GitUnmergedFile    GitRemove

let b:current_syntax = "gitsstatus"
