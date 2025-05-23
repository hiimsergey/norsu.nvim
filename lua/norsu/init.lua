-- TODO NOW
-- CONSIDER option
--     NorsuOpen! always creates in root (like obsidian) vs creates in pwd
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
local vim = vim

local cmd = require "norsu.commands"
local group = vim.api.nvim_create_augroup("Norsu", { clear = true })

local M = {}

M.config = {
    -- Deepest directory containing all detectable wikis on the system.
    -- The wiki indexing algorithm stops crawling here.
    -- All wikis outside the root will not be indexed.
    root = vim.fn.expand "~"
}

M.setup = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        group = group,
        callback = function()
            -- Abort indexing if opened file is outside wikis root
            local dir = vim.fn.expand "%:p:h"
            if dir:sub(1, #M.config.root) ~= M.config.root then return end

            -- TODO ADD cache
            while true do
                local candidate = dir .. "/.norsu.json"
                if vim.fn.filereadable(candidate) == 1 then
                    vim.b.wiki_root = dir
                    break
                end

                if dir == M.config.root then return end
                dir = vim.fn.fnamemodify(dir, ":h")
            end

            cmd.register_exclusive()

            vim.api.nvim_create_autocmd("BufWritePost", {
                buffer = 0,
                group = group,
                callback = function()
                    -- TODO PLAN
                    -- reindex:
                    -- find new links
                    vim.cmd.quit()
                end
            })
        end
    })

    cmd.register_ubiquitous()
end

return M
