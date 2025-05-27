-- TODO
-- NOW
-- Move
-- Delete
-- test all
--
-- markdown features:
--     basic link functionality:
--         hide brackets when leaving line
--         <enter> goes there
--     link autocomplete (with #headings)
--     table autocomplete
-- write commands:
--     list notes in this wiki (telescope)
--     list norsu commands (telescope)
--     view backlinks (telescope)
-- file cache:
--     where links are
--     backlinks
-- CONSIDER?? access your wiki from anywhere
-- FINAl
-- help pages
-- set filetype in lualine
-- norsu-export: pdf, html, markdown
-- REPLACE .norsu.json with .norsu/ if necessary
-- elegant way to make lua_ls shut up about "local vim = vim"
-- CONSIDER making a norsu-no-treesitter plugin that does everything the vimwiki way
-- FINAL ALL CHECK all pickers are abortable
local vim = vim

local cmd = require "norsu.commands"
local config = require "norsu.config"
local group = vim.api.nvim_create_augroup("Norsu", { clear = true })

local M = {}

--- Starting point of the norsu.nvim plugin.
--- @param opts? Config user's configuration
--- @see config.lua
M.setup = function(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        group = group,
        callback = function()
            local cwd = vim.uv.cwd()
            if type(config.entry_dir) == "function" then
                config.entry_dir = config.entry_dir()
            end

            -- Abort indexing if opened file is outside wikis root
            if not vim.fs.relpath(config.root, cwd) then return end

            -- TODO ADD cache
            local norsu_json = vim.fs.find(".norsu.json", {
                upward = true,
                path = cwd,
                stop = config.root
            })
            if not next(norsu_json) then return end
            vim.b.norsu_root = vim.fs.dirname(norsu_json[1])

            cmd.register_exclusive(config)

            vim.api.nvim_create_autocmd("BufWritePost", {
                buffer = 0,
                group = group,
                callback = function()
                    -- TODO PLAN
                    -- reindex:
                    -- find new links
                    -- CONSIDER unregistering exclusive commands on detecting
                    -- .norsu.json missing. maybe there is an io-related signal
                    vim.cmd.quit()
                end
            })
        end
    })

    cmd.register_ubiquitous(config)
end

return M
