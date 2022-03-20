"-------------------------------------------------------------------------------
"
"          File:  popup.vim
"
"   Description:  
"
"   VIM Version:  8.0+
"        Author:  Wolfgang Mehner, wolfgang-mehner@web.de
"       Version:  1.0
"       Created:  19.03.2022
"      Revision:  ---
"       License:  Copyright (c) 2022, Wolfgang Mehner
"-------------------------------------------------------------------------------

function! gitsupport#popup#Open ( lines, options )
  let width  = winwidth( 0 )
  let height = winheight( 0 )

  let opts = {
        \ 'pos':  'topright',
        \ 'line': 2,
        \ 'col':  width - 1,
        \
        \ 'wrap': 0,
        \ 'maxheight': height - 2,
        \ }

  if len( a:lines ) > opts.maxheight
    let opts.scrollbar = 1
  end

  let win_id = popup_create( a:lines, opts )
  let buf_id = winbufnr( win_id )
  return [win_id, buf_id]
endfunction

function! gitsupport#popup#Close ( win_id )
  call popup_close( a:win_id )
endfunction
