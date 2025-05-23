return {
    -- Deepest directory containing all detectable wikis on the system.
    -- The wiki indexing algorithm stops crawling here.
    -- All wikis outside the root will not be indexed.
    root = vim.fn.expand "~",
    
    -- Directory where notes created with :NorsuOpen get saved.
    -- Accepts a string containing the relative path from the wiki root or a
    -- function returning such a string.
    new_notes_dir = "."
}
