"-------------------------------------------------------------------------------
"
"          File:  cmd_log_folds.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  13.08.2023
"      Revision:  ---
"       License:  Copyright (c) 2023, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:use_log_fold_feature = 0

function! s:NewCommit(line_str, line_nr)
  let mlist = matchlist(a:line_str, 'commit \(\x\+\)')

  if len(mlist) >= 2
    let commit_hash = mlist[1]
  else
    let commit_hash = '-unknown-'
  endif

  return {
        \ 'line_start': a:line_nr,
        \ 'hash': commit_hash,
        \ 'first_line': '',
        \ 'diffs': []
        \ }
endfunction

function! s:AddCommitMessage(commit, line_str)
  let commit = a:commit
  if !empty(commit) && empty(commit.first_line)
    let commit.first_line = trim(a:line_str)
  endif
endfunction

function! s:FinishCommit(commit, line_nr)
  let commit = a:commit
  if !empty(commit)
    let msg = commit.first_line
    let info = 'commit '.commit.hash[0:7].' '.msg
    if !empty(commit.diffs)
      let info .= ' ('.len(commit.diffs).' files)'
    endif
    call gitsupport#fold#AddFold(commit.line_start, a:line_nr, info)
  endif
endfunction

function! s:NewDiff(line_str, line_nr)
  return {
        \ 'line_start': a:line_nr,
        \ 'chunks': []
        \ }
endfunction

function! s:FinishDiff(diff, line_nr, commit)
  let diff = a:diff
  let commit = a:commit
  if !empty(diff)
    call gitsupport#fold#AddFold(diff.line_start, a:line_nr, '')
    if !empty(commit)
      call add(commit.diffs, diff)
    endif
  endif
endfunction

function! s:NewChunk(line_str, line_nr)
  return {
        \ 'line_start': a:line_nr
        \ }
endfunction

function! s:FinishChunk(chunk, line_nr, diff)
  let chunk = a:chunk
  let diff = a:diff
  if !empty(chunk)
    call gitsupport#fold#AddFold(chunk.line_start, a:line_nr, '')
    if !empty(diff)
      call add(diff.chunks, chunk)
    endif
  endif
endfunction

function! gitsupport#cmd_log_folds#Add(buf_nr)
  if !s:use_log_fold_feature
    return
  endif

  let lines = getbufline(a:buf_nr, 1, '$')

  let current_commit = {}
  let current_diff = {}
  let current_chunk = {}

  for idx in range(len(lines))
    let line_str = lines[idx]
    let prefix = line_str[0:1]

    if prefix == 'co'   " commit
      call s:FinishChunk(current_chunk, idx, current_diff)
      call s:FinishDiff(current_diff, idx, current_commit)
      call s:FinishCommit(current_commit, idx)
      let current_commit = s:NewCommit(line_str, idx+1)
      let current_diff = {}
      let current_chunk = {}
    elseif prefix == 'di'   " diff
      call s:FinishChunk(current_chunk, idx, current_diff)
      call s:FinishDiff(current_diff, idx, current_commit)
      let current_diff = s:NewDiff(line_str, idx+1)
      let current_chunk = {}
    elseif prefix == '@@'   " diff chunk
      call s:FinishChunk(current_chunk, idx, current_diff)
      let current_chunk = s:NewChunk(line_str, idx+1)
    elseif prefix == '  '   " commit message?
      call s:AddCommitMessage(current_commit, line_str)
    endif
  endfor

  call s:FinishChunk(current_chunk, len(lines), current_diff)
  call s:FinishDiff(current_diff, len(lines), current_commit)
  call s:FinishCommit(current_commit, len(lines))
endfunction
