local vim = vim

local config = require "norsu.config"

local M = {}

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
                    "io.open: Could not create file " .. note_relpath,
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

    --- Creates a new folder in the wiki with a Telescope picker.
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
    vim.api.nvim_buf_create_user_command(0, "NorsuNewFolder", NewFolder,
        { nargs = "?" })

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

        local stat = vim.uv.fs_stat(opts.args)
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

        -- TODO prevent moving outside the wiki

        -- TODO CONSIDER keeping it with relative paths instead of root-centric paths
        local bufname = vim.api.nvim_buf_get_name(0)
        local basename = vim.fs.basename(bufname)
        -- TODO TEST overwriting
        stat = vim.uv.fs_rename(bufname, opts.args .. "/" .. basename)
        if not stat then
            vim.notify(
                "uv.fs_rename: Failed to move " .. basename .. " to " .. opts.args,
                vim.log.levels.ERROR
            )
            return
        end

        vim.notify(
            basename .. " -> " .. opts.args .. "/" .. basename,
            vim.log.levels.INFO
        )
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuMove", Move,
        { nargs = "?" })

    --- Delete notes and folders using a Telescope picker.
    --- Use `<Tab>` to select items and `<CR>` to submit.
    --- @param opts DeleteOpts
    --- @class DeleteOpts
    --- @field args string only delete the entry at this path.
    ---                    % resolves to the currently open note.
    --- @field bang boolean skip confirmation dialog
    local function Delete(opts)
        -- show number of files in dir if no bang

        if opts.args == "" then
            -- TODO CONSIDER C-a to select all
            -- TODO handle bang
            -- TODO NOTE multi select telescope picker
            vim.notify "TODO NorsuDelete no picker? :("
            return
        end

        local abspath = vim.b.norsu_root .. "/" .. opts.args
        local relpath = vim.fs.relpath(vim.b.norsu_root, abspath)

        -- Handle paths outside the wiki
        if not relpath then
            vim.notify "TODO not a subpath >:("
            return
        end

        if opts.args == "%" then
            opts.args = vim.api.nvim_buf_get_name(0)
        end

        if opts.bang then
            vim.ui.input(
                { prompt = "Do you want to delete " .. relpath .. "? [y/N] " },
                function(input)
                    if not (input and input:lower() == "y") then
                        vim.notify "TODO Delte aboreted"
                        return
                    end
                end
            )
        end

        -- TODO CONSIDER deleting multiple files
        -- TODO CHECK handle nonexistent files
        vim.fs.rm(abspath, { recursive = true })
        vim.notify("Deleted " .. relpath)
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuDelete", Delete,
        { bang = true, nargs = "?" })
end

M.register_ubiquitous = function()
    -- TODO FINAL CHECK if .norsu.json is the only thing needed
    --- Initialize the current working directory as a Norsu wiki by creating
    --- `.norsu.json` .
    local function Init()
        vim.uv.fs_open(".norsu.json", 438, function(err, fd)
            if err then
                vim.notify "uv.fs_open: Failed to open .norsu.json"
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
                    vim.uf.fs_close(fd, function()
                        vim.notify "us.fs_write: Failed to write to .norsu.json"
                    end)
                end
            )
        end)

        -- TODO index without checking/crawling
        -- TODO TEST
        vim.fn.writefile({ "register_exclusive" }, "/home/sergey/downloads/norsuvault/msg")
        M.register_exclusive()

        vim.notify(
            "Initialized new wiki at " .. vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
            vim.log.levels.INFO
        )
    end
    vim.api.nvim_buf_create_user_command(0, "NorsuInit", Init, {})
end

return M
