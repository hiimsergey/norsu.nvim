--- Prints error message
--- @param msg string
return function(msg)
	vim.notify(msg, vim.log.levels.ERROR)
end
