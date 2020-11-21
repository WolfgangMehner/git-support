#!/usr/bin/env lua
--
--------------------------------------------------------------------------------
--         FILE:  release.lua
--
--        USAGE:  project/release.lua <mode>
--
--  DESCRIPTION:  Run from the project's top-level directory.
--
--      OPTIONS:  The mode is one of:
--                - list
--                - check
--                - zip
--                - archive
--                - help
--
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  Wolfgang Mehner, <wolfgang-mehner@web.de>
--      COMPANY:  
--      VERSION:  1.0
--      CREATED:  05.01.2016
--     REVISION:  21.11.2020
--------------------------------------------------------------------------------
--

------------------------------------------------------------------------
--  Auxiliary Functions
------------------------------------------------------------------------

local function escape_shell ( text )
	return string.gsub ( text, '[%(%);&=\' ]', function ( m ) return '\\' .. m end )
end

------------------------------------------------------------------------
--  Arguments and File List
------------------------------------------------------------------------

local plugin_name = 'git-support'
local outfile = escape_shell ( plugin_name..'.zip' )

local mode = arg[1]
local print_help = false

-- files for the zip-archive
local filelist = {
	'doc/gitsupport.txt',
	'plugin/git-support.vim',
	'git-support/data/',
	'git-support/rc/',
	'syntax/gits*.vim',
	'CHANGELOG.md',
	'README.md',
}

-- additional files for the stand-alone repository
local filelist_repo = {
	'git-support/git-doc/',
	'project/release.lua',
}

------------------------------------------------------------------------
--  Processing ...
------------------------------------------------------------------------

for idx, val in ipairs ( filelist or {} ) do
	filelist[ idx ] = escape_shell ( val )
end

if #arg == 0 then

	print ( '\n=== failed: mode missing ===\n' )

	print_help = true

elseif mode == 'list' then

	local cmd = 'ls -1 '..table.concat ( filelist, ' ' )

	print ( '\n=== listing ===\n' )

	local success, res_reason, res_status = os.execute ( cmd )

	if success then
		print ( '\n=== done ===\n' )
	else
		print ( '\n=== failed: '..res_reason..' '..res_status..' ===\n' )
	end

elseif mode == 'check' then

	local flag_dir  = '--directories recurse'
	local flag_excl = '--exclude "*.pdf"'
	local cmd = 'grep '..flag_dir..' '..flag_excl..' -nH ":[[:upper:]]\\+:\\|[Tt][Oo][Dd][Oo]" '..table.concat ( filelist, ' ' )

	print ( '\n=== checking ===\n' )

	local success, res_reason, res_status = os.execute ( cmd )

	if success then
		print ( '\n=== done ===\n' )
	else
		print ( '\n=== failed: '..res_reason..' '..res_status..' ===\n' )
	end

elseif mode == 'zip' then

	local cmd = 'zip -r '..outfile..' '..table.concat ( filelist, ' ' )

	print ( '\n=== executing: '..outfile..' ===\n' )

	local success, res_reason, res_status = os.execute ( cmd )

	if success then
		print ( '\n=== successful ===\n' )
	else
		print ( '\n=== failed: '..res_reason..' '..res_status..' ===\n' )
	end

elseif mode == 'archive' then

	local cmd = 'git archive --prefix='..plugin_name..'/'..' --output='..outfile..' HEAD'

	print ( '\n=== executing: '..outfile..' ===\n' )

	local success, res_reason, res_status = os.execute ( cmd )

	if success then
		print ( '\n=== successful ===\n' )
	else
		print ( '\n=== failed: '..res_reason..' '..res_status..' ===\n' )
	end

elseif mode == 'help' then

	print_help = true

else

 	print ( '\n=== failed: unknown mode "'..mode..'" ===\n' )

	print_help = true

end

------------------------------------------------------------------------
--  Help
------------------------------------------------------------------------

if print_help then

	io.write [[

release <mode>

Modes:
  list    - list all files
  check   - check the release
  zip     - create archive via "zip"
  archive - create archive via "git archive"
  help    - print help

]]
end
