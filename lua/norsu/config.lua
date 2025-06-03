--- @class Config
--- @field root string
---     Deepest directory containing all detectable wikis on the system.
---     The wiki indexing algorithm stops crawling here.
---     All wikis outside the root will not be indexed.

--- @type Config
return {
    root = os.getenv "HOME" or os.getenv "HOMEPATH" --[[@as string]]
    -- TODO FINAL MOVE this if there are no more configs :/
}
