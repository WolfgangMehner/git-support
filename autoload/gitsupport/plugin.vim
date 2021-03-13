"-------------------------------------------------------------------------------
"
"          File:  plugin.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  13.03.2021
"      Revision:  ---
"       License:  Copyright (c) 2021, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:plugin_dir = gitsupport#config#PluginDir()

function! gitsupport#plugin#help ( topic )
  try
    silent exe 'help '.a:topic
  catch
    exe 'helptags '.s:plugin_dir.'/doc'
    silent exe 'help '.a:topic
  endtry
endfunction

