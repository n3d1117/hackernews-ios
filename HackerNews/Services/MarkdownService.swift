import Foundation

actor MarkdownService {
    private enum CacheValue {
        case none
        case some(String)

        var value: String? {
            switch self {
            case .none:
                return nil
            case let .some(value):
                return value
            }
        }
    }

    private struct RegexKey: Hashable {
        let pattern: String
        let options: UInt
    }

    private var cache: [String: CacheValue] = [:]
    private var cacheOrder: [String] = []
    private var regexCache: [RegexKey: NSRegularExpression] = [:]
    private let cacheLimit = 500

    func convert(_ html: String?, cacheKey: String? = nil) -> String? {
        if let cacheKey, let cached = cache[cacheKey] {
            if case .some = cached {
                touchCache(key: cacheKey)
                return cached.value
            }
            if html == nil || html?.isEmpty == true {
                touchCache(key: cacheKey)
                return cached.value
            }
        }
        guard var text = html, !text.isEmpty else {
            if let cacheKey { storeCache(key: cacheKey, value: html) }
            return html
        }

        text = replaceLinks(in: text)
        text = replacePreBlocks(in: text)
        text = replaceInlineCode(in: text)
        text = wrap(in: text, tag: "strong", with: "**")
        text = wrap(in: text, tag: "b", with: "**")
        text = wrap(in: text, tag: "em", with: "*")
        text = wrap(in: text, tag: "i", with: "*")
        text = replaceParagraphs(in: text)
        text = replaceBreaks(in: text)
        text = neutralizeLinkReferences(in: text)
        text = stripRemainingTags(in: text)
        text = decodeEntities(in: text)
        text = ensureReferenceSeparation(in: text)
        text = trimEmptyLines(in: text)
        text = stripEmptyCodeLines(in: text)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cacheKey { storeCache(key: cacheKey, value: trimmed) }
        return trimmed
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
            let code = normalizeCodeBlock(match[1])
            return "```\n\(code)\n```"
        }
    }

    private func normalizeCodeBlock(_ code: String) -> String {
        var lines = code.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        trimEmptyEdges(&lines)

        guard let firstLine = lines.first else { return "" }
        let baseline = firstLine.prefix(while: { $0 == " " || $0 == "\t" }).count

        let dedented = lines.map { line -> String in
            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let drop = min(indent, baseline)
            return String(line.dropFirst(drop))
        }

        let cleaned = dedented.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return cleaned.joined(separator: "\n")
    }

    private func trimEmptyEdges(_ lines: inout [String]) {
        while let first = lines.first, first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeFirst()
        }

        while let last = lines.last, last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeLast()
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

    private func neutralizeLinkReferences(in text: String) -> String {
        replace(text, pattern: #"(?m)^\s*\[(.+?)\]:\s*(.+)$"#) { match in
            let label = match[1]
            let target = match[2]
            return "\(label): \(target)"
        }
    }

    private func stripRemainingTags(in text: String) -> String {
        replace(text, pattern: #"<[^>]+>"#) { _ in "" }
    }

    private func decodeEntities(in text: String) -> String {
        var decoded = text
        decoded = decoded.replacingOccurrences(of: "&amp;", with: "&")
        decoded = decoded.replacingOccurrences(of: "&lt;", with: "<")
        decoded = decoded.replacingOccurrences(of: "&gt;", with: ">")
        decoded = decoded.replacingOccurrences(of: "&quot;", with: "\"")
        decoded = decoded.replacingOccurrences(of: "&apos;", with: "'")
        decoded = decoded.replacingOccurrences(of: "&#39;", with: "'")
        decoded = decoded.replacingOccurrences(of: "&#x27;", with: "'")
        decoded = decoded.replacingOccurrences(of: "&#x2F;", with: "/")
        decoded = decodeNumericEntities(in: decoded)
        return decoded
    }

    private func decodeNumericEntities(in text: String) -> String {
        var updated = text
        updated = replace(updated, pattern: #"&#(\d+);"#) { match in
            guard let code = Int(match[1]), let scalar = UnicodeScalar(code) else { return match[0] }
            return String(scalar)
        }
        updated = replace(updated, pattern: #"&#x([0-9A-Fa-f]+);"#) { match in
            guard let code = Int(match[1], radix: 16), let scalar = UnicodeScalar(code) else { return match[0] }
            return String(scalar)
        }
        return updated
    }

    private func ensureReferenceSeparation(in text: String) -> String {
        var lines: [String] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let isReference = line.range(of: #"^[^:]+:\s"#, options: .regularExpression) != nil
            if isReference, let last = lines.last, !last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("")
            }
            lines.append(String(line))
        }
        return lines.joined(separator: "\n")
    }

    private func stripEmptyCodeLines(in text: String) -> String {
        let pattern = #"```[\n]?([\s\S]*?)[\n]?```"#
        return replace(text, pattern: pattern, options: [.dotMatchesLineSeparators]) { match in
            let block = match[1]
            let lines = block.split(separator: "\n", omittingEmptySubsequences: false)
            let cleaned = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return "```\n\(cleaned.joined(separator: "\n"))\n```"
        }
    }

    private func trimEmptyLines(in text: String) -> String {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        while let first = lines.first, first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeFirst()
        }
        while let last = lines.last, last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    private func touchCache(key: String) {
        guard let index = cacheOrder.firstIndex(of: key) else { return }
        cacheOrder.remove(at: index)
        cacheOrder.append(key)
    }

    private func storeCache(key: String, value: String?) {
        cache[key] = value.map(CacheValue.some) ?? CacheValue.none
        if let index = cacheOrder.firstIndex(of: key) {
            cacheOrder.remove(at: index)
        }
        cacheOrder.append(key)
        while cacheOrder.count > cacheLimit {
            let removedKey = cacheOrder.removeFirst()
            cache.removeValue(forKey: removedKey)
        }
    }

    private func regex(for pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? {
        let key = RegexKey(pattern: pattern, options: options.rawValue)
        if let cached = regexCache[key] {
            return cached
        }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        regexCache[key] = regex
        return regex
    }

    private func replace(_ text: String, pattern: String, options: NSRegularExpression.Options = [], transform: ([String]) -> String) -> String {
        guard let regex = regex(for: pattern, options: options) else { return text }
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

private extension Collection where Element == Int {
    func mode() -> Int? {
        var counts: [Int: Int] = [:]
        for value in self {
            counts[value, default: 0] += 1
        }
        return counts.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        }?.key
    }
}
