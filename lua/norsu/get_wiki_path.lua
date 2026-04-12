local vim = vim

--- Determines whether a given path is a subpath of a Norsu wiki. Returns absolute
--- wiki path if so, otherwise nil.
--- Aborts if path is outside of root.
--- @param path string Path of currently open file
--- @param root string
---     Deepest directory containing all detectable wikis on the system.
---     The wiki indexing algorithm stops crawling here.
---     All wikis outside root will not be indexed.
--- @return string? path Dbsolute path of wiki or nil if note not in a wiki
return function(path, root)
	if not vim.fs.relpath(root, path) then return end
	local norsu_json = vim.fs.find(".norsu.json", {
		upward = true,
		type = "file",
		path = path,
		stop = root
	})
	return next(norsu_json) and vim.fs.dirname(norsu_json[1]) or nil
end
