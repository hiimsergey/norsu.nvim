local vim = vim
local uv = vim.uv
local cmd = require "norsu.cmd"
local data = require "norsu.data"
local get_wiki_path = require "norsu.get_wiki_path"
local M = {}

--- Starting point of the plugin.
--- @param root? string
---     Deepest directory containing all detectable wikis on the system.
---     The wiki indexing algorithm stops crawling here.
---     All wikis outside the root will not be indexed.
M.setup = function(root)
	root = root or uv.os_homedir() or "/"
	data = { root = root }
	cmd.register_ubiquitous()

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			-- TODO PLAN
			-- check if note path is in a wiki
			-- if yes, update vim.g.norsu and register exclusive (if not registered)

			local bufname = vim.api.nvim_buf_get_name(0)
			-- TODO FINAL CONSIDER a prettier form
			-- ^v (this is supposed to result in an absolute path)
			local bufdirpath = bufname == "" and assert(uv.cwd()) or
				vim.fs.dirname(bufname)

			-- Don't proceed if buffer path is outside root or doesn't contain .norsu.json
			local wiki_path = get_wiki_path(bufdirpath, root)
			if not wiki_path then return end

			-- At that point, the just opened file is part of a wiki.

			cmd.register_exclusive()

			vim.api.nvim_create_autocmd("BufWritePost", {
				buffer = 0,
				callback = function()
					-- TODO PLAN
					-- reindex: update outlinks and backlinks
				end
			})

			-- Only update current norsu wiki if it's a new one
			if not data or data.path ~= wiki_path then
				data.path = wiki_path

				-- TODO CONSIDER defer_fn
				vim.defer_fn(function()
					vim.notify("Entered Norsu wiki at " .. wiki_path)
				end, 0)
			end
		end
	})
end

return M

-- TODO NOTE when leaving wiki for another norsu file, you still can enter links
-- what to do?

-- TODO NOTE
-- consider updating the index locally and only writing it on VimLeave
-- store index wiki.mpack files in stdpath("cache")

-- TODO NOTE PLAN of indexing
-- after registering wiki:
-- if cachefile doesnt exit, index everything
-- otherwise {diff note list with index' file list}
-- ^ delete indexes without corresponding notes
-- only update entries where mtime < file's mtime
-- if file is new, create new entry
-- after writing current file:
-- update outlinks (including removing deprecated info) (that including updating other note's backlinks)
-- update other files' backlinks accordingly
-- when calling a note's backlinks:
-- check that every one exists
-- if one is deleted, perform routine note-deleted:
-- using foo.outlinks, remove foo as a backlink from every note; finally delete foo.outlinks
-- TODO how to handle external prcesses adding links to a file?

-- TODO NOTE commands updating the index:
-- NorsuRename, NorsuMove, NorsuDelete

-- TODO add ghosts_in_open wiki setting

-- TODO deprecate vim.g.norsu

-- TODO
-- help pages
-- how to install the grammar more elegantly than cloning tree-sitter-norsu?
-- CONSIDER making option for whether wiki entering detection should be automatic
-- CONSIDER implementing native gf mechanism for NorsuLinkEnter
-- CONSIDER option for whether to show punctuation characters or not
-- FINAL ALL CHECK all pickers are abortable

-- TODO
-- option conceal
-- option also conceal URLs: https://github.com/hiimsergey/tree-sitter-norsu
-- ^-> github.com/~/tree-sitter-norsu
