# norsu.nvim
A personal knowledge management plugin with a personally tailored markup language.

Requires Neovim **0.11.0** or above.

## Goals of the language
- Simplicity
- Extensibility
- Human-readability, even in source mode
- Neovim-first approach
- appeal to me :)

## Prerequisites
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Installation
TODO

## Language
```
%%%
index = 5,
date = { year = 2025, month = 4, day = 2 },
author = "me",
frontmatter = true,
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
### heading 3
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
% Inline markers must be directly connected to text. `* bold? *` is invalid.

[[wiki note link]] % ./'wiki note link'.no
[[wiki note link|]]
[[https://gnu.org]]
[[file:///home/user/.gtkrc-2.0]]
![[note]] % show the contents of ./note.no
![[image]] % show an image (norsu-sixel)
[[$echo "Hello World"]] % shell commands (norsu-shell)

> quote block

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
\```
```

## Tips & tricks

### Get a wiki selection
TODO include telescope picker script over arbitrary dirs
