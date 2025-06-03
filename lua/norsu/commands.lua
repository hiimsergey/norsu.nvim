local vim = vim

local M = {}

--- Register Norsu commands that should be available everywhere in Neovim.
--- @param config Config plugin configuration
M.register_ubiquitous = function(config)
    vim.api.nvim_create_user_command("NorsuWiki", function(opts)
        -- TODO
    end, {
        nargs = "?", -- path to open/create. `%` resolves to cwd
        bang = true, -- create a new wiki, if the path is not a valid one
        desc = "Set the given path as the current wiki, if it's valid."
    })
end

--- Register Norsu commands that should only be available in Norsu wikis.
--- @param config Config plugin configuration
M.register_exclusive = function(config)
    vim.api.nvim_create_user_command("NorsuOpen", function(opts)
        -- TODO
    end, {
        nargs = "?", -- TODO COMMENT
        bang = true, -- TODO COMMENT
        desc = "Open or create a new Norsu note"
    })
end

return M
