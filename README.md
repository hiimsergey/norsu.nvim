# norsu.nvim
A personal knowledge management plugin with a personally tailored markup language.

## Language
```
/*
* date: 2025-04-02
* author:
* type: frontmatter
*/

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

[[wiki note link]] // ./'wiki note link'.no
[[wiki note link|]]
[[https://gnu.org]]
[[file:///home/user/.gtkrc-2.0]]
![[note]] // show the contents of ./note.no
![[image]] // show an image (norsu-sixel)
[[$echo "Hello World"]] // shell commands (norsu-shell)

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

#tag // norsu-tags
#tag/subtag

| table header | table header |
| content      | content      |
| content      | content      |

// comment

```c
int main(void) {
    printf("Code block!\n");
    return 0;
}
\```

> quote

// single-line comment
/*
multi
line
comment
*/

--- // separator
```

## Goals of the language
- Extensibility
- Human-readability, even in source mode
- Neovim-first
- appeal to me, foremost :)
