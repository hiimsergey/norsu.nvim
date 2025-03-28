-- TODO NOW
-- write commands:
--     list notes in this wiki (telescope)
--     list norsu commands (telescope)
--     view backlinks (telescope)
-- file cache:
--     where links are
--     backlinks
-- autocomplete:
--     note links
-- table autocomplete
local vim = vim
local M = {}

local function list_wikis_telescope(config)
    local actions = require "telescope.actions"
    local conf = require("telescope.config").values
    local finders = require "telescope.finders"
    local pickers = require "telescope.pickers"

    pickers.new({}, {
        prompt_title = "Norsu Wikis",
        finder = finders.new_table {
            -- TODO PLACEHOLDER
            results = config.wikis
        },
        sorter = conf.generic_sorter(),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                -- TODO make it do something
            end)
            return true
        end
    }):find()
end

local function create_exclusive_commands()
    -- TODO only make it availble if the pwd is the wiki
    vim.api.nvim_create_user_command("NorsuNewFolder", function(opts)
        if opts.args == "" then
            opts.args = vim.fn.input("Enter new folder name: ")
        end
        -- TODO PLAN
        -- create folder
        print("about to mkdir " .. opts.args)
    end, { nargs = "?" })

    -- TODO only make it availble if the pwd is the wiki
    vim.api.nvim_create_user_command("NorsuNewNote", function(opts)
        if opts.args == "" then
            opts.args = vim.fn.input("Enter new note name: ")
        end
        -- TODO PLAN
        -- vim.cmd.edit(WIKI_PATH .. opts.args)
        -- reindex
        print("about to make note" .. opts.args)
    end, { nargs = "?" })
end

local function create_ubiquitous_commands()
    -- TODO the preview window shows the last opened note
    vim.api.nvim_create_user_command("NorsuListWikis", function()
        M.config.list_wikis_cb(M.config)
    end, {})

    -- TODO CONSIDER NorsuOpenLast
end

M.config = {
    wikis = {},
    list_wikis_cb = list_wikis_telescope
}

M.setup = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        pattern = "*.md",
        callback = function()
            local cur_note_dir = vim.fn.expand "%:p:h"
            for _, wiki in pairs(config.wikis) do
                if vim.fn.expand(wiki.path) == cur_note_dir then
                    create_exclusive_commands()
                    break
                end
            end
            create_ubiquitous_commands()
        end
    })
end

return M
