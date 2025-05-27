local vim = vim

local config = require "norsu.config"

local M = {}

M.register_ubiquitous = function()
    --- Initialize the current working directory as a Norsu wiki by creating
    --- `.norsu.json` .
    local function Init()
        vim.uv.fs_open(".norsu.json", "w", 438, function(err_open, fd)
            if err_open then
                vim.defer_fn(function()
                    -- TODO NOW change every one to look like this
                    vim.notify(err_open, vim.log.levels.ERROR)
                end, 0)
                return
            end

            vim.uv.fs_write(
                fd,
[[
{
    "TODO": "what to put here?"
}
]],
                -1,
                function()
                    vim.uv.fs_close(fd, function(err_close)
                        if err_close then
                            vim.schedule_wrap(function()
                                vim.notify(
                                    "uv.fs_write: Failed to write to .norsu.json",
                                    vim.log.levels.ERROR
                                )
                            end)
                        end
                    end)
                end
            )
        end)

        -- TODO index without checking/crawling
        M.register_exclusive()

        local bufname = vim.api.nvim_buf_get_name(0)
        local bufdir = bufname == "" and vim.uv.cwd() or vim.fs.dirname(bufname)
        vim.notify(
            "Initialized new wiki at " .. bufdir,
            vim.log.levels.INFO
        )
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuInit", Init, {})
end

