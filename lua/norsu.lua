local M = {}

local function list_wikis_telescope()
    local actions = require "telescope.actions"
    local conf = require("telescope.config").values
    local finders = require "telescope.finders"
    local pickers = require "telescope.pickers"

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
end

M.config = {
    wikis = {},
    list_wikis_func = list_wikis_telescope
}

function M.setup(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    pattern = "*.md",
    callback = function(_)
        print(vim.fn.expand("%:p:h"))
    end
})

-- TODO the preview window shows the last opened note
vim.api.nvim_create_user_command("NorsuListWikis", M.config.list_wikis_func, {})

-- TODO only make it availble if the pwd is the wiki
vim.api.nvim_create_user_command("NorsuNewFolder", function(opts)
    if opts.args == "" then
        opts.args = vim.fn.input("Enter new folder name: ")
    end
    -- TODO PLAN
    -- create folder
end, { nargs = "?" })

-- TODO only make it availble if the pwd is the wiki
vim.api.nvim_create_user_command("NorsuNewNote", function(opts)
    if opts.args == "" then
        opts.args = vim.fn.input("Enter new note name: ")
    end
    -- TODO PLAN
    -- vim.cmd.edit(WIKI_PATH .. opts.args)
    -- reindex
end, { nargs = "?" })

return M
