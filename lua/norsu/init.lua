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

    local config = vim.api.tbl_deep_extend("force", conf, opts or {})
    local group = vim.api.nvim_create_augroup("Norsu", { clear = true })

    -- TODO NOW
    cmd.register_ubiquitous(config)

    -- TODO CONSIDER MOVE autocmds.lua
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        pattern = "*.no",

        --- Self-destructing autocommand. If the first file you open belongs to
        --- a Norsu wiki, then it enters automatically.
        callback = function()
            local bufname = vim.api.nvim_buf_get_name(0)
            local bufdir = bufname == "" and vim.uv.cwd() or vim.fs.dirname(bufname)

            if not vim.fs.relpath(config.root, bufdir) then goto del end
            local norsu_dir = vim.fs.find(".norsu", {
                path = bufdir,
                stop = config.root,
                type = "directory",
                upward = true
            })
            if next(norsu_dir) then
                vim.g.norsu = {
                    wiki = vim.fs.dirname(norsu_dir[1]),
                    history = {},
                    i = 0
                }

                cmd.register_exclusive(config) -- TODO NOW

                -- TODO CONSIDER MOVE autocmds.lua
                vim.api.nvim_create_autocmd("BufWritePost", {
                    group = group,
                    callback = function()
                        -- TODO PLAN
                        -- reindex:
                        -- find new links
                        -- CONSIDER unregistering exclusive commands on detecting
                        vim.cmd.quit()
                    end
                })

                vim.defer_fn(function()
                    vim.notify("Entered wiki " .. vim.g.norsu.wiki)
                end, 0)
            end

            ::del::
            vim.api.nvim_del_augroup_by_id(group)
        end
    })
end

return M
