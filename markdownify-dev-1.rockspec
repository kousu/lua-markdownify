rockspec_format = "3.0"
package = "markdownify"
version = "dev-1"

source = {
   url = "git+https://github.com/kousu/lua-markdownify.git",
   branch = "main",
}

description = {
   summary = "Convert HTML to Markdown, in pure Lua",
   detailed = [[
      markdownify converts HTML, such as rich text from the clipboard, to
      Markdown: it keeps what Markdown can represent, the text of everything
      else, and drops what's only presentation.
   ]],
   homepage = "https://github.com/kousu/lua-markdownify",
   license = "MIT",
}

dependencies = {
   "lua >= 5.1",
   -- lusoup is vendored as markdownify.lusoup instead: markdownify needs a
   -- patched lusoup (kousu/lusoup's html5 branch, with an HTML5 parser),
   -- and LuaRocks dependencies can't point at a git branch. Restore this
   -- once those patches are in a lusoup release.
   -- "lusoup",
}

test_dependencies = {
   "busted",
}

test = {
   type = "busted",
}

build = {
   type = "builtin",
   modules = {
      ["markdownify"] = "markdownify/init.lua",
      ["markdownify.lusoup"] = "markdownify/lusoup/init.lua",
      ["markdownify.lusoup.dom"] = "markdownify/lusoup/dom.lua",
      ["markdownify.lusoup.tokenizer"] = "markdownify/lusoup/tokenizer.lua",
      ["markdownify.lusoup.treebuilder"] = "markdownify/lusoup/treebuilder.lua",
      ["markdownify.lusoup.selector"] = "markdownify/lusoup/selector.lua",
      ["markdownify.lusoup.entities"] = "markdownify/lusoup/entities.lua",
      ["markdownify.lusoup.entity_table"] = "markdownify/lusoup/entity_table.lua",
   },
}
