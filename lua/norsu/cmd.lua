local vim = vim
local uv = vim.uv
local tst_move = require "nvim-treesitter-textobjects.move"
local get_wiki_path = require "norsu.get_wiki_path"
local M = {}

--- Registers NorsuInit, only Norsu command that's always available.
M.register_ubiquitous = function()
	-- TODO accept single optional string argument
	-- ^ i.e. the exact path initialized

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
	vim.api.nvim_create_user_command("NorsuInit", M.NorsuInit,
		{ desc = "Initialize new Norsu wiki at cwd" })
end

--- Registers Norsu commands only available if we're in a wiki.
M.register_exclusive = function()
	-- TODO CONSIDER vim.g.norsu.path
	-- ^ it used to be vim.g.norsu
	if vim.g.norsu.path then return end

	-- TODO NOW DEBUG it can jump to ~/foo.no, even if ~ is not a wiki
	--- Opens entry referenced in the link below the cursor.
	--- If note doesn't exist, opens a new buffer in the wiki root.
	--- @return boolean link_below_cursor
	M.NorsuLinkEnter = function()
		--- @param node any
		--- @return any?
		local function get_link_address_node(node)
			if not node then return nil end
			local parent = node:parent()

			if parent:type() == "link" then return parent:named_child(1) end
			if node:type() == "link" then return node:named_child(1) end
			return nil
		end

		--- @param relpath string
		local function find_and_open(relpath)
			local abspath = vim.fs.find(relpath, {
				type = "file",
				path = vim.g.norsu.path
			})[1] or vim.g.norsu.path .. "/" .. relpath

			vim.cmd.edit(abspath)
			return true
		end

		local cursor = vim.api.nvim_win_get_cursor(0)
		local row, col = cursor[1] - 1, cursor[2]

		local target_node = vim.treesitter.get_node { bufnr = 0, pos = { row, col } }
		local addr_node = get_link_address_node(target_node)
		if not addr_node then return false end

		local link_address = vim.treesitter.get_node_text(addr_node, 0)
		local section_separator_index = string.find(link_address, "#", 1, true)

		if not section_separator_index then
			find_and_open(link_address .. ".no")
			return true
		end

		if section_separator_index > 1 then
			local note_path = link_address:sub(1, section_separator_index - 1) .. ".no"
			find_and_open(note_path)
		end

		local section = link_address:sub(section_separator_index + 1)
		-- TODO TEST with trailing spaces
		-- TODO NOW DEBUG trailing spaces should not be part of h_text
		local query_string = string.format(
			[[ (
				((_) (h_text) @text)
				(#eq? @text "%s")
			) ]],
			section
		)
		local query = vim.treesitter.query.parse("norsu", query_string)
		local root = vim.treesitter.get_parser(0, "norsu"):parse()[1]:root()

		local section_node = select(2, query:iter_captures(root, 0, 0, -1)())
		if not section_node then return true end

		row, col = section_node:range()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })

		return true
	end
	vim.api.nvim_create_user_command("NorsuLinkEnter", M.NorsuLinkEnter,
		{ desc = "Follow link" })

	-- TODO use the native querying instead and get rid of the dependency
	--- Moves cursor to next link.
	M.NorsuLinkNext = function()
		local function next()
			local ok = pcall(tst_move.goto_next_start, "@link", "textobjects")
			assert(ok,
				"NorsuLinkNext failed! Perhaps you're missing the tree-sitter grammar!")
		end

		local before = vim.api.nvim_win_get_cursor(0)
		next()
		local after = vim.api.nvim_win_get_cursor(0)

		if before[1] == after[1] and before[2] == after[2] then
			vim.api.nvim_win_set_cursor(0, { 1, 0 })
			next()
		end
	end
	vim.api.nvim_create_user_command("NorsuLinkNext", M.NorsuLinkNext,
		{ desc = "Move cursor to next link" })

	-- TODO use the native querying instead and get rid of the dependency
	--- Moves cursor to previous link.
	M.NorsuLinkPrev = function()
		local function prev()
			local ok = pcall(tst_move.goto_previous_start, "@link", "textobjects")
			assert(ok,
				"NorsuLinkPrev failed! Perhaps you're missing the tree-sitter grammar!")
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
	vim.api.nvim_create_user_command("NorsuLinkPrev", M.NorsuLinkPrev,
		{ desc = "Move cursor to previous link" })
end

return M
