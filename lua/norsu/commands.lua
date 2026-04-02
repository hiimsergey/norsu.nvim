local vim = vim
local uv = vim.uv
local get_wiki_path = require "norsu.get_wiki_path"
local M = {}

--- Registers NorsuInit, only Norsu command that's always available.
--- @param root string
---     Deepest directory containing all detectable wikis on the system.
---     The wiki indexing algorithm stops crawling here.
---     All wikis outside the root will not be indexed.
M.register_ubiquitous = function(root)
	--- Initialize current working directory as new Norsu wiki by creating
	--- .norsu.json.
	local function NorsuInit()
		local bufname = vim.api.nvim_buf_get_name(0)
		local bufdirpath = bufname == "" and assert(uv.cwd()) or
			vim.fs.dirname(bufname)
		local json_path = bufdirpath .. "/.norsu.json"

		if get_wiki_path(json_path, root) then
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

		vim.g.norsu = { path = bufdirpath }
		vim.notify("New Norsu wiki at " .. bufdirpath)
	end
	vim.api.nvim_create_user_command("NorsuInit", NorsuInit,
		{ desc = "Initialize new Norsu wiki at cwd" })
end

--- Registers Norsu commands only available if we're in a wiki.
M.register_exclusive = function()
	if vim.g.norsu then return end

	-- TODO PLAN
	-- Norsu
end

return M
