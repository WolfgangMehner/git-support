" Vim syntax file
" Language: git output : branch
" Maintainer: Wolfgang Mehner <wolfgang-mehner@web.de>
" Last Change: 23.12.2012

if exists("b:current_syntax")
	finish
endif

syn sync fromstart
syn case match

"-------------------------------------------------------------------------------
" Syntax
"-------------------------------------------------------------------------------

" top-level categories:
" - GitBranchCurrent

syn match  GitBranchCurrent  "^\*\s.\+$"

"-------------------------------------------------------------------------------
" Highlight
"-------------------------------------------------------------------------------

highlight default link GitBranchCurrent  GitHighlight1

let b:current_syntax = "gitsbranch"
