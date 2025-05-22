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
-- FINAl
-- help pages
-- set filetype in lualine
local vim = vim
local cmd = require "norsu.commands"
local ctx = require "norsu.context"

local M = {}

local function create_exclusive_commands()
    vim.api.nvim_create_user_command("NorsuNewNote", cmd.NorsuNewNote, { nargs = "?" })
    vim.api.nvim_create_user_command("NorsuNewFolder", cmd.NorsuNewFolder, { nargs = "?" })
    vim.api.nvim_create_user_command("NorsuMove", cmd.NorsuMove, { nargs = "*" })
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
        callback = function()
            local cur_note_dir = vim.fn.expand "%:p:h"
            for _, wiki in pairs(config.wikis) do
                local wiki_path_abs = vim.fn.expand(wiki.path)
                if cur_note_dir:sub(1, #wiki_path_abs) == wiki_path_abs then
                    ctx.cur_wiki = wiki_path_abs .. "/"
                    create_exclusive_commands()
                    -- TODO CONSIDER register autocmd
                    -- update last opened note in this wiki
                    -- reindex on save:
                    --    update list of notes
                    --    update links
                    break
                end
            end
        end
    })

    create_ubiquitous_commands()
end

return M
