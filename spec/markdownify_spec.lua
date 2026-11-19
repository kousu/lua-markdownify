local markdownify = require("markdownify")

local function md(html, opts)
	return markdownify.convert(html, opts)
end

describe("markdownify.convert()", function()
	it("converts headings, emphasis and links", function()
		assert.are.equal(
			"# Title\n\nHello **bold** and *it*, [link](https://x.org).",
			md('<h1>Title</h1><p>Hello <b>bold</b> and <i>it</i>, <a href="https://x.org">link</a>.</p>')
		)
	end)

	it("wraps link destinations with spaces in <>, and shows bare URLs as autolinks", function()
		assert.are.equal(
			"[a](<x y.md>) <https://x.org>",
			md('<a href="x y.md">a</a> <a href="https://x.org">https://x.org</a>')
		)
	end)

	it("converts lists, keeping sub-lists tight and ordered starts", function()
		assert.are.equal(
			"- one\n- two\n  - nested\n\n3. three",
			md("<ul><li>one</li><li>two<ul><li>nested</li></ul></li></ul><ol start=3><li>three</li></ol>")
		)
	end)

	it("turns checkboxes into task list items", function()
		assert.are.equal(
			"- [x] done\n- [ ] todo",
			md("<ul><li><input type=checkbox checked> done<li><input type=checkbox> todo</ul>")
		)
	end)

	it("converts tables, escaping pipes", function()
		assert.are.equal(
			"| A | B |\n| --- | --- |\n| 1\\|x | 2 |",
			md("<table><tr><th>A</th><th>B</th></tr><tr><td>1|x</td><td>2</td></tr></table>")
		)
	end)

	it("converts quotes, code blocks, rules and line breaks", function()
		assert.are.equal(
			"> q1\n>\n> q2\n\n```sh\necho `hi`\n```\n\n---\n\na\\\nb",
			md(
				'<blockquote><p>q1</p><p>q2</p></blockquote><pre><code class="language-sh">echo `hi`\n</code></pre><hr><p>a<br>b</p>'
			)
		)
	end)

	it("keeps only the copied fragment, and drops head content", function()
		assert.are.equal(
			"x",
			md(
				"<html><head><style>p{}</style></head><body>before<!--StartFragment--><p>x</p><!--EndFragment-->after</body></html>"
			)
		)
	end)

	it("escapes text that would otherwise be Markdown", function()
		assert.are.equal(
			"\\* not a list\n\n1\\. not a list\n\n\\# not a heading\n\na \\*b\\* c",
			md("<p>* not a list</p><p>1. not a list</p><p># not a heading</p><p>a *b* c</p>")
		)
	end)

	it("follows bold and italic in inline styles, as Google Docs and LibreOffice write them", function()
		assert.are.equal(
			"plain **bold** *slanted*",
			md(
				'<b style="font-weight:normal" id="docs-internal-guid-1">plain <span style="font-weight:700">bold</span> <span style="font-style:italic">slanted</span></b>'
			)
		)
	end)

	it("keeps spaces outside emphasis markers", function()
		assert.are.equal("a **b** c", md("a<b> b </b>c"))
	end)

	it("uses backticks that don't occur in inline code", function()
		assert.are.equal("``a`b``", md("<code>a`b</code>"))
	end)

	it("links images unchanged without a handler, data: images included", function()
		assert.are.equal(
			"![pic](data:image/png;base64,AA) ![y](x.png)",
			md('<img src="data:image/png;base64,AA" alt="pic"> <img src="x.png" alt="y">')
		)
	end)

	it("passes image sources through the image handler", function()
		local seen = {}
		local out = md('<img src="https://x.org/a.png" alt="a"><img src="b.png" alt="b">', {
			imageHandler = function(src, alt)
				seen[#seen + 1] = alt
				if alt == "a" then
					return "./a.png"
				end
			end,
		})
		assert.are.equal("![a](./a.png)b", out)
		assert.are.same({ "a", "b" }, seen)
	end)

	it("drops scripts and javascript: links", function()
		assert.are.equal("go", md('<script>alert(1)</script><a href="javascript:alert(1)">go</a>'))
	end)

	it("names links copied without their text by their title, and drops the rest", function()
		assert.are.equal(
			"[Dugong](https://x.org/D) and",
			md('<p><a href="https://x.org/D" title="Dugong"><span></span></a> and <a href="https://x.org/E"></a></p>')
		)
	end)

	it("separates list items in a table cell", function()
		assert.are.equal(
			"| a | [b](https://x.org/b) · c |\n| --- | --- |",
			md('<table><tr><th>a</th><td><ul><li><a href="https://x.org/b">b</a></li><li>c</li></ul></td></tr></table>')
		)
	end)

	describe("links within the copied page", function()
		local html = '<p><a href="https://x.org/p#Early_days">a</a> <a href="https://x.org/q#Early_days">b</a>'
			.. ' <a href="https://x.org/p#Later">c</a> <a href="#Early_days">d</a></p>'
			.. '<h2 id="Early_days">Early days</h2>'

		it("point at headings, given the page's URL", function()
			assert.are.equal(
				"[a](#early-days) [b](https://x.org/q#Early_days) [c](https://x.org/p#Later) [d](#early-days)\n\n## Early days",
				md(html, { source = "https://x.org/p#somewhere" })
			)
		end)

		it("point at headings given only the site, if only one page there links into the HTML", function()
			local one = '<a href="https://x.org/p#A">a</a> <a href="https://x.org/q#Z">b</a><h2 id="A">A</h2>'
			assert.are.equal("[a](#a) [b](https://x.org/q#Z)\n\n## A", md(one, { source = "https://x.org" }))
			-- p and q both reach "Early_days": no telling which is the page
			assert.are.equal(
				"[a](https://x.org/p#Early_days) [b](https://x.org/q#Early_days) [c](https://x.org/p#Later) [d](#early-days)\n\n## Early days",
				md(html, { source = "https://x.org" })
			)
		end)

		it("are only relative ones, without a source", function()
			assert.are.equal(
				"[a](https://x.org/p#Early_days) [b](https://x.org/q#Early_days) [c](https://x.org/p#Later) [d](#early-days)\n\n## Early days",
				md(html)
			)
		end)

		it("can use another anchor function", function()
			local out = md('<a href="#A%20b">x</a><h2 id="A b">A, b!</h2>', {
				anchor = function(line)
					return "custom-" .. line
				end,
			})
			assert.are.equal("[x](<#custom-## A, b!>)\n\n## A, b!", out)
		end)

		it("name links copied without their text by the heading they point at", function()
			assert.are.equal(
				"- [Early days](#early-days)\n\n## Early days",
				md('<ul><li><a href="#Early_days"><span></span></a></li></ul><h2 id="Early_days">Early days</h2>')
			)
		end)
	end)

	describe("footnotes", function()
		it("are made of <sup>s holding just a link, defined by the copied note", function()
			local html = '<p>Claim<sup id="r1"><a href="https://x.org/p#n1">[1]</a></sup> and<sup><a href="https://x.org/p#n2">[note 2]</a></sup>'
				.. ' again<sup><a href="https://x.org/p#n1">[1]</a></sup>.</p>'
				.. '<ol><li id="n1"><a href="https://x.org/p#r1">^</a> Source <i>one</i>.</li><li id="n2">Two.</li><li>Other.</li></ol>'
			assert.are.equal(
				"Claim[^1] and[^note-2] again[^1].\n\n1. Other.\n\n[^1]: Source *one*.\n[^note-2]: Two.",
				md(html, { source = "https://x.org/p" })
			)
		end)

		it("link to notes that weren't copied", function()
			assert.are.equal(
				"Claim[^7].\n\n[^7]: <https://x.org/p#cite_note-7>",
				md(
					'<p>Claim<sup><a href="https://x.org/p#cite_note-7">[7]</a></sup>.</p>',
					{ source = "https://x.org/p" }
				)
			)
		end)

		it("leave <sup>s with more than a link alone", function()
			assert.are.equal(
				"x2 [y](https://x.org)z",
				md('<p>x<sup>2</sup> <sup><a href="https://x.org">y</a>z</sup></p>')
			)
		end)
	end)

	it("returns an empty string for empty input", function()
		assert.are.equal("", md(""))
	end)
end)
