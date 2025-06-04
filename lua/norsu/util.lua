local vim = vim
local autocmds = require "norsu.autocmds"

local M = {}

--- Register Norsu commands
M.commands = {
    --- Register Norsu commands that should only be available in Norsu wikis.
    --- @param config Config plugin configuration
    exclusive = function(config)
        vim.api.nvim_create_user_command("NorsuOpen", function(opts)
            -- TODO
        end, {
            nargs = "?", -- just open this note
            bang = true, -- create chosen file, if it doesn't exist
            complete = "file",
            desc = "Open or create a new Norsu note"
        })

        vim.api.nvim_create_user_command("NorsuQuit", function()
            vim.g.norsu = nil
            for _, cmd in pairs(vim.api.nvim_get_commands {}) do
                if cmd.name:sub(1, 5) == "Norsu" and cmd.name ~= "NorsuWiki" then
                    vim.api.nvim_del_user_command(cmd.name)
                end
            end
        end, { desc = "Leave Norsu and deregister its commands" })
    end,

    --- Register Norsu commands that should be available everywhere in Neovim.
    --- @param config Config plugin configuration
    ubiquitous = function(config)
        vim.api.nvim_create_user_command("NorsuWiki", function(opts)
            if opts.args == "" then
                if vim.g.norsu then
                    vim.notify(vim.g.norsu.wiki)
                else
                    vim.notify(
                        "Not in a Norsu wiki",
                        vim.log.levels.WARN
                    )
                end
                return
            end

            local cwd = vim.uv.cwd()
            if opts.args == "%" then opts.args = cwd end

            local wiki_path = M.get_wiki_path(opts.args, config)

            if not wiki_path then
                if not opts.bang then
                    vim.notify(
                        opts.args .. " is not a valid wiki (use :NorsuWiki! to create)",
                        vim.log.levels.ERROR
                    )
                    return
                end

                local sep = package.config:sub(1, 1)
                for entry in string.gmatch(opts.args, "[^" .. sep .. "]+") do
                    if not vim.uv.fs_stat(entry) then
                        local ok, err = vim.uv.fs_mkdir(entry, 493)
                        if not ok then
                            vim.notify(err, vim.log.levels.ERROR)
                            vim.uv.chdir(cwd)
                            return
                        end
                    end

                    vim.uv.chdir(entry)
                end

                wiki_path = opts.args
            end

            M.actually.wiki(wiki_path, config)
        end, {
            nargs = "?", -- path to open/create. `%` resolves to cwd
            bang = true, -- create a new wiki, if the path is not a valid one
            complete = "dir",
            desc = "Set the given path as the current wiki, if it's valid"
        })
    end
}


--- Checks if cwd is the subpath of a valid Norsu wiki.
--- If so, returns the wiki path, otherwise nil.
--- @param dir string subpath in question
--- @param config Config plugin configuration
M.get_wiki_path = function(dir, config)
    if not vim.fs.relpath(config.root, dir) then return nil end

    local norsu_dir = vim.fs.find(".norsu", {
        path = dir,
        stop = config.root,
        type = "directory",
        upward = true
    })

    return next(norsu_dir) and vim.fs.dirname(norsu_dir[1]) or nil
end

--- Functions user commands use under the hood that users are not meant to access
M.actually = {
    --- Changes into `dir` and prepares Norsu for this wiki.
    wiki = function(dir, config)
        vim.uv.chdir(dir) -- TODO NOW DEBUG

        if not vim.g.norsu then
            M.commands.exclusive(config)
        end

        vim.g.norsu = {
            wiki = dir,
            history = {},
            i = 0
        }

        autocmds.reindex(config)

        vim.defer_fn(function()
            vim.notify("Changed into Norsu wiki at " .. vim.g.norsu.wiki)
        end, 0)
    end
}

return M
