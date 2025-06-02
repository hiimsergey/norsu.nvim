-- TODO
-- markdown features:
--     basic link functionality:
--         hide brackets when leaving line
--         <enter> goes there
--     link autocomplete (with #headings)
--     table autocomplete
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
local conf = require "norsu.config"

--- Determines whether a given path is a subpath of a Norsu wiki. Returns the
--- wiki path if so, otherwise nil.
--- @param path string dirpath of the currently open file
--- @param config Config user's configuration
--- @return string? path absolute path of wiki or nil if note not in a wiki
local function get_wiki_path(path, config)
    local norsu_json = vim.fs.find(".norsu.json", {
        upward = true,
        path = path,
        stop = config.root
    })
    return next(norsu_json) and vim.fs.dirname(norsu_json[1]) or nil
end

-- TODO notify when entering and leaving wikis
-- TODO NOTE indexing
-- for every .no file get
-- name
-- size
-- tags
-- outlinks
-- backlinks
-- atime
-- mtime
-- (some of these can be inferred instead of explicitly saved)
local M = {}

--- Starting point of the norsu.nvim plugin.
--- @param opts? Config user's configuration
--- @see config.lua
M.setup = function(opts)
    if vim.w.norsu then
        vim.notify(
            "norsu.nvim: Someone else already took our namespace! Resigning...",
            vim.log.levels.ERROR
        )
        return
    end

    local group = vim.api.nvim_create_augroup("Norsu", { clear = true })

    local config = vim.tbl_deep_extend("force", conf, opts or {})
    if type(config.entry_dir) == "function" then
        config.entry_dir = config.entry_dir()
    end

    cmd.register_ubiquitous(config)

    -- TODO NOW switch to command-based checking
    -- note validity is checked in user commands, not autocmds
    -- use a one-off (self deleting (using groups)) autocmd checking for the wiki in this file,
    -- all other ones need to be set with :NorsuWiki
    -- :NorsuWiki prints current wiki
    -- :NorsuWiki /path/to/wiki checks if it or a superdir is a valid wiki and sets it
    -- :NorsuWiki % same for this note
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function()
            local bufname = vim.api.nvim_buf_get_name(0)
            local bufdir = bufname == "" and vim.uv.cwd() or vim.fs.dirname(bufname)

            if vim.w.norsu then
                if not vim.fs.relpath(config.root, bufdir) then return end

                local new_wiki_path = get_wiki_path(bufdir, config)
                if not new_wiki_path then
                    local left_wiki = vim.w.norsu.root
                    vim.defer_fn(function()
                        vim.notify("Left wiki " .. left_wiki)
                    end, 0)

                    vim.w.norsu = nil
                    return
                end

                if vim.w.norsu.root ~= new_wiki_path then
                    vim.w.norsu.root = new_wiki_path
                    vim.defer_fn(function()
                        vim.notify("Entered wiki " .. new_wiki_path)
                    end, 0)
                end
                return
            end

            -- Abort indexing if opened file is outside wikis root
            if not vim.fs.relpath(config.root, bufdir) then return end

            -- TODO ADD cache
            local wiki_path = get_wiki_path(bufdir, config)
            if not wiki_path then return end

            -- TODO TEST
            -- switching panes
            -- opening notes with NorsuOpen
            -- opening with :edit
            -- Where indexing starts
            -- TODO TYPE annotate
            vim.w.norsu = {
                root = wiki_path,
                history = {},
                i = 0
            }

            cmd.register_exclusive(config)

            vim.api.nvim_create_autocmd("BufWritePost", {
                buffer = 0,
                group = group,
                callback = function()
                    -- TODO PLAN
                    -- reindex:
                    -- find new links
                    -- CONSIDER unregistering exclusive commands on detecting
                    vim.cmd.quit()
                end
            })

            vim.defer_fn(function() vim.notify("Entered wiki " .. wiki_path) end, 0)
        end
    })
end

return M
