import Foundation
import Testing
@testable import HackerNews

struct HackerNewsLinkParserTests {
    @Test func normalizesPlainID() {
        let url = HackerNewsLinkParser.normalizedURL(from: "456")
        #expect(url?.absoluteString == "hn://456")
    }

    @Test func normalizesHostWithoutScheme() {
        let url = HackerNewsLinkParser.normalizedURL(from: "news.ycombinator.com/item?id=789")
        #expect(url?.absoluteString == "https://news.ycombinator.com/item?id=789")
    }

    @Test func rejectsNonHackerNewsLinks() {
        let url = HackerNewsLinkParser.normalizedURL(from: "https://example.com/item?id=123")
        #expect(url == nil)
    }

    @Test func parsesStoryAndCommentFromHNLink() {
        let url = URL(string: "https://news.ycombinator.com/item?id=23160367#23160530")!
        let link = HackerNewsLinkParser.storyLink(from: url)
        #expect(link?.storyID == 23160367)
        #expect(link?.commentID == 23160530)
    }
}
