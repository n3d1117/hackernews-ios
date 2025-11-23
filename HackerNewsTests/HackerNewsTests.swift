//
//  HackerNewsTests.swift
//  HackerNewsTests
//
//  Created by ned on 23/11/25.
//

import Testing
@testable import HackerNews

struct MarkdownServiceTests {
    private let service = MarkdownService()

    @Test func handlesParagraphs() async throws {
        let html = "<p>Hello</p><p>World</p>"
        let markdown = await service.convert(html)
        #expect(markdown == "Hello\n\nWorld")
    }

    @Test func convertsLinks() async throws {
        let html = "<p>Hi <a href=\"https://example.com\">there</a></p>"
        let markdown = await service.convert(html)
        #expect(markdown == "Hi [there](https://example.com)")
    }

    @Test func convertsInlineCode() async throws {
        let html = "<p>Use <code>git</code> please</p>"
        let markdown = await service.convert(html)
        #expect(markdown == "Use `git` please")
    }

    @Test func convertsCodeBlocks() async throws {
        let html = "<pre><code>line1\nline2</code></pre>"
        let markdown = await service.convert(html)
        #expect(markdown == "```\nline1\nline2\n```")
    }

    @Test func convertsItalicsAndEntities() async throws {
        let html = "<p><i>fast &amp; light</i></p>"
        let markdown = await service.convert(html)
        #expect(markdown == "*fast & light*")
    }

    @Test func convertsLineBreaks() async throws {
        let html = "<p>Line1<br/>Line2</p>"
        let markdown = await service.convert(html)
        #expect(markdown == "Line1\nLine2")
    }
}
