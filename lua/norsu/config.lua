--- @class NorsuConfig
--- @field root string
---     Deepest directory containing all detectable wikis on the system.
---     The wiki indexing algorithm stops crawling here.
---     All wikis outside the root will not be indexed.
--- @field entry_dir string|fun():string
---     Directory where notes and folders created with :NorsuOpen and
---     :NorsuNewFolder respectively get saved.
---     Accepts a string containing the relative path from the wiki root or a
---     function returning such a string.
--- @field allow_folder_delete boolean
---     Allow :NorsuDelete to also recursively delete folders.

--- @type NorsuConfig
return {
    root = os.getenv "HOME" --[[@as string]],
    entry_dir = ".",
    allow_folder_delete = false
}
