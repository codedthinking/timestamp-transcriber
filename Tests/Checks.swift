import Foundation

@main
enum Checks {
    static func main() throws {
        let text = TranscriptDocument.render(
            title: "A short Hungarian title",
            languageCode: "hu",
            sourceName: "meeting.m4a",
            sentences: [
                TimedSentence(start: 2.9, end: 5.0, text: "Első mondat."),
                TimedSentence(start: 3_661.2, end: 3_664, text: "Második mondat."),
            ]
        )
        try expect(
            text == "A short Hungarian title\nHU · meeting.m4a\n\n"
                + "[00:02] Első mondat.\n[01:01:01] Második mondat.\n",
            "timestamped transcript format"
        )

        try expect(
            TranscriptDocument.fileName(
                for: "Árvíztűrő / tükörfúrógép?",
                fallback: "recording"
            ) == "Árvíztűrő tükörfúrógép.txt",
            "safe Unicode filename"
        )

        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appending(path: "recording.m4a")
        let existing = folder.appending(path: "Interview.txt")
        try Data().write(to: source)
        try Data().write(to: existing)
        try expect(
            TranscriptDocument.availableURL(
                beside: source,
                named: "Interview.txt"
            ).lastPathComponent == "Interview-2.txt",
            "collision-free output path"
        )

        let transcript = String(repeating: "a", count: 9_500)
            + String(repeating: "z", count: 3_500)
        let input = DesertAntClient.titleInput(from: transcript)
        try expect(
            input.hasPrefix("aaaa") && input.hasSuffix("zzzz") && input.count < transcript.count,
            "bounded title input samples both ends"
        )

        print("4 checks passed")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ name: String) throws {
        guard condition() else {
            throw CheckFailure(name: name)
        }
    }
}

private struct CheckFailure: LocalizedError {
    let name: String
    var errorDescription: String? { "Check failed: \(name)" }
}
