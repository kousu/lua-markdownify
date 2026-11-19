# markdownify

Convert HTML to Markdown, in pure Lua: the way GitHub and Obsidian convert
rich text when you paste it.

```lua
local markdownify = require("markdownify")

print(markdownify.convert([[<h1>Notes</h1><p>Some <b>bold</b> text and a
<a href="https://example.com">link</a>.</p><ul><li>one<li>two</ul>]]))
```

```markdown
# Notes

Some **bold** text and a [link](https://example.com).

- one
- two
```

## What's converted

- headings, paragraphs, block quotes, horizontal rules
- bold, italic and strike-through, including from inline styles, as
  Google Docs and LibreOffice write them
- links and images
- lists, including numbered lists' start, and checkboxes as task lists
- tables (the first row is the header)
- inline code and code blocks, with the language from `class="language-x"`
- line breaks

## Testing

```bash
luarocks test
```
