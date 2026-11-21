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

Text that Markdown would read as formatting is escaped. When the HTML has
the `<!--StartFragment-->`/`<!--EndFragment-->` markers browsers put on
the clipboard, only the part between them is converted.

Outside code, invisible characters that only affect layout or could disguise
the text are removed, so the Markdown can be searched: soft hyphens, zero-width
spaces, word joiners, byte order marks, control characters, and bidi embeddings
and overrides. Non-breaking hyphens become plain hyphens. Characters that some
text needs are kept: ZWJ, ZWNJ, variation selectors, tag characters, LRM, RLM
and bidi isolates. Tag characters are invisible, so they can hide text from a
reader that other tools, such as LLMs, will still see.

## Images

You can pass an `imageHandler(src, alt)` to do something special with their
links. It's called for each image, and should return the src to link to instead,
or `nil` to drop the image and keep only its description.

```lua
markdownify.convert(html, {
    imageHandler = function(src, alt)
        return download(src) -- e.g. save a copy and link to that
    end,
})
```

## Links within the page

Browsers copy links to sections of the page (`href="#History"`) as absolute
links (`https://host/page#History`). Pass the page's URL as `source` and
those whose targets were copied too point into the Markdown instead: links
to headings become `#history`, and footnotes are kept (below). If only the
page's site is known (Firefox puts just that on the clipboard), the page is
taken to be the one there whose links reach the copied HTML, if there's
exactly one; otherwise links are left as they are. Links to anything that
wasn't copied stay absolute, so they still work.

Pass an `anchor(line)` function to make anchors your way; it gets the
heading's Markdown line (`"## History"`), and the default follows GitHub.

## Footnotes

A `<sup>` holding just a link, like Wikipedia's citations, becomes a
footnote reference, labelled with the link's text (`[7]` → `[^7]`). If what
it links to was copied, that is the footnote (and isn't repeated where it
was); otherwise the footnote is the link, so it can still be followed.

## Long documents

Converting a large document takes a while. Pass a `yield` function, called
often during the conversion, to run it in a coroutine without blocking:

```lua
local co = coroutine.create(function()
    return markdownify.convert(html, { yield = coroutine.yield })
end)
-- resume `co` a slice at a time, e.g. from a timer, until it's dead
```

## Testing

```bash
luarocks test
```
