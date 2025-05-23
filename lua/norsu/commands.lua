local vim = vim

local actions = require "telescope.actions"
local conf = require "telescope.config".values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"

local M = {}

M.register_exclusive = function()
    vim.api.nvim_buf_create_user_command(0, "NorsuOpen", function(opts)
        if opts.args == "" then
            -- TODO use picker
            print "NorsuOpen TODO no args :("
            return
        end

        if opts.args:sub(-3, -1) ~= ".no" then
            opts.args = opts.args .. ".no"
        end

        if not vim.uv.fs_stat(opts.args) then
            if not opts.bang then
                vim.notify(
                    "No such file: " .. opts.args .. " (use :NorsuOpen! to create)",
                    vim.log.levels.ERROR
                )
                return
            end

            local f = io.open(opts.args, "w")
            if not f then
                vim.notify("io.open: Could not create file " .. opts.args, vim.log.levels.ERROR)
                return
            end
            vim.notify("Created note " .. opts.args, vim.log.levels.INFO)
            f:close()
        end
        vim.cmd.edit(vim.b.wiki_root .. "/" .. opts.args)
    end, { bang = true, nargs = "?" })

    vim.api.nvim_buf_create_user_command(0, "NorsuNewFolder", function(opts)
        if opts.args == "" then
            -- TODO use picker
            print "TODO no args :("
            return
        end

        vim.fn.mkdir(vim.b.wiki_root .. "/" .. opts.args, "p")
        vim.notify("Made folder " .. opts.args, vim.log.levels.INFO)
    end, { nargs = "?" })

    -- TODO
    vim.api.nvim_buf_create_user_command(0, "NorsuMove", function(opts)
        if opts.args == "" then
            -- TODO use picker
            print "TODO no args :("
            return
        end

        opts.args = vim.split(opts.args, " ", { trimempty = true })

        --[[ TODO PLAN
        {entry} dest
            dest dont exist -> error
            dest no dir -> error
            for every entry:
                exists -> move
                else -> add name to list
            list not empty -> multi-line error
        --]]
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
    end, { nargs = "*" })
end

M.register_ubiquitous = function()
    vim.api.nvim_buf_create_user_command(0, "NorsuInit", function()
        -- TODO replace { "hello", "world" } with .norsu.json template
        vim.fn.writefile({ "hello", "world" }, ".norsu.json")
        -- TODO index without checking/crawling
        vim.notify("Initialized new wiki at " .. vim.fn.expand "%:p:h", vim.log.levels.INFO)
    end, {})

    -- TODO CONSIDER! REMOVE
    vim.api.nvim_buf_create_user_command(0, "NorsuOpenWiki", function(opts)
        -- TODO handle args
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
    end, { nargs = "?" })
end

return M
