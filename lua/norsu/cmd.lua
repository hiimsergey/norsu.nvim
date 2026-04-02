local vim = vim
local uv = vim.uv
local tst_move = require "nvim-treesitter-textobjects.move"
local err = require "norsu.err"
local get_wiki_path = require "norsu.get_wiki_path"
local M = {}

--- Registers NorsuInit, only Norsu command that's always available.
M.register_ubiquitous = function()
	vim.api.nvim_create_user_command("NorsuInit", M.NorsuInit,
		{ desc = "Initialize new Norsu wiki at cwd" })
end

--- Registers Norsu commands only available if we're in a wiki.
M.register_exclusive = function()
	if vim.g.norsu then return end

	vim.api.nvim_create_user_command("NorsuLinkEnter", M.NorsuLinkEnter,
		{ desc = "Follow link" })
	vim.api.nvim_create_user_command("NorsuLinkNext", M.NorsuLinkNext,
		{ desc = "Move cursor to next link" })
	vim.api.nvim_create_user_command("NorsuLinkPrev", M.NorsuLinkPrev,
		{ desc = "Move cursor to previous link" })
	-- TODO NOW
end

--- Initialize current working directory as new Norsu wiki by creating
--- .norsu.json.
M.NorsuInit = function()
	local bufname = vim.api.nvim_buf_get_name(0)
	local bufdirpath = bufname == "" and assert(uv.cwd()) or
		vim.fs.dirname(bufname)
	local json_path = bufdirpath .. "/.norsu.json"

	if get_wiki_path(json_path, vim.g.norsu.root) then
		vim.notify "This is already a wiki"
		return
	end

	local fd = assert(uv.fs_open(json_path, "w", 438)) -- 0o666
	assert(uv.fs_write(
		fd,
		[[{ "entry_path": "." }]],
		-1
	))
	uv.fs_close(fd)

	M.register_exclusive()

	local norsu = vim.g.norsu
	norsu.path = bufdirpath
	vim.g.norsu = norsu

	vim.notify("New Norsu wiki at " .. bufdirpath)
end

--- Opens entry referenced in the link below the cursor.
--- If note doesn't exist, opens a new buffer in the wiki root.
--- Returns false if there is no link below the cursor, true if the operation
--- succeeded.
M.NorsuLinkEnter = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	-- treesitter is 0-indexed
	local row, col = cursor[1] - 1, cursor[2]

	local target_node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col } })
	local link_node = target_node:parent()
	if not link_node or link_node:type() ~= "link" then return false end
	local text_node = link_node:named_child(1) -- second child (i.e. link_text)

	local start_row, start_col, end_row, end_col =
		vim.treesitter.get_node_range(text_node)
	local link_text = vim.api.nvim_buf_get_text(bufnr,
		start_row, start_col, end_row, end_col,
		{})[1]
	local relpath_wo_ext = vim.fs.find(link_text, {
		type = "file",
		path = vim.g.norsu.path
	})[1] or link_text

	local relpath = relpath_wo_ext .. ".no"
	vim.cmd.edit(relpath)
	return true
end

--- Moves cursor to next link.
M.NorsuLinkNext = function()
	local function next()
		if not pcall(tst_move.goto_next_start, "@link", "textobjects") then
			err "NorsuLinkNext failed! Perhaps you're missing the tree-sitter grammar!"
		end
	end

	local before = vim.api.nvim_win_get_cursor(0)
	next()
	local after = vim.api.nvim_win_get_cursor(0)

	if before[1] == after[1] and before[2] == after[2] then
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		next()
	end
end

--- Moves cursor to previous link.
M.NorsuLinkPrev = function()
	local function prev()
		if not pcall(tst_move.goto_previous_start, "@link", "textobjects") then
			err "NorsuLinkPrev failed! Perhaps you're missing the tree-sitter grammar!"
		end
	end

	local before = vim.api.nvim_win_get_cursor(0)
	prev()
	local after = vim.api.nvim_win_get_cursor(0)

	if before[1] == after[1] and before[2] == after[2] then
		local last_line = vim.api.nvim_buf_line_count(0)
		local last_col =
			#vim.api.nvim_buf_get_lines(0, last_line - 1, last_line, true)[1]
		vim.api.nvim_win_set_cursor(0, { last_line, last_col })
		prev()
	end
end

return M
