"-------------------------------------------------------------------------------
"
"          File:  cmd_branch.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  06.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#cmd_branch#FromCmdLine ( q_params )
  let args = gitsupport#common#ParseShellParseArgs( a:q_params )
  return gitsupport#cmd_branch#OpenBuffer( args )
endfunction

function! gitsupport#cmd_branch#OpenBuffer ( params )
  let params = a:params
  let cwd = gitsupport#services_cwd#Get()

  if empty( params )
    call gitsupport#run#OpenBuffer( 'Git - branch' )
    call s:Run( params, cwd )

    command! -nargs=0 -buffer  Help   :call <SID>Help()
    nnoremap          <buffer> <S-F1> :call <SID>Help()<CR>
    nnoremap <silent> <buffer> q      :call <SID>Quit()<CR>
    nnoremap <silent> <buffer> u      :call <SID>Update()<CR>

    nnoremap <expr>   <buffer> ch     <SID>Checkout()
    nnoremap <expr>   <buffer> cr     <SID>Create(0)
    nnoremap <expr>   <buffer> Ch     <SID>Create(1)
    nnoremap <expr>   <buffer> CH     <SID>Create(1)
    nnoremap <expr>   <buffer> de     <SID>Delete(0)
    nnoremap <expr>   <buffer> De     <SID>Delete(1)
    nnoremap <expr>   <buffer> DE     <SID>Delete(1)
    nnoremap <expr>   <buffer> me     <SID>Merge()
    nnoremap <expr>   <buffer> re     <SID>Rebase()
    nnoremap <expr>   <buffer> rn     <SID>Rename(0)
    nnoremap <expr>   <buffer> Rn     <SID>Rename(1)
    nnoremap <expr>   <buffer> RN     <SID>Rename(1)
    nnoremap <expr>   <buffer> su     <SID>SetUpstream(1)
    nnoremap <silent> <buffer> sh     :call <SID>Show()<CR>
    nnoremap <expr>   <buffer> rp     <SID>Remote('prune')
    nnoremap <expr>   <buffer> ru     <SID>Remote('update')

    let b:GitSupport_Param = params
    let b:GitSupport_CWD = cwd
  else
    return gitsupport#run#RunDirect( '', ['branch'] + params, 'env_std', 1, 'cwd', cwd )
  endif
endfunction

function! s:Help ()
  let text =
        \  "git branch\n\n"
        \ ."S-F1    : help\n"
        \ ."q       : close\n"
        \ ."u       : update\n"
        \ ."\n"
        \ ."branch under cursor ...\n"
        \ ."ch      : checkout\n"
        \ ."cr      : use as starting point for creating a new branch\n"
        \ ."Ch / CH : create new branch and check it out\n"
        \ ."de      : delete\n"
        \ ."De / DE : delete (force via -D)\n"
        \ ."me      : merge with current branch\n"
        \ ."re      : rebase\n"
        \ ."rn      : rename\n"
        \ ."Rn / RN : rename (force via -M)\n"
        \ ."su      : set as upstream from current branch\n"
        \ ."sh      : show the commit\n"
        \ ."\n"
        \ ."remote under cursor ...\n"
        \ ."rp      : prune the remote branches\n"
        \ ."ru      : update the remote\n"
  echo text
endfunction

function! s:Quit ()
  close
endfunction

function! s:Run ( params, cwd )
  call gitsupport#run#RunToBuffer( '', ['branch', '-avv'] + a:params, 'callback', function( 's:Wrap' ), 'cwd', a:cwd )
endfunction

function! s:Update ()
  call s:Run( b:GitSupport_Param, b:GitSupport_CWD )
endfunction

function! s:Wrap ()
  setlocal filetype=gitsbranch
endfunction

function! s:Checkout ()
  let [ branch_name, is_remote ] = s:GetBranch()
  return gitsupport#common#AssembleCmdLine( ':GitCheckout '.shellescape( branch_name ), '' )
endfunction

function! s:Create ( do_checkout )
  let [ branch_name, is_remote ] = s:GetBranch()
  let suggestion = s:GetNameSuggestion( branch_name, is_remote )
  if a:do_checkout 
    return gitsupport#common#AssembleCmdLine( ':GitCheckout -b '.suggestion, ' '.shellescape( branch_name ) )
  else
    return gitsupport#common#AssembleCmdLine( ':GitBranch '.suggestion, ' '.shellescape( branch_name ) )
  endif
endfunction

function! s:Delete ( do_force )
  let [ branch_name, is_remote ] = s:GetBranch()
  let flag  = is_remote  ? '-r' : '-'
  let flag .= a:do_force ? 'D'  : 'd'
  return gitsupport#common#AssembleCmdLine( ':GitBranch '.flag.' '.shellescape( branch_name ), '' )
endfunction

function! s:Merge ()
  let [ branch_name, is_remote ] = s:GetBranch()
  return gitsupport#common#AssembleCmdLine( ':GitMerge '.shellescape( branch_name ), '' )
endfunction

function! s:Rebase ()
  let [ branch_name, is_remote ] = s:GetBranch()
  return gitsupport#common#AssembleCmdLine( ':GitTerm rebase '.shellescape( branch_name ), '' )
endfunction

function! s:Rename ( do_force )
  let [ branch_name, is_remote ] = s:GetBranch()
  let flag = a:do_force ? '-M' : '-m'
  return gitsupport#common#AssembleCmdLine( ':GitBranch '.flag.' '.shellescape( branch_name ).' '.branch_name, '' )
endfunction

function! s:SetUpstream ( do_force )
  " get short name of current HEAD
  let branch_current = gitsupport#run#GitOutput( [ 'symbolic-ref', '-q', 'HEAD' ] )[1]
  let branch_current = gitsupport#run#GitOutput( [ 'for-each-ref', "--format='%(refname:short)'", branch_current ] )[1]

  let [ branch_name, is_remote ] = s:GetBranch()
  return gitsupport#common#AssembleCmdLine( ':GitBranch --set-upstream-to='.branch_name.' '.branch_current, '' )
endfunction

function! s:Show ()
  let [ branch_name, is_remote ] = s:GetBranch()

  if branch_name == ''
    return s:ErrorMsg( 'no branch under the cursor' )
  endif

  return gitsupport#cmd_show#OpenBuffer( [ branch_name ] )
endfunction

function! s:Remote ( mode )
  let [ branch_name, is_remote ] = s:GetBranch()

  if ! is_remote
    return s:ErrorMsg( 'no remote branch under the cursor' )
  endif

  let remote = s:GetRemoteName( branch_name, is_remote )
  if a:mode == 'prune'
    return gitsupport#common#AssembleCmdLine( ':GitRemote prune ', ' '.remote )
  elseif a:mode == 'update'
    return gitsupport#common#AssembleCmdLine( ':GitRemote update ', ' '.remote )
  endif
endfunction

function! s:GetBranch ()
  let line = getline('.')
  let mlist = matchlist( line, '^[[:space:]*]*\(remotes/\)\?\(\S\+\)' )

  if empty( mlist )
    return [ '', '' ]
  else
    let branch_name = mlist[2]
    let is_remote = ! empty( mlist[1] )
    return [ branch_name, is_remote ]
  endif
endfunction

function! s:GetNameSuggestion ( branch_name, is_remote )
  if a:is_remote
    return substitute( a:branch_name, '^[^/]\+/', '', '' )
  else
    return ''
  endif
endfunction

function! s:GetRemoteName ( branch_name, is_remote )
  if a:is_remote
    return substitute( a:branch_name, '/.*', '', '' )
  else
    return ''
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

