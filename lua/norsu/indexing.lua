local vim = vim

-- TODO NOW
-- indexing
--      after actually.wiki()
--          x decompress the cache
--          x then glob all .no files
--          ? compare hashes
--          ? update entries if necessary
--      after saving
--          compare ts trees
--          update entry if necessary
--      before closing nvim
--          compress index
-- TODO

--- @class Index
--- @field notes table<string, Note>
---     Hashmap with relative note path as input and note metadata as `Note` as
---     output
--- @field tags table<string, string[]>
---     Hashmap with tag name/path as input and list of relative paths of member notes
---     as output
local Index = {}
Index.__index = Index

--- Loads cached index for the current wiki, if present.
--- @return Index? cache found cache
local function load_cache()
    local cache_path = vim.fn.stdpath "state" .. "/norsu/cache.mpack"

    local stat = vim.uv.fs_stat(cache_path)
    if not stat then return {} end

    local fd = vim.uv.fs_open(cache_path, "r", 438)
    if not fd then return {} end

    local data = vim.uv.fs_read(fd, stat.size, 0)
    vim.uv.fs_close(fd)

    if not data then return {} end

    local ok, cache = pcall(vim.mpack.decode, data)
    if not ok or type(cache) ~= "table" then return {} end

    vim.g.norsu.index = {}
    return cache or {}
end

--- TODO COMMENT
--- @param index Index index in construction
local function iterate_notes(index)
    local function scan(path, ind)
        local handle = vim.uv.fs_scandir(path)
        if not handle then return end

        while true do
            local name, type = vim.uv.fs_scandir_next(handle)
            if not name then break end

            local subpath = path .. "/" .. name
            if type == "directory" then
                scan(subpath, ind)
            elseif type == "file" and name:sub(-3) == ".no" then
                table.insert(vim.g.norsu.notes, subpath)
                -- TODO NOW
            end
        end
    end
    scan(vim.g.norsu.wiki, index)
end

--- Computes new index structure for newly entered wiki.
--- @return Index index newly constructed index for current wiki
function Index.new()
    -- TODO ADD checking of the cache has more than there actually are

    local result = {}
    result.notes = {}
    result.tags = {}

    setmetatable(result, Index)
    result = vim.tbl_deep_extend("force", result, load_cache())

    iterate_notes(result)

    return result
end

--- @class Note
--- @field mtime number
---     Last access date of note in question
--- @field links string[]
---     List of relative paths of notes the note in question links to
--- @field backlinks string[]
---     List of relative paths of notes that link to the note in question
--- @field tags string[]
---     List of tag names/paths in the note in question
