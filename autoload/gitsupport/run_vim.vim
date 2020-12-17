"-------------------------------------------------------------------------------
"
"          File:  run_vim.vim
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

function! gitsupport#run_vim#JobRun ( cmd, params, opts )
  let job_data = {}
  let job_data.in_io = 'null'
  let job_data.out_io = 'buffer'
  let job_data.out_buf = bufnr( '%' )
  let job_data.exit_cb  = function( 's:JobExit' )
  let job_data.close_cb = function( 's:JobClose' )
  if a:opts.cwd != ''
    let job_data.cwd = a:opts.cwd
  endif
  let job_data.env = a:opts.env

  let job_obj = job_start( [a:cmd] + a:params, job_data )

  let job_id = job_info( job_obj ).process

  let g:all_jobs[job_id] = { 'job': job_obj, 'is_closed': 0, 'is_exited': 0, 'opts': a:opts, }
endfunction

function! s:JobWrapup ( job_id )
  let job_data = g:all_jobs[ a:job_id ]
  let opts = job_data.opts

  call gitsupport#common#BufferSetPosition( opts.restore_cursor )
  if job_data.status == 0
    call opts.callback()
  endif

  unlet g:all_jobs[ a:job_id ]

  " restart syntax highlighting
  if &syntax != ''
    setlocal syntax=ON
  endif
endfunction

function! s:JobExit ( job, status )
  let job_id = job_info( a:job ).process
  let job_data = g:all_jobs[ job_id ]
  let job_data.is_exited = 1
  let job_data.status    = a:status

  if job_data.is_closed
    call s:JobWrapup( job_id )
  endif
endfunction

function! s:JobClose ( channel )
  let job = ch_getjob( a:channel )
  let job_id = job_info( job ).process
  let job_data = g:all_jobs[ job_id ]
  let job_data.is_closed = 1

  if job_data.is_exited
    call s:JobWrapup( job_id )
  endif
endfunction

