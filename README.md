> [!WARNING]
> In development! :pensive:
 
# norsu.nvim
A personal knowledge management plugin with a tailored markup language.

## Philosophy
- readability
- Neovim-first apperance and workflow
- portability <!-- TODO see norsu-export -->
- Lua-first for interactive parts (frontmatter, lua links, norsu-query)
- personal appeal to me

## Language syntax
<pre>
%%%
date: 2025-04-02
author: me
type: frontmatter
%%%

% single-line comment
%%
multi
line
comment
%%

--- % separator

# heading 1
## heading 2
### hedaing 3
#### heading 4
##### heading 5
###### heading 6

*bold*
/italic/
_underline_
~strikethrough~
=highlight=
`code`
$\TeX$
> quote
% Inline markers must be directly connected to text. `* bold? *` is invalid.

[[wiki note link]] % ./'wiki note link'.no
[[wiki note link|]]
[[https://gnu.org]]
[[file:///home/user/.gtkrc-2.0]]
![[note]] % show the contents of ./note.no
![[image]] % show an image (norsu-sixel)
$[[vim.print "Hello world" |Lua code]]
$[[
vim.print "It even allows multiple-lines"
vim.cmd.colorscheme "slate"
|Multi-line lua link]]

- bullet list
- bullet list
    - indented bullet list

1. ordered list
2. ordered list
3. ordered list

a. letter list
b. letter list
...
z. letter list
aa. letter list

A. same but in capital
B. same but in capital
...
AA. same but in capital

#tag % norsu-tags
#tag/subtag

| table header | table header |
| content      | content      |
| content      | content      |

```c
int main(void) {
    printf("Code block!\n");
    return 0;
}
```
</pre>

<!-- TODO ADD version requirements for dependencies -->
## Requirements
- Neovim **0.11.0** or above
- Dependency plugins:
    - [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for syntax-related operations
    - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for pickers for interaction

## Installation
TODO <!-- all the cool pkg managers -->

## Configuration
TODO <!-- review config object -->

## Extensions
TODO <!--
explain how extending works
name notable extensions: query, export, bookmarks -->
