-- TODO NOW
-- MOVE both command namespaces to norsu.util
-- FINISH NorsuWiki
--
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
local conf = require "norsu.config"
local util = require "norsu.util"

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

    util.commands.ubiquitous(config)

    local group = vim.api.nvim_create_augroup("NorsuAutoWiki", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,

        --- Self-destructing autocommand. If the first opened file belongs to
        --- a Norsu wiki, enter automatically.
        callback = function()
            local function destroy() vim.api.nvim_del_augroup_by_id(group) end

            local wiki_path = util.get_wiki_path(vim.uv.cwd(), config)
            if not wiki_path then
                destroy()
                return
            end

            util.actually.wiki(wiki_path, config)
            destroy()
        end
    })
end

return M
