import Foundation

actor MarkdownService {
    func convert(_ html: String?) -> String? {
        guard var text = html, !text.isEmpty else { return html }

        text = replaceLinks(in: text)
        text = replacePreBlocks(in: text)
        text = replaceInlineCode(in: text)
        text = wrap(in: text, tag: "strong", with: "**")
        text = wrap(in: text, tag: "b", with: "**")
        text = wrap(in: text, tag: "em", with: "*")
        text = wrap(in: text, tag: "i", with: "*")
        text = replaceParagraphs(in: text)
        text = replaceBreaks(in: text)
        text = stripRemainingTags(in: text)
        text = decodeEntities(in: text)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replaceLinks(in text: String) -> String {
        replace(text, pattern: #"<a\s+[^>]*href="([^"]+)"[^>]*>(.*?)</a>"#) { match in
            let href = match[1]
            let label = match[2]
            return "[\(label)](\(href))"
        }
    }

    private func replacePreBlocks(in text: String) -> String {
        replace(text, pattern: #"<pre><code>(.*?)</code></pre>"#, options: [.dotMatchesLineSeparators]) { match in
            let code = match[1]
            return "```\n\(code)\n```"
        }
    }

    private func replaceInlineCode(in text: String) -> String {
        replace(text, pattern: #"<code>(.*?)</code>"#, options: [.dotMatchesLineSeparators]) { match in
            let code = match[1]
            return "`\(code)`"
        }
    }

    private func wrap(in text: String, tag: String, with wrapper: String) -> String {
        replace(text, pattern: "<\(tag)>(.*?)</\(tag)>", options: [.dotMatchesLineSeparators]) { match in
            let inner = match[1]
            return "\(wrapper)\(inner)\(wrapper)"
        }
    }

    private func replaceParagraphs(in text: String) -> String {
        var updated = replace(text, pattern: #"<p>(.*?)</p>"#, options: [.dotMatchesLineSeparators]) { match in
            let inner = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
            return inner.isEmpty ? "" : "\(inner)\n\n"
        }
        updated = updated.replacingOccurrences(of: "<p>", with: "\n\n")
        updated = updated.replacingOccurrences(of: "</p>", with: "\n\n")
        return updated
    }

    private func replaceBreaks(in text: String) -> String {
        var updated = text
        let breakPatterns = ["<br\\s*/?>", "<BR\\s*/?>"]
        for pattern in breakPatterns {
            updated = replace(updated, pattern: pattern, options: [.caseInsensitive]) { _ in "\n" }
        }
        return updated
    }

    private func stripRemainingTags(in text: String) -> String {
        replace(text, pattern: #"<[^>]+>"#) { _ in "" }
    }

    private func decodeEntities(in text: String) -> String {
        text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private func replace(_ text: String, pattern: String, options: NSRegularExpression.Options = [], transform: ([String]) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var result = text
        let matches = regex.matches(in: text, options: [], range: range).reversed()
        for match in matches {
            var groups: [String] = []
            for idx in 0..<match.numberOfRanges {
                let nsRange = match.range(at: idx)
                if let range = Range(nsRange, in: text) {
                    groups.append(String(text[range]))
                } else {
                    groups.append("")
                }
            }
            let replacement = transform(groups)
            if let r = Range(match.range, in: result) {
                result.replaceSubrange(r, with: replacement)
            }
        }
        return result
    }
}
