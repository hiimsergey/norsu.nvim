local vim = vim
local cmd = require "norsu.commands"
local err = require "norsu.err"
local get_wiki_path = require "norsu.get_wiki_path"
local M = {}

--- Starting point of the plugin.
--- @param root? string
---     Deepest directory containing all detectable wikis on the system.
---     The wiki indexing algorithm stops crawling here.
---     All wikis outside the root will not be indexed.
M.setup = function(root)
	-- TODO TEST
	if vim.g.norsu then
		err "Someone else already took our namespace! Resigning..."
		return
	end

	root = root or os.getenv "HOME" or os.getenv "HOMEPATH" or "/"
	cmd.register_ubiquitous(root)

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			-- TODO PLAN
			-- check if note path is in a wiki
			-- if yes, update vim.g.norsu and register exclusive (if not registered)

			local bufname = vim.api.nvim_buf_get_name(0)
			local bufdirpath = bufname == "" and assert(vim.uv.cwd()) or
				vim.fs.dirname(bufname)

			-- don't proceed if buffer path is outside root or doesn't contain .norsu.json
			local wiki_path = get_wiki_path(bufdirpath, root)
			if not wiki_path then return end

			cmd.register_exclusive()

			vim.api.nvim_create_autocmd("BufWritePost", {
				buffer = 0,
				callback = function()
					-- TODO PLAN
					-- reindex: update outlinks and backlinks
				end
			})

			-- only update current norsu wiki if it's a new one
			if not vim.g.norsu or vim.g.norsu.path ~= wiki_path then
				vim.g.norsu = { path = wiki_path }
				vim.defer_fn(function()
					vim.notify("Entered Norsu wiki at " .. wiki_path)
				end, 0)
			end
		end
	})
end

return M

-- TODO
-- help pages
-- FINAL ALL CHECK all pickers are abortable
