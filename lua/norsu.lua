local M = {}

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"

-- TODO the preview window shows the last opened note
vim.api.nvim_create_user_command("NorsuListWikis", function()
    pickers.new({}, {
        prompt_title = "Norsu Wikis",
        finder = finders.new_table {
            -- TODO PLACEHOLDER
            results = { "one", "two", "three" }
        },
        sorter = conf.generic_sorter(),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                -- TODO make it do something
            end)
            return true
        end
    }):find()
end, {})

return M
