local vim = vim

local config = require "norsu.config"

local M = {}

-- TODO FINAL ALL ADD desc to commands
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

        local dir = type(config.new_notes_dir) == "function" and
            config.new_notes_dir() or
            config.new_notes_dir
        local note_relpath = dir .. "/" .. opts.args
        local note_path = vim.b.norsu_root .. "/" .. note_relpath

        if not vim.uv.fs_stat(note_path) then
            if not opts.bang then
                vim.notify(
                    "No such file: " .. note_relpath .. " (use :NorsuOpen! to create)",
                    vim.log.levels.ERROR
                )
                return
            end

            local f = io.open(note_path, "w")
            if not f then
                vim.notify(
                    "io.open: Could not create file " .. note_relpath,
                    vim.log.levels.ERROR
                )
                return
            end

            f:close()
            vim.notify("Created note " .. note_relpath, vim.log.levels.INFO)
            -- TODO add to index
        end

        vim.cmd.edit(note_path)
    end, { bang = true, nargs = "?" })

    vim.api.nvim_buf_create_user_command(0, "NorsuNewFolder", function(opts)
        if opts.args == "" then
            -- TODO use picker
            print "TODO no args :("
            return
        end

        vim.fn.mkdir(vim.b.norsu_root .. "/" .. opts.args, "p")
        vim.notify("Made folder " .. opts.args, vim.log.levels.INFO)
        -- TODO add to index if necessary
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

    -- TODO
    vim.api.nvim_buf_create_user_command(0, "NorsuDelete", function(opts)
        vim.notify(opts.bang and "TODO doing crazy deletion" or "TODO asking you to delete")
        -- TODO handle no currently open file
    end, { bang = true, nargs = "?" })
end

M.register_ubiquitous = function()
    vim.api.nvim_buf_create_user_command(0, "NorsuInit", function()
        -- TODO replace { "hello", "world" } with .norsu.json template
        vim.fn.writefile({ "hello", "world" }, ".norsu.json")
        -- TODO index without checking/crawling
        vim.notify(
            "Initialized new wiki at " .. vim.fn.expand "%:p:h",
            vim.log.levels.INFO
        )
    end, {})
end

return M
