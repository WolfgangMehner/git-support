" Vim syntax file
" Language: git output : status (uses: diff)
" Maintainer: Wolfgang Mehner <wolfgang-mehner@web.de>
" Last Change: 19.03.2013

if exists("b:current_syntax")
	finish
endif

syn sync fromstart
syn case match

"-------------------------------------------------------------------------------
" Syntax
"-------------------------------------------------------------------------------

" top-level categories:
" - GitStatusHashRegion
" containing status lines starting with a hash:
" - GitStagedRegion
" - GitModifiedRegion
" - GitUntrackedRegion
" - GitIgnoredRegion
" - GitUntrackedRegion
" imported:
" - GitDiffRegion

" use 'GitDiffRegion' as a top-level category
runtime! syntax/gitsdiff.vim
unlet b:current_syntax

syn region GitStatusHashRegion  start=/^#/ end=/\_^#\@!/ contains=GitStagedRegionH,GitModifiedRegionH,GitUntrackedRegionH,GitIgnoredRegionH,GitUnmergedRegionH fold

syn region GitStagedRegionH     start=/^# Changes to be committed:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeaderH,GitStatusCommentH,GitStagedFileH fold  contained
syn match  GitStagedFileH       "^#\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained

" the header for uncommitted changes changed somewhere along the way,
" the first alternative is the old version
syn region GitModifiedRegionH   start=/^# Changed but not updated:/       end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeaderH,GitStatusCommentH,GitModifiedFileH fold  contained
syn region GitModifiedRegionH   start=/^# Changes not staged for commit:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeaderH,GitStatusCommentH,GitModifiedFileH fold  contained
syn match  GitModifiedFileH     "^#\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained

syn region GitUntrackedRegionH  start=/^# Untracked files:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeaderH,GitStatusCommentH,GitUntrackedFileH fold  contained
syn match  GitUntrackedFileH    "^#\s\+\zs[^([:space:]].*$" contained

syn region GitIgnoredRegionH    start=/^# Ignored files:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeaderH,GitStatusCommentH,GitIgnoredFileH fold  contained
syn match  GitIgnoredFileH      "^#\s\+\zs[^([:space:]].*$" contained

syn region GitUnmergedRegionH   start=/^# Unmerged paths:/ end=/^\%(# \w\)\@=\|^#\@!/ contains=GitStatusHeaderH,GitStatusCommentH,GitUnmergedFileH fold  contained
syn match  GitUnmergedFileH     "^#\s\+\zs[[:alnum:][:space:]]\+:\s.\+" contained

syn match  GitStatusHeaderH     "^# \zs.\+:$"        contained
syn match  GitStatusCommentH    "^#\s\+\zs([^)]*)$"  contained

"-------------------------------------------------------------------------------
" Highlight
"-------------------------------------------------------------------------------

highlight default link GitStatusHeaderH   GitStatusHeader
highlight default link GitStatusCommentH  GitStatusComment
highlight default link GitStagedFileH     GitStagedFile
highlight default link GitModifiedFileH   GitModifiedFile
highlight default link GitUntrackedFileH  GitUntrackedFile
highlight default link GitIgnoredFileH    GitIgnoredFile
highlight default link GitUnmergedFileH   GitUnmergedFile

highlight default link GitStatusHeader   GitHeading
highlight default link GitStatusComment  GitComment
highlight default link GitStagedFile     GitAdd
highlight default link GitModifiedFile   GitRemove
highlight default link GitUntrackedFile  GitRemove
highlight default link GitIgnoredFile    GitRemove
highlight default link GitUnmergedFile   GitRemove

let b:current_syntax = "gitsstatus"
