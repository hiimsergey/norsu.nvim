-- TODO PLAN
-- test if auto-recognition works
-- :NorsuWiki (sets new wiki or prints cur one)
-- indexing
-- caching
-- rest: commands
-- GoBack, GoForward
-- Search
-- NorsuTagsShow, NorsuTagsRename
-- tree-sitter-norsu
-- NorsuQuery...
-- NorsuLatex...
-- NorsuExport
--      probably single command defined in the base plugin
--      side plugins just add targets, latex, typst, html, markdown, org, json
--      options
--          -all: treat a single note of all
--          -convert: if target is a src, then convert (e.g. latex -> pdf)
--          -opts string of a lua object of individual configs or something like that
--      maybe targets can be given aliases so you could have multiple html targets
-- all the other commands
local vim = vim
local act = require "norsu.actually"
local cmd = require "norsu.commands"
local conf = require "norsu.config"

local M = {}

--- Starting point of the norsu.nvim plugin.
--- @param opts? Config user's configuration
--- @see config.lua
M.setup = function(opts)
    -- TODO CONSIDER ADD own file for vim.g.norsu
    if vim.g.norsu then
        vim.notify(
            "norsu.nvim: Someone else already took over our namespace! Resigning...",
            vim.log.levels.ERROR
        )
        return
    end

    local config = vim.tbl_deep_extend("force", conf, opts or {})
    local group = vim.api.nvim_create_augroup("Norsu", { clear = true })

    -- TODO NOW
    cmd.register_ubiquitous(config)

    -- TODO CONSIDER MOVE autocmds.lua
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        pattern = "*.no",

        --- Self-destructing autocommand. If the first opened file belongs to
        --- a Norsu wiki, enter automatically.
        callback = function()
            local function destroy() vim.api.nvim_del_augroup_by_id(group) end

            local bufname = vim.api.nvim_buf_get_name(0)
            local bufdir = bufname == "" and vim.uv.cwd() or vim.fs.dirname(bufname)

            if not vim.fs.relpath(config.root, bufdir) then
                destroy()
                return
            end

            local norsu_dir = vim.fs.find(".norsu", {
                path = bufdir,
                stop = config.root,
                type = "directory",
                upward = true
            })
            if next(norsu_dir) then
                act.wiki(norsu_dir[1], config)
            end

            destroy()
        end
    })
end

return M
