import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import Readability

protocol SummaryService {
    var isAvailable: Bool { get }
    func summarize(url: URL, title: String?) async -> String?
}

struct UnavailableSummaryService: SummaryService {
    var isAvailable: Bool { false }
    func summarize(url: URL, title: String?) async -> String? { nil }
}

enum SummaryServiceFactory {
    static func make() -> any SummaryService {
        #if canImport(FoundationModels)
        return LiveSummaryService()
        #endif
        return UnavailableSummaryService()
    }
}

#if canImport(FoundationModels)
struct LiveSummaryService: SummaryService {
    var isAvailable: Bool {
        guard !ProcessInfo.processInfo.isRunningOnSimulator else { return false }
        return SystemLanguageModel.default.availability == .available
    }

    func summarize(url: URL, title: String?) async -> String? {
        guard isAvailable else { return nil }
        do {
            let t0 = Date()
            print("[Summary] start url=\(url.absoluteString)")
            let result = try await Readability().parse(url: url)
            let text = Self.limitWords(result.textContent, maxWords: 3500).trimmingCharacters(in: .whitespacesAndNewlines)

            let content: String
            if !text.isEmpty {
                content = text
            } else {
                print("[Summary] readability returned empty, falling back to plain fetch")
                content = await (Self.fetchPlainText(url: url) ?? "")
            }

            guard !content.isEmpty else { return nil }

            let attempts: [(chunkCap: Int, combinedCap: Int)] = [
                (200, 160),
                (150, 120)
            ]

            for attempt in attempts {
                do {
                    let attemptStart = Date()
                    print("[Summary] attempt chunkCap=\(attempt.chunkCap) combinedCap=\(attempt.combinedCap)")
                    if let summary = try await Self.summarize(text: content, title: title, chunkCap: attempt.chunkCap, combinedCap: attempt.combinedCap) {
                        let elapsed = Date().timeIntervalSince(attemptStart)
                        print("[Summary] success in \(String(format: "%.2f", elapsed))s")
                        print("[Summary] total elapsed \(String(format: "%.2f", Date().timeIntervalSince(t0)))s")
                        return summary
                    }
                    let elapsed = Date().timeIntervalSince(attemptStart)
                    print("[Summary] attempt produced no summary in \(String(format: "%.2f", elapsed))s")
                } catch {
                    if Self.isContextError(error) {
                        print("[Summary] context error, retrying smaller caps")
                        continue
                    } else {
                        print("[Summary] failure: \(error)")
                        break
                    }
                }
            }
            print("[Summary] all attempts exhausted in \(String(format: "%.2f", Date().timeIntervalSince(t0)))s")
            return nil
        } catch {
            if Self.isReaderUnavailable(error) {
                print("[Summary] reader unavailable, attempting plain fetch fallback")
                if let plain = await Self.fetchPlainText(url: url) {
                    return await Self.summarizePlain(text: plain, title: title)
                }
            }
            print("[Summary] fatal error: \(error)")
            return nil
        }
    }

    private static func summarizePlain(text: String, title: String?) async -> String? {
        let trimmed = limitWords(text, maxWords: 2000).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let attempts: [(chunkCap: Int, combinedCap: Int)] = [
            (180, 140),
            (140, 110)
        ]

        for attempt in attempts {
            do {
                if let summary = try await summarize(text: trimmed, title: title, chunkCap: attempt.chunkCap, combinedCap: attempt.combinedCap) {
                    return summary
                }
            } catch {
                if isContextError(error) {
                    continue
                } else {
                    break
                }
            }
        }
        return nil
    }

