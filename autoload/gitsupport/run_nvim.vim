"-------------------------------------------------------------------------------
"
"          File:  run_nvim.vim
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

let g:all_jobs = {}

function! gitsupport#run_nvim#JobRun ( cmd, params, opts )
  let job_data = {}
  let job_data.on_stdout = function( 's:JobOutput' )
  let job_data.on_stderr = function( 's:JobOutput' )
  let job_data.on_exit   = function( 's:JobExit' )
  if a:opts.cwd != ''
    let job_data.cwd = a:opts.cwd
  endif
  let job_data.env = a:opts.env

  let job_id = jobstart( [a:cmd] + a:params, job_data )

  if job_id > 0
    let g:all_jobs[job_id] = { 'job': job_id, 'buf': bufnr('%'), 'line_accu': '', 'buf_nr': bufnr('%'), 'opts': a:opts, }
  endif
endfunction

function! s:JobWrapup ( job_id )
  let job_data = g:all_jobs[ a:job_id ]
  call gitsupport#run#JobWrapup( job_data )

  unlet g:all_jobs[ a:job_id ]
endfunction

function! s:JobOutput ( job_id, data, event )
  let line_data = a:data
  let job_data = g:all_jobs[ a:job_id ]
  let buf = job_data.buf

  if line_data == ['']   " EOF
    if job_data.line_accu != ''
      call nvim_buf_set_lines( buf, -2, -2, 1, [ job_data.line_accu ] )
      let job_data.line_accu = ''
    endif
    return
  endif

  let first_line = job_data.line_accu . line_data[0]
  let job_data.line_accu = line_data[-1]

  call nvim_buf_set_lines( buf, -2, -2, 1, [ first_line ] )
  call nvim_buf_set_lines( buf, -2, -2, 1, line_data[1:-2] )
endfunction

function! s:JobExit ( job_id, status, event )
  let job_id = a:job_id
  let job_data = g:all_jobs[ job_id ]
  let job_data.status = a:status

  call s:JobWrapup( job_id )
endfunction

