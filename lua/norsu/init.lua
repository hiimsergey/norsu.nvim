-- TODO NOW
-- markdown features:
--     basic link functionality:
--         hide brackets when leaving line
--         <enter> goes there
--     link autocomplete (with #headings)
--     table autocomplete
-- write commands:
--     list notes in this wiki (telescope)
--     list norsu commands (telescope)
--     view backlinks (telescope)
-- file cache:
--     where links are
--     backlinks
local vim = vim
local cmd = require "norsu.commands"

local M = {}

local function create_exclusive_commands()
    vim.api.nvim_create_user_command("NorsuNewFolder", cmd.NorsuNewFolder, { nargs = "?" })
    vim.api.nvim_create_user_command("NorsuNewNote", cmd.NorsuNewNote, { nargs = "?" })
end

local function create_ubiquitous_commands()
    -- TODO the preview window shows the last opened note
    vim.api.nvim_create_user_command("NorsuListWikis", cmd.NorsuOpenWiki, {})

    -- TODO CONSIDER NorsuOpenLast
end

M.config = {
    wikis = {}
}

M.setup = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        pattern = "*.no",
        callback = function()
            local cur_note_dir = vim.fn.expand "%:p:h"
            for _, wiki in pairs(config.wikis) do
                if vim.fn.expand(wiki.path) == cur_note_dir then
                    print "TODO starting norsu"
                    create_exclusive_commands()
                    break
                end
            end
        end
    })

    create_ubiquitous_commands()
end

return M
