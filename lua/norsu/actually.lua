local vim = vim
local cmd = require "norsu.commands"

local M = {}

M.wiki = function(dir, config)
    vim.g.norsu = {
        wiki = vim.fs.dirname(dir),
        history = {},
        i = 0
    }

    cmd.register_exclusive(config) -- TODO NOW

    -- TODO CONSIDER MOVE autocmds.lua
    vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
            -- TODO PLAN
            -- reindex:
            -- find new links
            -- CONSIDER unregistering exclusive commands on detecting
            vim.cmd.quit()
        end
    })

    vim.defer_fn(function()
        vim.notify("Entered wiki " .. vim.g.norsu.wiki)
    end, 0)
end

return M
