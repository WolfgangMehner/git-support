"-------------------------------------------------------------------------------
"
"          File:  data.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  20.12.2020
"      Revision:  ---
"       License:  Copyright (c) 2020, Wolfgang Mehner
"-------------------------------------------------------------------------------

let s:plugin_dir = expand('<sfile>:p:h:h:h')

function! s:LoadJson ( filename )
  try
    let str = readfile( a:filename )
    return [ 0, json_decode( join( str, "\n" ) ) ]
  catch /E484:.*/
    return [ 1, { 'error_type': 'could not read file', 'error_message': substitute( v:exception, '^\S*:E484:\s*', '', '' ) } ]
  catch /E491:.*/
    return [ 1, { 'error_type': 'could not read json', 'error_message': substitute( v:exception, '^\S*:E491:\s*', '', '' ) } ]
  catch /.*/
    return [ 1, { 'error_type': 'internal error', 'error_message': v:exception, 'throwpoint': v:throwpoint } ]
  endtry
endfunction


function! gitsupport#data#LoadData ( filename )
  let filename = s:plugin_dir..'/git-support/data/'..a:filename..'.json'
  let [ ret_code, data ] = s:LoadJson( filename )

  if ret_code == 0
    return data
  else
    call s:ErrorMsg( printf( 'Git-Support: error while loding data: %s', data.error_message ) )
    return {}
  endif
endfunction

function! s:ErrorMsg ( ... )
  echohl WarningMsg
  for line in a:000
    echomsg line
  endfor
  echohl None
endfunction

function! s:WarningMsg ( ... )
  echohl WarningMsg
  echo join( a:000, "\n" )
  echohl None
endfunction

