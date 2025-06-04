local vim = vim
local util = require "norsu.util"

local M = {}
local group = vim.api.nvim_create_augroup("Norsu", { clear = true })

--- Self-destructing autocommand. If the first opened file belongs to
--- a Norsu wiki, enter automatically.
--- @param config Config plugin configuration
M.auto_enter_wiki = function(config)
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        -- TODO NOW DEBUG doesnt run on empty buffers

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

--- Incrementally alter the wiki index after saving.
--- @param config Config plugin configuration
M.reindex = function(config)
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        callback = function()
            -- TODO PLAN
            -- reindex:
            -- find new links
            vim.cmd.quit()
        end
    })
end

return M
