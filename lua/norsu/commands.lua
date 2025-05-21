local actions = require "telescope.actions"
local conf = require "telescope.config".values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"

local vim = vim
local M = {}

M.NorsuNewNote = function(opts)
    if opts.args == "" then
        opts.args = vim.fn.input("Enter new note name: ")
    end
    -- TODO PLAN
    -- vim.cmd.edit(WIKI_PATH .. opts.args)
    -- reindex
    print("about to make note" .. opts.args)
end

M.NorsuNewFolder = function(opts)
    if opts.args == "" then
        opts.args = vim.fn.input("Enter new folder name: ")
    end
    -- TODO PLAN
    -- create folder
    print("TODO about to mkdir " .. opts.args)
end

-- TODO NOW MOVE picker to abstraction
M.NorsuOpenWiki = function(opts)
    print "TODO listing wikis"

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

return M
