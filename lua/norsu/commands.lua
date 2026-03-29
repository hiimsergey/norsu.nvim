-- TODO ALL CONSIDER using classes in function signature comments
local vim = vim

local M = {}

--- @param config Config user configuration set in `require "norsu".setup()`
M.register_ubiquitous = function(config)
	--- Initialize the current working directory as a Norsu wiki by creating
	--- `.norsu.json`.
	local function Init()
		if vim.uv.fs_stat(".norsu.json") then
			vim.notify(vim.w.norsu.root .. " is already a wiki")
			return
		end

		local fd, err_open = vim.uv.fs_open(".norsu.json", "w", 438)
		if not fd then
			vim.notify(err_open, vim.log.levels.ERROR)
			return
		end

		local ok, err_write = vim.uv.fs_write(
			fd,
			[[{
	"TODO": "what to put here?"
}]],
			-1
		)
		vim.uv.fs_close(fd)

		if not ok then
			vim.notify(err_write, vim.log.levels.ERROR)
			return
		end

		-- TODO index without checking/crawling
		M.register_exclusive(config)

		local bufname = vim.api.nvim_buf_get_name(0)
		local bufdir = bufname == "" and vim.uv.cwd() or vim.fs.dirname(bufname)

		vim.w.norsu.root = bufdir -- TODO FINAL CONSIDER
		vim.notify("New Norsu wiki at " .. bufdir)
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuInit", Init,
		{ desc = "Initialize a new Norsu wiki at cwd" })
end

