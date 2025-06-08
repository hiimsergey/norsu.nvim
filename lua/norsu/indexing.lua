-- TODO

--- @class Index
--- @field notes table<string, Note>
---     Hashmap with relative note path as input and note metadata as `Note` as
---     output
--- @field tags table<string, string[]>
---     Hashmap with tag name/path as input and list of relative paths of member notes
---     as output

--- @class Note
--- @field links string[]
---     List of relative paths of notes the note in question links to
--- @field backlinks string[]
---     List of relative paths of notes that link to the note in question
--- @field tags string[]
---     List of tag names/paths in the note in question
