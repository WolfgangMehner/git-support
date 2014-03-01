--
--------------------------------------------------------------------------------
--         FILE:  release.lua
--        USAGE:  lua git-support/release.lua <mode> [<options>]
--  DESCRIPTION:  Run from the project's top-level directory.
--      OPTIONS:  The mode is either "check", "zip", "cp-repo" or "help".
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  Wolfgang Mehner, <wolfgang-mehner@web.de>
--      COMPANY:  
--      VERSION:  1.0
--      CREATED:  24.12.12
--     REVISION:  19.02.14
--------------------------------------------------------------------------------
--

function escape_shell ( text )
	return string.gsub ( text, '[%(%);&=\' ]', function ( m ) return '\\' .. m end )
end  ----------  end of function escape_shell  ----------

local args = { ... }

local outfile = 'git-support.zip'

local filelist = {
	'doc/gitsupport.txt',
	'plugin/git-support.vim',
	'git-support/doc/',
	'git-support/rc/',
	'git-support/README.md',
	'syntax/gits*.vim',
}

local filelist_repo = {
	'git-support/git-doc/',
	'git-support/release.lua',
}

outfile = escape_shell ( outfile )
for idx, val in ipairs ( filelist ) do
	filelist[ idx ] = escape_shell ( val )
end

local print_help = false

if #args == 0 then

	print ( '\n=== failed: mode missing ===\n' )

	print_help = true

elseif args[1] == 'check' then

	local cmd = 'grep -nH ":[[:upper:]]\\+:\\|[Tt][Oo][Dd][Oo]" '..table.concat ( filelist, ' ' )

	print ( '\n=== checking ===\n' )

	local success, res_reason, res_status = os.execute ( cmd )

	if success then
		print ( '\n=== done ===\n' )
	else
		print ( '\n=== failed: '..res_reason..' '..res_status..' ===\n' )
	end

elseif args[1] == 'zip' then

	local cmd = 'zip -r '..outfile..' '..table.concat ( filelist, ' ' )

	print ( '\n=== executing: '..outfile..' ===\n' )

	local success, res_reason, res_status = os.execute ( cmd )

	if success then
		print ( '\n=== successful ===\n' )
	else
		print ( '\n=== failed: '..res_reason..' '..res_status..' ===\n' )
	end

elseif args[1] == 'cp-repo' then

	if #args >= 2 then

		filelist_compl = {}

		for key, val in pairs ( filelist ) do
			table.insert ( filelist_compl, val )
		end

		for key, val in pairs ( filelist_repo ) do
			table.insert ( filelist_compl, val )
		end

		os.execute ( 'mkdir -p '..args[2] )

		local cmd = 'cp --parents -r '..table.concat ( filelist_compl, ' ' )..' '..args[2]

		print ( '\n=== copying: '..args[2]..' ===\n' )

		local success, res_reason, res_status = os.execute ( cmd )

		if success then
			cmd = 'cat git-support/README.standalone.md git-support/README.md > '..args[2]..'/README.md'

			success, res_reason, res_status = os.execute ( cmd )
		end

		if success then
			print ( '\n=== successful ===\n' )
		else
			print ( '\n=== failed: '..res_reason..' '..res_status..' ===\n' )
		end

	else

		print ( '\n=== failed: no destination given: release.lua cp-repo <dest> ===\n' )

	end

elseif args[1] == 'help' then

	print_help = true

else

	print ( '\n=== failed: unknown mode "'..args[1]..'" ===\n' )

	print_help = true

end

if print_help then

	print ( '' )
	print ( 'release <mode>' )
	print ( '' )
	print ( '\tcheck          - check the release' )
	print ( '\tzip            - create archive' )
	print ( '\tcp-repo <dest> - copy the repository' )
	print ( '\thelp           - print help' )
	print ( '' )

end