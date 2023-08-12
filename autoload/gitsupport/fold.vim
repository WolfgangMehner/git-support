"-------------------------------------------------------------------------------
"
"          File:  fold.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  12.08.2023
"      Revision:  ---
"       License:  Copyright (c) 2023, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function! gitsupport#fold#Init(buf_expr)
  let buf_nr = bufnr(a:buf_expr)
  call setbufvar(buf_nr, 'GitSupport_FoldData', {})
  call setbufvar(buf_nr, '&foldmethod', 'manual')
  call setbufvar(buf_nr, '&foldtext', '<SNR>'.s:SID().'_FoldText()')
endfunction

function! gitsupport#fold#AddFold(line_first, line_last, fold_text)
  let b:GitSupport_FoldData[a:line_first.'-'.a:line_last] = a:fold_text
  silent exec printf(':%d,%dfold', a:line_first, a:line_last)
endfunction

function! gitsupport#fold#SetLevel(buf_expr, foldlevel)
  let buf_nr = bufnr(a:buf_expr)
  call setbufvar(buf_nr, '&foldlevel', a:foldlevel)
endfunction

function! s:FoldText()
  let fold_id = v:foldstart.'-'.v:foldend
  let info = get(b:GitSupport_FoldData, fold_id, '')
  let head = '+-'.v:folddashes.' '

  if empty(info)
    let first_line = getline(v:foldstart)
    return head.first_line.' '
  else
    return head.info.' '
  endif
endfunction
