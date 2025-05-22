local vim = vim
local actions = require "telescope.actions"
local conf = require "telescope.config".values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"

local ctx = require "norsu.context"

local M = {}

-- TODO NOW
-- where to store ctx variables (current wiki)
-- write the picker
-- vim.cmd.edit command
-- log msg
M.NorsuNewNote = function(opts)
    if opts.args == "" then
        -- TODO use picker
        print "TODO no args :("
        return
    end

    if opts.args:sub(-3, -1) ~= ".no" then
        opts.args = opts.args .. ".no"
        -- TODO NOW
    end

    vim.cmd.edit(ctx.cur_wiki .. opts.args)
end

M.NorsuNewFolder = function(opts)
    if opts.args == "" then
        -- TODO use picker
        print "TODO no args :("
        return
    end

    vim.fn.mkdir(ctx.cur_wiki .. opts.args)
    vim.notify("Norsu: Made folder " .. opts.args, vim.log.levels.INFO)
end

-- TODO
M.NorsuMove = function(opts)
    if opts.args == "" then
        -- TODO use picker
        print "TODO no args :("
        return
    end

    opts.args = vim.split(opts.args, " ", { trimempty = true })

    local dest = opts.args[#opts.args]
    if not vim.uv.fs_stat(dest) then
        print(dest .. " doesnt exist :( TODO")
        return
    end

    -- TODO PLAN
    -- if there is only arg the src file is the currently open one
    for i = 1, #opts.args - 1 do
        -- TODO PLAN
        -- move opts.args[i] to dest
        if not vim.fn.isabsolute(opts.args[i]) then
            opts.args[i] = ctx.cur_wiki .. opts.args[i]
        end
        vim.uv.fs_rename(opts.args[i], dest .. opts.args[i])
    end
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

    -- TODO PLAN
    -- open the latest note of selected wiki
    -- a simple vim.cmd.edit will suffice
end

return M
