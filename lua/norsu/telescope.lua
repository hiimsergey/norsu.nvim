local M = {}

M.list_wikis = function(config)
    local actions = require "telescope.actions"
    local conf = require("telescope.config").values
    local finders = require "telescope.finders"
    local pickers = require "telescope.pickers"

    pickers.new({}, {
        prompt_title = "Norsu Wikis",
        finder = finders.new_table {
            -- TODO PLACEHOLDER
            results = config.wikis
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
end

return M
