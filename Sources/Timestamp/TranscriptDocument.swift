import Foundation

struct TimedSentence: Codable, Equatable, Sendable {
    let start: Double
    let end: Double
    let text: String
}

struct TranscriptPayload: Decodable, Sendable {
    let input: String
    let text: String
    let durationSec: Double
    let sentences: [TimedSentence]
}

struct LanguagePayload: Decodable, Sendable {
    let language: String?
    let confidence: Double
}

struct TitlePayload: Decodable, Sendable {
    let title: String
    let description: String
}

enum TranscriptDocument {
    static func render(
        title: String,
        languageCode: String,
        sourceName: String,
        sentences: [TimedSentence]
    ) -> String {
        let lines = sentences.map { "[\(timestamp($0.start))] \($0.text)" }
        return ([title, "\(languageCode.uppercased()) · \(sourceName)", ""] + lines)
            .joined(separator: "\n") + "\n"
    }

    static func timestamp(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let remaining = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remaining)
        }
        return String(format: "%02d:%02d", minutes, remaining)
    }

    static func fileName(for title: String, fallback: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_"))
        let cleaned = title.unicodeScalars
            .map { allowed.contains($0) ? Character(String($0)) : " " }
        let collapsed = String(cleaned)
            .split(whereSeparator: \Character.isWhitespace)
            .joined(separator: " ")
        let base = collapsed.isEmpty ? fallback : collapsed
        return String(base.prefix(80)) + ".txt"
    }

    static func availableURL(beside source: URL, named fileName: String) -> URL {
        let folder = source.deletingLastPathComponent()
        let proposed = folder.appending(path: fileName)
        guard FileManager.default.fileExists(atPath: proposed.path) else { return proposed }

        let stem = proposed.deletingPathExtension().lastPathComponent
        let ext = proposed.pathExtension
        for index in 2...999 {
            let candidate = folder.appending(path: "\(stem)-\(index).\(ext)")
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return folder.appending(path: "\(stem)-\(UUID().uuidString).\(ext)")
    }
}
