//
//  HackerNewsTests.swift
//  HackerNewsTests
//
//  Created by ned on 23/11/25.
//

import Foundation
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

    @Test func neutralizesReferenceStyleLinks() async throws {
        let html = """
        <p>The paper is quite good [0]</p>
        <p>[0]: <a href="https://example.com/v/file.pdf">https://example.com/v/file.pdf</a></p>
        """
        let markdown = await service.convert(html)
        #expect(markdown == "The paper is quite good [0]\n\n0: [https://example.com/v/file.pdf](https://example.com/v/file.pdf)")
    }

    @Test func trimsLeadingAndTrailingBlankLines() async throws {
        let html = "<p>Line1</p><p>Line2</p><p></p>"
        let markdown = await service.convert(html)
        #expect(markdown == "Line1\n\nLine2")
    }

    @Test func prunesEmptyComments() {
        let child = Comment(id: 2, author: "ghost", content: "   ", children: [])
        let parent = Comment(id: 1, author: "parent", content: "Parent", children: [child])

        let pruned = parent.pruned()
        #expect(pruned?.children.isEmpty == true)
    }

    @Test func keepsDeletedComments() {
        let deleted = Comment(id: 1, author: "ghost", content: "[deleted]", children: [])
        let pruned = deleted.pruned()
        #expect(pruned?.content == "[deleted]")
    }

    @Test func extractsStoryIDFromItemLink() {
        let url = URL(string: "https://news.ycombinator.com/item?id=45979220")!
        #expect(HackerNewsLinkParser.storyID(from: url) == 45979220)
    }

    @Test func extractsStoryIDFromRelativeItemLink() {
        let url = URL(string: "item?id=45979220")!
        #expect(HackerNewsLinkParser.storyID(from: url) == 45979220)
    }

    @Test func extractsStoryIDFromRootedRelativeLink() {
        let url = URL(string: "/item?id=45979220")!
        #expect(HackerNewsLinkParser.storyID(from: url) == 45979220)
    }

    @Test func extractsStoryIDFromPathItemLink() {
        let url = URL(string: "https://news.ycombinator.com/item/45979220")!
        #expect(HackerNewsLinkParser.storyID(from: url) == 45979220)
    }

    @Test func extractsStoryAndCommentFromAnchorLink() {
        let url = URL(string: "https://news.ycombinator.com/item?id=23160367#23160530")!
        let link = HackerNewsLinkParser.storyLink(from: url)
        #expect(link?.storyID == 23160367)
        #expect(link?.commentID == 23160530)
    }

    @Test func extractsStoryAndCommentFromHNScheme() {
        let url = URL(string: "hn://46073844#46073077")!
        let link = HackerNewsLinkParser.storyLink(from: url)
        #expect(link?.storyID == 46073844)
        #expect(link?.commentID == 46073077)
    }

    @Test func ignoresNonHackerNewsLinks() {
        let url = URL(string: "https://example.com/item?id=123")!
        #expect(HackerNewsLinkParser.storyID(from: url) == nil)
    }

    @Test func separatesReferenceLinksWithBlankLine() async throws {
        let html = """
        <p>After we have Smell-O-Vision[0] we should work on the next big step for the internet:<p>&lt;[SA]HatfulOfHollow&gt; i&#x27;m going to become rich and famous after i invent a device that allows you to stab people in the face over the internet<p>[0]: <a href="https://en.wikipedia.org/wiki/Smell-O-Vision" rel="nofollow">https://en.wikipedia.org/wiki/Smell-O-Vision</a>
        """
        let markdown = await service.convert(html)
        #expect(markdown == """
        After we have Smell-O-Vision[0] we should work on the next big step for the internet:

        <[SA]HatfulOfHollow> i'm going to become rich and famous after i invent a device that allows you to stab people in the face over the internet

        0: [https://en.wikipedia.org/wiki/Smell-O-Vision](https://en.wikipedia.org/wiki/Smell-O-Vision)
        """)
    }
}
