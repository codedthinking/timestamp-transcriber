import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    struct Completion: Equatable {
        let title: String
        let languageCode: String
        let confidence: Double
        let sourceURL: URL
        let outputURL: URL
        let duration: Double
    }

    enum State: Equatable {
        case idle
        case working(String)
        case complete(Completion)
        case failed(String)
    }

    private static let supportedLanguages: Set<String> = [
        "bg", "hr", "cs", "da", "nl", "en", "et", "fi", "fr", "de", "el", "hu",
        "it", "lv", "lt", "mt", "pl", "pt", "ro", "ru", "sk", "sl", "es", "sv", "uk",
    ]

    private(set) var state: State = .idle
    private(set) var selectedURL: URL?

    var isWorking: Bool {
        if case .working = state { return true }
        return false
    }

    func accept(_ url: URL) {
        guard !isWorking else { return }
        guard url.pathExtension.lowercased() == "m4a" else {
            state = .failed("Choose an M4A audio file.")
            return
        }
        selectedURL = url
        Task { await process(url) }
    }

    func retry() {
        guard let selectedURL, !isWorking else { return }
        Task { await process(selectedURL) }
    }

    func openTranscript() {
        guard case .complete(let completion) = state else { return }
        NSWorkspace.shared.open(completion.outputURL)
    }

    func revealTranscript() {
        guard case .complete(let completion) = state else { return }
        NSWorkspace.shared.activateFileViewerSelecting([completion.outputURL])
    }

    private func process(_ sourceURL: URL) async {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        do {
            let client = try DesertAntClient()

            state = .working("Preparing language detection…")
            try await client.prepare("ear")
            try Task.checkCancellation()

            state = .working("Detecting the spoken language…")
            let detection = try await client.identify(sourceURL)
            guard let language = detection.language else {
                throw WorkflowError.noLanguage
            }
            guard Self.supportedLanguages.contains(language) else {
                throw WorkflowError.unsupportedLanguage(language)
            }

            state = .working("Preparing speech recognition…")
            try await client.prepare("voz")
            try Task.checkCancellation()

            state = .working("Transcribing on this Mac…")
            let transcript = try await client.transcribe(sourceURL)
            guard !transcript.sentences.isEmpty else { throw WorkflowError.noSpeech }

            state = .working("Preparing the title model…")
            try await client.prepare("title")
            try Task.checkCancellation()

            state = .working("Writing a title in \(language.uppercased())…")
            let card = try await client.title(for: transcript.text)
            let title = card.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { throw WorkflowError.noTitle }

            state = .working("Saving the timestamped transcript…")
            let fallback = sourceURL.deletingPathExtension().lastPathComponent + " transcript"
            let fileName = TranscriptDocument.fileName(for: title, fallback: fallback)
            let outputURL = TranscriptDocument.availableURL(beside: sourceURL, named: fileName)
            let document = TranscriptDocument.render(
                title: title,
                languageCode: language,
                sourceName: sourceURL.lastPathComponent,
                sentences: transcript.sentences
            )
            try document.write(to: outputURL, atomically: true, encoding: .utf8)

            state = .complete(Completion(
                title: title,
                languageCode: language,
                confidence: detection.confidence,
                sourceURL: sourceURL,
                outputURL: outputURL,
                duration: transcript.durationSec
            ))
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

private enum WorkflowError: LocalizedError {
    case noLanguage
    case unsupportedLanguage(String)
    case noSpeech
    case noTitle

    var errorDescription: String? {
        switch self {
        case .noLanguage:
            "No spoken language could be detected in this recording."
        case .unsupportedLanguage(let code):
            "The detected language, \(code.uppercased()), is not supported by Voz."
        case .noSpeech:
            "No speech was found in this recording."
        case .noTitle:
            "The title model returned no title. Try the recording again."
        }
    }
}
