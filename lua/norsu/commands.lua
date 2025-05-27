local vim = vim

local config = require "norsu.config"

local M = {}

M.register_ubiquitous = function()
    -- TODO dont let it overwrite an existing wiki
    --- Initialize the current working directory as a Norsu wiki by creating
    --- `.norsu.json` .
    local function Init()
        local fd, err_open = vim.uv.fs_open(".norsu.json", "w", 438)
        if not fd then
            vim.notify(err_open, vim.log.levels.ERROR)
            return
        end

        local ok, err_write = vim.uv.fs_write(
            fd,
[[{
    "TODO": "what to put here?"
}]],
            -1
        )
        vim.uv.fs_close(fd)

        if not ok then
            vim.notify(err_write, vim.log.levels.ERROR)
            return
        end

        -- TODO index without checking/crawling
        M.register_exclusive()

        local bufname = vim.api.nvim_buf_get_name(0)
        local bufdir = bufname == "" and vim.uv.cwd() or vim.fs.dirname(bufname)

        vim.b.norsu_root = bufdir -- TODO CONSIDER
        vim.notify("New Norsu wiki at " .. bufdir, vim.log.levels.INFO)
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

        if opts.args:sub(-3, -1) ~= ".no" then opts.args = opts.args .. ".no" end

        local abspath = vim.b.norsu_root .. "/" .. config.entry_dir .. "/" .. opts.args
        local relpath = vim.fs.relpath(vim.b.norsu_root, abspath)

        -- Ensure the destination exists
        if not relpath then
            vim.notify("Not a wiki subpath: " .. opts.args, vim.log.levels.ERROR)
            return
        end

        if not vim.uv.fs_stat(abspath) then
            if not opts.bang then
                vim.notify(
                    "No such file: " .. relpath .. " (use :NorsuOpen! to create)",
                    vim.log.levels.ERROR
                )
                return
            end

            local fd, err = vim.uv.fs_open(abspath, "a", 420)
            if not fd then
                vim.notify(err, vim.log.levels.ERROR)
                return
            end
            vim.uv.fs_close(fd)

            vim.notify("Created note " .. relpath, vim.log.levels.INFO)
            -- TODO add to index
        end

        vim.cmd.edit(abspath)
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
            local ok, err_mkdir = vim.uv.fs_mkdir(entries[i], 493)
            if not ok then
                vim.notify(err_mkdir, vim.log.levels.ERROR)
                vim.uv.chdir(cwd)
                return
            end
            vim.uv.chdir(entries[i])
        end

        vim.uv.chdir(cwd)
        vim.notify("Made folder " .. opts.args, vim.log.levels.INFO)
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
            vim.notify("No such folder: " .. opts.args, vim.log.levels.ERROR)
            return
        end
        if stat.type ~= "directory" then
            vim.notify("Not a folder: " .. opts.args, vim.log.levels.ERROR)
            return
        end

        -- Prevent moving outside the wiki
        if not relpath then
            -- TODO TEST
            vim.notify("Not a wiki subpath: " .. opts.args, vim.log.levels.ERROR)
            return
        end

        -- TODO TEST overwriting
        local bufname = vim.api.nvim_buf_get_name(0)
        local bufrelpath = vim.fs.relpath(vim.b.norsu_root, bufname)
        local bufbasename = vim.fs.basename(bufname)

        local ok, err_rename = vim.uv.fs_rename(bufname, abspath .. "/" .. bufbasename)
        if not ok then
            vim.notify(err_rename, vim.log.levels.ERROR)
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

        -- TODO CONSIDER support "foobar" instead of only "foobar.no"

        if opts.args == "" then
            vim.notify "TODO NorsuDelete no picker? :("
            return
        else
            paths = { opts.args }
        end

        -- TODO close buffers of deleted notes
        -- use the proposed O(n + m) solution
        for i = #paths, 1, -1 do
            local abspath = paths[i] == "%" and
                vim.api.nvim_buf_get_name(0) or
                vim.b.norsu_root .. "/" .. paths[i]

            if not vim.uv.fs_stat(abspath) then
                table.insert(ghosts, table.remove(paths, i))
                goto continue
            end

            local relpath = vim.fs.relpath(vim.b.norsu_root, abspath)
            if not relpath then
                table.insert(foreigners, table.remove(paths, i))
                goto continue
            end

            paths[i] = abspath
            ::continue::
        end

        local numerus = #paths == 1 and " entry" or " entries"
        local function actually_delete()
            for _, path in ipairs(paths) do
                vim.fs.rm(path, { recursive = true })
            end

            local errmsg = ""
            if #ghosts > 0 then
                errmsg = errmsg .. "NorsuDelete: No such files or folders:"
                for _, path in ipairs(ghosts) do
                    errmsg = errmsg .. "\n    " .. path
                end
            end
            if #foreigners > 0 then
                errmsg = errmsg .. "\nNorsuDelete: Files or folders outside the wiki:"
                for _, path in ipairs(foreigners) do
                    errmsg = errmsg .. "\n    " .. path
                end
            end

            vim.api.nvim_echo({{ errmsg }}, errmsg ~= "", { err = true })
            if #paths > 0 then
                vim.defer_fn(function()
                    vim.notify(
                        "Deleted " .. #paths .. numerus,
                        vim.log.levels.INFO
                    )
                end, 0)
            end
        end

        if not opts.bang then
            vim.ui.input(
                { prompt =
                    "Do you want to delete " .. #paths .. numerus .. " [y/N] "
                },
                function(input)
                    if not (
                        input and
                        (input:lower() == "y" or input:lower() == "yes")
                    ) then
                        vim.defer_fn(function()
                            vim.notify("Deletion aborted", vim.log.levels.INFO)
                        end, 0)
                        return
                    end
                    actually_delete()
                end
            )
            return
        end

        actually_delete()
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuDelete", Delete,
        { bang = true, nargs = "?" })
end

return M
