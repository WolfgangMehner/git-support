"-------------------------------------------------------------------------------
"
"          File:  menus.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  15.09.2021
"      Revision:  ---
"       License:  Copyright (c) 2021, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:MenuData = gitsupport#config#Menu()

if ! exists( 's:MenuVisible' )
  let s:MenuVisible = 0
endif

function! gitsupport#menus#Add ()
  if ! has( 'menu' )
    return
  endif

  if s:MenuData.load_menus && s:MenuVisible == 0
    call s:Init()
    let s:MenuVisible = 1
  endif
endfunction

function! gitsupport#menus#Remove ()
  if ! has( 'menu' )
    return
  endif

  if s:MenuVisible == 1
    exe 'aunmenu <silent> '.s:MenuData.root_menu_name
    let s:MenuVisible = 0
  endif
endfunction

function! s:Init ()
  let root_menu_name = s:MenuData.root_menu_name

  let ahead = 'anoremenu '.root_menu_name.'.'

  exe ahead.'Git       :echo "This is a menu header!"<CR>'
  exe ahead.'-Sep00-   :'

  " Commands
  let ahead = 'anoremenu '.root_menu_name.'.&git\ \.\.\..'
  let vhead = 'vnoremenu '.root_menu_name.'.&git\ \.\.\..'

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

  " Current File
  let shead = 'anoremenu <silent> '.root_menu_name.'.&file.'
  let vhead = 'vnoremenu <silent> '.root_menu_name.'.&file.'

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

  " Specials
  let ahead = 'anoremenu          '.root_menu_name.'.s&pecials.'
  let shead = 'anoremenu <silent> '.root_menu_name.'.s&pecials.'

  exe ahead.'Specials<TAB>Git :echo "This is a menu header!"<CR>'
  exe ahead.'-Sep00-          :'

  exe ahead.'&commit,\ msg\ from\ file<TAB>:GitCommitFile   :GitCommitFile<space>'
  exe shead.'&commit,\ msg\ from\ merge<TAB>:GitCommitMerge :GitCommitMerge<CR>'
  exe ahead.'&commit,\ msg\ from\ cmdline<TAB>:GitCommitMsg :GitCommitMsg<space>'
  exe ahead.'-Sep01-          :'

  exe ahead.'&grep,\ use\ top-level\ dir<TAB>:GitGrepTop       :GitGrepTop<space>'
  exe shead.'&stash\ list<TAB>:GitSlist                        :GitSlist<CR>'

  " Custom Menu
  if ! empty( s:MenuData.custom_menu )

    let ahead = 'anoremenu          '.root_menu_name.'.&custom.'
    let ahead = 'anoremenu <silent> '.root_menu_name.'.&custom.'

    exe ahead.'Custom<TAB>Git :echo "This is a menu header!"<CR>'
    exe ahead.'-Sep00-        :'

    call s:GenerateCustomMenu( root_menu_name.'.custom', s:MenuData.custom_menu )

    exe ahead.'-HelpSep-                                  :'
    exe ahead.'help\ (custom\ menu)<TAB>:GitSupportHelp   :call gitsupport#plugin#help("gitsupport-menus")<CR>'

  endif

  " Edit
  let ahead = 'anoremenu          '.root_menu_name.'.&edit.'
  let shead = 'anoremenu <silent> '.root_menu_name.'.&edit.'

  exe ahead.'Edit File<TAB>Git :echo "This is a menu header!"<CR>'
  exe ahead.'-Sep00-          :'

  for fileid in gitsupport#cmd_edit#Options()
    let filepretty = substitute( fileid, '-', '\\ ', 'g' )
    exe shead.'&'.filepretty.'<TAB>:GitEdit   :GitEdit '.fileid.'<CR>'
  endfor

  " Help
  let ahead = 'anoremenu          '.root_menu_name.'.help.'
  let shead = 'anoremenu <silent> '.root_menu_name.'.help.'

  exe ahead.'Help<TAB>Git :echo "This is a menu header!"<CR>'
  exe ahead.'-Sep00-      :'

  exe shead.'help\ (Git-Support)<TAB>:GitSupportHelp     :call gitsupport#plugin#help("gitsupport")<CR>'
  exe shead.'plug-in\ settings<TAB>:GitSupportSettings   :call gitsupport#config#PrintSettings(0)<CR>'

  " Main Menu - open buffers
  let ahead = 'anoremenu          '.root_menu_name.'.'
  let shead = 'anoremenu <silent> '.root_menu_name.'.'

  exe ahead.'-Sep01-                      :'

  exe ahead.'&run\ git<TAB>:Git           :Git<space>'
  exe shead.'&branch<TAB>:GitBranch       :GitBranch<CR>'
  exe ahead.'&help\ \.\.\.<TAB>:GitHelp   :GitHelp<space>'
  exe shead.'&log<TAB>:GitLog             :GitLog<CR>'
  exe shead.'&remote<TAB>:GitRemote       :GitRemote<CR>'
  exe shead.'&stash\ list<TAB>:GitSlist   :GitSlist<CR>'
  exe shead.'&status<TAB>:GitStatus       :GitStatus<CR>'
  exe shead.'&tag<TAB>:GitTag             :GitTag<CR>'

  return
endfunction

function! s:GenerateCustomMenu ( prefix, data )
  for [ entry_l, entry_r, cmd ] in a:data
    " escape special characters and assemble entry
    let entry_l = escape( entry_l, ' |\' )
    let entry_l = substitute( entry_l, '\.\.', '\\.', 'g' )
    let entry_r = escape( entry_r, ' .|\' )

    if entry_r == '' | let entry = a:prefix.'.'.entry_l
    else             | let entry = a:prefix.'.'.entry_l.'<TAB>'.entry_r
    endif

    if cmd == ''
      let cmd = ':'
    endif

    let silent = '<silent> '

    " prepare command
    if cmd =~ '<CURSOR>'
      let mlist = matchlist( cmd, '^\(.\+\)<CURSOR>\(.\{-}\)$' )
      let cmd = s:AssembleCmdLine( mlist[1], mlist[2], '<Left>' )
      let silent = ''
    elseif cmd =~ '<EXECUTE>$'
      let cmd = substitute( cmd, '<EXECUTE>$', '<CR>', '' )
    endif
    "
    let cmd = substitute( cmd, '<WORD>',   '<cword>', 'g' )
    let cmd = substitute( cmd, '<FILE>',   '<cfile>', 'g' )
    let cmd = substitute( cmd, '<BUFFER>', '%',       'g' )

    exe 'anoremenu '.silent.entry.'      '.cmd
    exe 'vnoremenu '.silent.entry.' <C-C>'.cmd
  endfor
endfunction

function! s:AssembleCmdLine ( part1, part2, ... )
  if a:0 == 0 || a:1 == ''
    let left = "\<Left>"
  else
    let left = a:1
  endif
  return a:part1.a:part2.repeat( left, s:UnicodeLen( a:part2 ) )
endfunction

function! s:UnicodeLen ( str )
  return len(split( a:str, '.\zs' ))
endfunction

