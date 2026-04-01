local vim = vim
local uv = vim.uv
local M = {}

--- Registers NorsuInit, only Norsu command that's always available.
M.register_ubiquitous = function()
	--- Initialize current working directory as new Norsu wiki by creating
	--- .norsu.json.
	local function NorsuInit()
		if uv.fs_stat ".norsu.json" then
			vim.notify "This is already a wiki"
			return
		end

		local fd = assert(uv.fs_open(".norsu.json", "w", 438))

		assert(uv.fs_write(
			fd,
			[[{ "entry_dir": "." }]],
			-1
		))
		uv.fs_close(fd)

		M.register_exclusive()

		local bufname = vim.api.nvim_buf_get_name(0)
		local bufdir = bufname == "" and assert(uv.cwd()) or vim.fs.dirname(bufname)

		vim.g.norsu = { path = bufdir }
		vim.notify("New Norsu wiki at " .. bufdir)
	end
	vim.api.nvim_create_user_command("NorsuInit", NorsuInit,
		{ desc = "Initialize new Norsu wiki at cwd" })
end

--- Registers Norsu commands only available if we're in a wiki.
M.register_exclusive = function()
	-- TODO NOW
end

return M
