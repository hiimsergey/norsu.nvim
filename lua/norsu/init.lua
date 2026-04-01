local vim = vim
local cmd = require "norsu.commands"
local err = require "norsu.err"
local M = {}

--- Starting point of the plugin.
--- @param root? string
---     Deepest directory containing all detectable wikis on the system.
---     The wiki indexing algorithm stops crawling here.
---     All wikis outside the root will not be indexed.
M.setup = function(root)
	if vim.g.norsu then
		err "Someones else already took our namespace! Resigning..."
		return
	end

	root = root or os.getenv "HOME" or os.getenv "HOMEPATH" or "/"

	cmd.register_ubiquitous()
end

return M