-- TODO ALL get completions
--- @param config Config user configuration from `require "norsu".setup()`
M.register_exclusive = function(config)
	--- Open the file switcher for the current wiki with a Telescope picker or
	--- open a note from an arg.
	--- @param opts OpenOpts
	--- @class OpenOpts
	--- @field args string just open the note at this path
	--- @field bang boolean create the note if the submitted path doesn't exist
	local function Open(opts)
		if opts.args == "" then
			-- TODO use picker
			print "NorsuOpen TODO no args :("
			return
		end

		if opts.args:sub(-3, -1) ~= ".no" then opts.args = opts.args .. ".no" end

		local abspath = vim.w.norsu.root .. "/" .. config.entry_dir .. "/" .. opts.args
		local relpath = vim.fs.relpath(vim.w.norsu.root, abspath)

		-- Ensure the destination exists
		if not relpath then
			vim.notify("Not a wiki subpath: " .. opts.args, vim.log.levels.ERROR)
			return
		end

		if not vim.uv.fs_stat(abspath) then
			if not opts.bang then
				vim.notify(
					"No such file: " .. relpath .. " (use :NorsuOpen! to create)",
					vim.log.levels.ERROR
				)
				return
			end

			local fd, err = vim.uv.fs_open(abspath, "a", 420)
			if not fd then
				vim.notify(err, vim.log.levels.ERROR)
				return
			end
			vim.uv.fs_close(fd)

			vim.notify("Created note " .. relpath)
			-- TODO add to index
		end

		-- TODO TEMPORARY + NOW move this to own function shared by NorsuLinkFollow
		-- + NOTE vim.cmd.edit is great but i need:
		--      create buffer (with handle pls)
		--      open this bufer in this pane
		--
		-- TODO PLAN
		-- test all prior commands
		-- basic indexing
		-- pickers for all prior commands
		-- util.open()
		-- :NorsuGoBack and :NorsuGoForward
		-- write tree-sitter-norsu
		vim.cmd.edit(abspath)

		local buf = vim.api.nvim_get_current_buf()
		if vim.w.norsu.history[vim.w.norsu.i] ~= buf then
			table.insert(vim.w.norsu.history, buf)
			vim.w.norsu.i = vim.w.norsu.i + 1
			vim.w.norsu.history[vim.w.norsu.i] = buf
			vim.w.norsu.history[vim.w.norsu.i + 1] = nil
		end
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuOpen", Open,
		{ bang = true, nargs = "?", desc = "Open or create a new Norsu note" })

	--- Create a new folder in the wiki with a Telescope picker or an arg.
	--- @param opts NewFolderOpts
	--- @class NewFolderOpts
	--- @field args string just create the folder at this path
	local function NewFolder(opts)
		if opts.args == "" then
			-- TODO use picker
			print "TODO no args :("
			return
		end

		local cwd = vim.uv.cwd()
		local entries = {}
		local sep = package.config:sub(1, 1)

		for entry in string.gmatch(opts.args, "[^" .. sep .. "]+") do
			table.insert(entries, entry)
		end

		vim.uv.chdir(vim.w.norsu.root .. "/" .. config.entry_dir)
		for i = 1, #entries do
			local ok, err_mkdir = vim.uv.fs_mkdir(entries[i], 493)
			if not ok then
				vim.notify(err_mkdir, vim.log.levels.ERROR)
				vim.uv.chdir(cwd)
				return
			end
			vim.uv.chdir(entries[i])
		end

		vim.uv.chdir(cwd)
		vim.notify("Made folder " .. opts.args)
		-- TODO add to index if necessary
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuNewFolder", NewFolder,
		{ nargs = "?", desc = "Create a folder in a Norsu wiki" })

	--- Rename the currently open note with a Telescope picker or an arg.
	--- @param opts RenameOpts
	--- @class RenameOpts
	--- @field args string just rename the note to this name
	local function Rename(opts)
		local bufpath = vim.api.nvim_buf_get_name(0)
		if bufpath == "" then
			vim.defer_fn(function()
				vim.notify("Empty buffer", vim.log.levels.ERROR)
			end, 0)
			return
		end
		local bufdir = vim.fs.dirname(bufpath)

		local function actually_rename()
			if opts.args:find "[%z/\\<>:\"|%?%*]" or
				opts.args == "." or
				opts.args == ".." then
				vim.defer_fn(function()
					vim.notify("Invalid basename: " .. opts.args, vim.log.levels.ERROR)
				end, 0)
				return
			end

			local bufpath_new = bufdir .. "/" .. opts.args
			vim.uv.fs_rename(bufpath, bufpath_new)
			vim.cmd.edit(bufpath_new) -- TODO CONSIDER better way
		end

		if opts.args == "" then
			vim.ui.input(
				{ prompt = "Enter new name: " },
				function(input)
					if input == nil then
						vim.notify "Rename aborted"
						return
					end
					opts.args = input
					actually_rename()
				end
			)
			return
		end

		actually_rename()
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuRename", Rename,
		{ nargs = "?", desc = "Rename a Norsu note" })

	--- Move the currently open note to another folder with a Telescope picker or an arg.
	--- @param opts MoveOpts
	--- @class MoveOpts
	--- @field args string just move the note into this path
	--- @field bang boolean overwrite the destination, if already existed
	local function Move(opts)
		if opts.args == "" then
			-- TODO use picker
			vim.notify "TODO no args :("
			return
		end

		local abspath = vim.w.norsu.root .. "/" .. opts.args
		local relpath = vim.fs.relpath(vim.w.norsu.root, abspath)

		-- Ensure the destination exists
		local stat = vim.uv.fs_stat(abspath)
		if not stat then
			vim.notify("No such folder: " .. opts.args, vim.log.levels.ERROR)
			return
		end
		if stat.type ~= "directory" then
			vim.notify("Not a folder: " .. opts.args, vim.log.levels.ERROR)
			return
		end

		-- Prevent moving outside the wiki
		if not relpath then
			vim.notify("Not a wiki subpath: " .. opts.args, vim.log.levels.ERROR)
			return
		end

		local bufpath = vim.api.nvim_buf_get_name(0)
		local bufrelpath = vim.fs.relpath(vim.w.norsu.root, bufpath)
		local bufbasename = vim.fs.basename(bufpath)

		local bufpath_new = abspath .. "/" .. bufbasename
		local bufrelpath_new = vim.fs.relpath(vim.w.norsu.root, bufpath_new)

		if not opts.bang and vim.uv.fs_stat(bufpath_new) then
			vim.notify(
				bufrelpath_new .. " already exists (use :NorsuMove! to overwrite)",
				vim.log.levels.ERROR
			)
			return
		end

		local ok, err_rename = vim.uv.fs_rename(bufpath, bufpath_new)
		if not ok then
			vim.notify(err_rename, vim.log.levels.ERROR)
			return
		end

		vim.cmd.edit(bufpath_new) -- TODO READ is there a more elegant solution?
		vim.notify(bufrelpath .. " -> " .. bufrelpath_new)
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuMove", Move,
		{ bang = true, nargs = "?", desc = "Move a Norsu note to another folder" })

	--- Delete notes and folders using a Telescope picker or an arg.
	--- Use `<Tab>` to select items and `<CR>` to submit.
	--- @param opts DeleteOpts
	--- @class DeleteOpts
	--- @field args string only delete the entry at this path.
	---                    `%` resolves to the currently open note.
	--- @field bang boolean skip confirmation dialog
	local function Delete(opts)
		local paths = {}
		local ghosts = {}
		local foreigners = {}

		if opts.args == "" then
			vim.notify "TODO NorsuDelete no picker? :("
			return
		else
			paths = { opts.args }
		end

		-- TODO TEST
		paths = { "delme", "delme.no" }

		-- TODO close buffers of deleted notes
		-- use the proposed O(n + m) solution
		for i = #paths, 1, -1 do
			local abspath = paths[i] == "%" and
			vim.api.nvim_buf_get_name(0) or
			vim.w.norsu.root .. "/" .. paths[i]

			if not vim.uv.fs_stat(abspath) then
				table.insert(ghosts, table.remove(paths, i))
				goto continue
			end

			local relpath = vim.fs.relpath(vim.w.norsu.root, abspath)
			if not relpath then
				table.insert(foreigners, table.remove(paths, i))
				goto continue
			end

			paths[i] = abspath
			::continue::
		end

		local numerus = #paths == 1 and " entry" or " entries"
		local function actually_delete()
			for _, path in ipairs(paths) do
				vim.fs.rm(path, { recursive = true })
			end

			local errmsg = ""
			if #ghosts > 0 then
				errmsg = errmsg .. "NorsuDelete: No such files or folders:"
				for _, path in ipairs(ghosts) do
					errmsg = errmsg .. "\n    " .. path
				end
			end
			if #foreigners > 0 then
				errmsg = errmsg .. "\nNorsuDelete: Files or folders outside the wiki:"
				for _, path in ipairs(foreigners) do
					errmsg = errmsg .. "\n    " .. path
				end
			end

			vim.api.nvim_echo({{ errmsg }}, errmsg ~= "", { err = true })
			if #paths > 0 then
				vim.defer_fn(function()
					vim.notify("Deleted " .. #paths .. numerus)
				end, 0)
			end
		end

		if not opts.bang and #paths > 0 then
			vim.ui.input(
				{ prompt =
					"Do you want to delete " .. #paths .. numerus .. " [y/N] "
				},
				function(input)
					if not (
						input and
						(input:lower() == "y" or input:lower() == "yes")
					) then
						vim.defer_fn(function()
							vim.notify "Deletion aborted"
						end, 0)
						return
					end
					actually_delete()
				end
			)
			return
		end

		actually_delete()
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuDelete", Delete,
		{ bang = true, nargs = "?", desc = "Delete the currently open Norsu note" })

	--- Navigates back in the note history of the current buffer.
	--- @param opts GoOpts
	--- @class GoOpts
	--- @field count number go back multiple notes
	local function GoBack(opts)
		opts.count = opts.count or 1

		if vim.w.norsu.i == 1 then
			vim.notify "Already at oldest note"
			return
		end

		if opts.count < 1 or opts.count > vim.w.norsu.i - 1 then
			vim.notify("Invalid argument", vim.log.levels.ERROR)
			return
		end

		vim.w.norsu.i = vim.w.norsu.i - opts.count
		vim.api.nvim_set_current_buf(vim.w.norsu.history[vim.w.norsu.i])
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuGoBack", GoBack,
		{ count = 1, desc = "Navigate back in the Norsu note history" })

	--- Navigates forward in the note history of the current buffer.
	--- @param opts GoOpts
	--- @class GoOpts
	local function GoForward(opts)
		opts.count = opts.count or 1

		if vim.w.norsu.history[vim.w.norsu.i + 1] == nil then
			vim.notify "Already at newest note"
			return
		end

		if opts.count < 1 or not vim.w.norsu.history[vim.w.norsu.i + opts.count] then
			vim.notify("Invalid argument", vim.log.levels.ERROR)
			return
		end

		vim.w.norsu.i = vim.w.norsu.i + opts.count
		vim.api.nvim_set_current_buf(vim.w.norsu.history[vim.w.norsu.i])
	end
	vim.api.nvim_buf_create_user_command(0, "NorsuGoForward", GoForward,
		{ count = 1, desc = "Navigate forward in the Norsu note history" })
end

return M