-- TODO ALL get completions
M.register_exclusive = function()
    --- Open the file switcher for the current wiki with a Telescope picker.
    --- @param opts OpenOpts
    --- @class OpenOpts
    --- @field args string just open the note at this path
    --- @field bang boolean create the note if the submitted path doesn't exist
    local function Open(opts)
        if opts.args == "" then
            -- TODO use picker
            print "NorsuOpen TODO no args :("
            return
        end

        if opts.args:sub(-3, -1) ~= ".no" then
            opts.args = opts.args .. ".no"
        end

        local note_relpath = config.entry_dir .. "/" .. opts.args
        local note_path = vim.b.norsu_root .. "/" .. note_relpath

        if not vim.uv.fs_stat(note_path) then
            if not opts.bang then
                vim.notify(
                    "No such file: " .. note_relpath .. " (use :NorsuOpen! to create)",
                    vim.log.levels.ERROR
                )
                return
            end

            local f = vim.uv.fs_open(note_path, "a", 420)
            if not f then
                vim.notify(
                    "uv.fs_open: Could not create file " .. note_relpath,
                    vim.log.levels.ERROR
                )
                return
            end

            vim.uv.fs_close(f)
            vim.notify("Created note " .. note_relpath, vim.log.levels.INFO)
            -- TODO add to index
        end

        vim.cmd.edit(note_path)
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuOpen", Open,
        { bang = true, nargs = "?" })

    --- Create a new folder in the wiki with a Telescope picker.
    --- @param opts NewFolderOpts
    --- @class NewFolderOpts
    --- @field args string just create the folder at this path
    local function NewFolder(opts)
        if opts.args == "" then
            -- TODO use picker
            print "TODO no args :("
            return
        end

        local cwd = vim.uv.cwd()
        local entries = {}
        local sep = package.config:sub(1, 1)

        for entry in string.gmatch(opts.args, "[^" .. sep .. "]+") do
            table.insert(entries, entry)
        end

        vim.uv.chdir(vim.b.norsu_root .. "/" .. config.entry_dir)
        for i = 1, #entries do
            local stat = vim.uv.fs_mkdir(entries[i], 493)
            if not stat then
                vim.uv.chdir(cwd)
                vim.notify(
                    "uv.fs_mkdir: Failed to create " .. entries[i],
                    vim.log.levels.ERROR
                )
                return
            end
            vim.uv.chdir(entries[i])
        end

        vim.notify("Made folder " .. opts.args, vim.log.levels.INFO)
        vim.uv.chdir(cwd)
        -- TODO add to index if necessary
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuNewFolder", NewFolder, { nargs = "?" })

    --- Move the currently open note to another folder with a Telescope picker.
    --- @param opts MoveOpts
    --- @class MoveOpts
    --- @field args string just move the note into this path
    local function Move(opts)
        if opts.args == "" then
            -- TODO use picker
            vim.notify "TODO no args :("
            return
        end

        local abspath = vim.b.norsu_root .. "/" .. opts.args
        local relpath = vim.fs.relpath(vim.b.norsu_root, abspath)

        -- Ensure the destination exists
        local stat = vim.uv.fs_stat(abspath)
        if not stat then
            vim.notify(
                opts.args .. " doesn't exist",
                vim.log.levels.ERROR
            )
            return
        end
        if stat.type ~= "directory" then
            vim.notify(
                opts.args .. " is not a folder",
                vim.log.levels.ERROR
            )
            return
        end

        -- Prevent moving outside the wiki
        if not relpath then
            -- TODO TEST
            vim.notify(
                opts.args .. " is not a wiki subpath",
                vim.log.levels.ERROR
            )
            return
        end

        -- TODO TEST overwriting
        local bufname = vim.api.nvim_buf_get_name(0)
        local bufrelpath = vim.fs.relpath(vim.b.norsu_root, bufname)
        local bufbasename = vim.fs.basename(bufname)

        stat = vim.uv.fs_rename(bufname, abspath .. "/" .. bufbasename)
        if not stat then
            vim.notify(
                "uv.fs_rename: Failed to move " .. bufrelpath .. " to " .. relpath,
                vim.log.levels.ERROR
            )
            return
        end

        vim.notify(
            bufrelpath .. " -> " .. abspath .. "/" .. bufbasename,
            vim.log.levels.INFO
        )
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuMove", Move, { nargs = "?" })

    --- Delete notes and folders using a Telescope picker.
    --- Use `<Tab>` to select items and `<CR>` to submit.
    --- @param opts DeleteOpts
    --- @class DeleteOpts
    --- @field args string only delete the entry at this path.
    ---                    `%` resolves to the currently open note.
    --- @field bang boolean skip confirmation dialog
    local function Delete(opts)
        local paths = {}
        local ghosts = {}
        local foreigners = {}
        local succesful = 0
        local numerus = #paths == 1 and " entry" or " entries"

        local function actually_delete()
            for _, path in ipairs(paths) do
                vim.fs.rm(path, { recursive = true })
                succesful = succesful + 1
            end

            local errmsg = ""
            if #ghosts > 0 then
                errmsg = errmsg .. "NorsuDelete: No such files or directories:\n"
                for _, path in ipairs(ghosts) do
                    errmsg = errmsg .. "        " .. path .. "\n"
                end
            end
            if #foreigners > 0 then
                errmsg = errmsg .. "NorsuDelete: File or directories outside the wiki:\n"
                for _, path in ipairs(foreigners) do
                    errmsg = errmsg .. "        " .. path .. "\n"
                end
            end

            -- TODO TEST
            vim.schedule_wrap(function() -- TODO DEBUG
                vim.api.nvim_echo({{ errmsg }}, errmsg == "", { err = true })
            end)
            vim.notify("Deleted " .. succesful .. numerus, vim.log.levels.INFO)
        end

        if opts.args == "" then
            vim.notify "TODO NorsuDelete no picker? :("
            return
        else
            paths = { opts.args }
        end

        for i = 1, #paths do
            local abspath = paths[i] == "%" and
                vim.api.nvim_buf_get_name(0) or
                vim.b.norsu_root .. "/" .. paths[i]

            if not vim.uv.fs_stat(abspath) then
                table.insert(ghosts, paths[i])
            end

            local relpath = vim.fs.relpath(vim.b.norsu_root, abspath)
            if not relpath then
                table.insert(foreigners, paths[i])
            end

            paths[i] = abspath
        end

        if opts.bang then
            vim.ui.input(
                { prompt =
                    "Do you want to delete " .. #paths .. numerus .. " [y/N] "
                },
                function(input)
                    if not (input and input:lower() == "y") then
                        vim.notify(
                            "Deletion aborted",
                            vim.log.levels.INFO
                        )
                        return
                    end
                    actually_delete()
                end
            )
            return
        end
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuDelete", Delete,
        { bang = true, nargs = "?" })
end

return M