    private static func summarize(text: String, title: String?, chunkCap: Int, combinedCap: Int) async throws -> String? {
        var chunks = chunkText(text, maxWords: chunkCap)
        if chunks.isEmpty { return nil }
        if chunks.count > 3 {
            chunks = Array(chunks.prefix(3))
            print("[Summary] chunked into \(chunks.count) parts (cap=\(chunkCap)) (truncated)")
        } else {
            print("[Summary] chunked into \(chunks.count) parts (cap=\(chunkCap))")
        }

        let session = LanguageModelSession(model: .default)
        let options = GenerationOptions(sampling: .greedy, maximumResponseTokens: 220)

        var partials: [String] = []
        for chunk in chunks {
            let chunkStart = Date()
            let limitedChunk = limitWords(chunk, maxWords: chunkCap)
            let prompt = prompt(for: limitedChunk, title: title, isFinal: chunks.count == 1)
            let response = try await session.respond(to: prompt, options: options)
            let trimmed = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                partials.append(trimToTwoParagraphs(trimmed))
            }
            let elapsed = Date().timeIntervalSince(chunkStart)
            print("[Summary] chunk processed in \(String(format: "%.2f", elapsed))s, partials=\(partials.count)")
        }

        guard !partials.isEmpty else { return nil }
        if partials.count == 1 { return partials[0] }

        let combined = partials.joined(separator: "\n\n")
        let limitedCombined = limitWords(combined, maxWords: combinedCap)
        let finalPrompt = prompt(for: limitedCombined, title: title, isFinal: true)
        let finalResponse = try await session.respond(to: finalPrompt, options: options)
        let finalSummary = finalResponse.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimToTwoParagraphs(finalSummary)
    }

    private static func prompt(for text: String, title: String?, isFinal: Bool) -> String {
        """
        Summarize the following content in 2 concise paragraphs. Each paragraph should contain 2–3 short sentences. Keep the tone neutral and clear.

        Title: \(title ?? "(unknown title)")

        \(text)
        """
    }

    private static func trimToTwoParagraphs(_ text: String) -> String {
        let paragraphs = text
            .components(separatedBy: CharacterSet.newlines)
            .split(whereSeparator: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            .map { $0.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return paragraphs.prefix(2).joined(separator: "\n\n")
    }

    private static func chunkText(_ text: String, maxWords: Int = 2400) -> [String] {
        let paragraphs = text
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var chunks: [String] = []
        var current: [String] = []
        var currentCount = 0

        func flush() {
            guard !current.isEmpty else { return }
            chunks.append(current.joined(separator: "\n\n"))
            current.removeAll()
            currentCount = 0
        }

        for paragraph in paragraphs {
            let wordCount = paragraph.split(whereSeparator: { $0.isWhitespace }).count
            if currentCount + wordCount > maxWords {
                flush()
            }
            current.append(paragraph)
            currentCount += wordCount
        }
        flush()
        return chunks
    }

    private static func limitWords(_ text: String, maxWords: Int) -> String {
        var wordsSeen = 0
        var pieces: [Substring] = []
        for word in text.split(whereSeparator: { $0.isWhitespace }) {
            if wordsSeen >= maxWords { break }
            pieces.append(word)
            wordsSeen += 1
        }
        return pieces.joined(separator: " ")
    }

    private static func isContextError(_ error: any Error) -> Bool {
        if let genError = error as? LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = genError { return true }
        }
        return false
    }

    private static func fetchPlainText(url: URL) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            return stripHTML(html)
        } catch {
            print("[Summary] plain fetch failed: \(error)")
            return nil
        }
    }

    private static func stripHTML(_ html: String) -> String {
        let withoutScripts = html.replacingOccurrences(of: "(?is)<(script|style)[^>]*>.*?</\\1>", with: " ", options: .regularExpression)
        let withoutTags = withoutScripts.replacingOccurrences(of: "(?is)<[^>]+>", with: " ", options: .regularExpression)
        let collapsed = withoutTags.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isReaderUnavailable(_ error: any Error) -> Bool {
        let message = String(describing: error).lowercased()
        if message.contains("readerisunavailable") { return true }
        if message.contains("reader is unavailable") { return true }
        if message.contains("reader unavailable") { return true }
        return false
    }
}
#endif

private extension ProcessInfo {
    var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        environment["SIMULATOR_DEVICE_NAME"] != nil
        #endif
    }
}
