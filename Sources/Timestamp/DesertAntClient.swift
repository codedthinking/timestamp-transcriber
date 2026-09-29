import Foundation

struct DesertAntClient: Sendable {
    enum ClientError: LocalizedError {
        case runtimeMissing
        case commandFailed(String)
        case invalidResponse(String)

        var errorDescription: String? {
            switch self {
            case .runtimeMissing:
                "Desert Ant is not installed. Run: brew install desert-ant-labs/tap/desertant"
            case .commandFailed(let message):
                message.isEmpty ? "The on-device model did not finish." : message
            case .invalidResponse(let command):
                "Desert Ant returned an unreadable response for \(command)."
            }
        }
    }

    private let executableURL: URL

    init() throws {
        let candidates = [
            "/opt/homebrew/bin/desertant",
            "/usr/local/bin/desertant",
            "\(NSHomeDirectory())/.local/bin/desertant",
        ]
        guard let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            throw ClientError.runtimeMissing
        }
        executableURL = URL(filePath: path)
    }

    func prepare(_ model: String) async throws {
        _ = try await run(["pull", model, "--json", "--quiet", "--no-color"])
    }

    func identify(_ audioURL: URL) async throws -> LanguagePayload {
        try decode(
            LanguagePayload.self,
            from: await run(["ear", audioURL.path, "--json", "--quiet", "--no-color"]),
            command: "language detection"
        )
    }

    func transcribe(_ audioURL: URL) async throws -> TranscriptPayload {
        try decode(
            TranscriptPayload.self,
            from: await run(["voz", audioURL.path, "--json", "--quiet", "--no-color"]),
            command: "transcription"
        )
    }

    func title(for transcript: String) async throws -> TitlePayload {
        let input = Data(Self.titleInput(from: transcript).utf8)
        return try decode(
            TitlePayload.self,
            from: await run(
                ["run", "title", "--json", "--quiet", "--no-color"],
                standardInput: input
            ),
            command: "title generation"
        )
    }

    static func titleInput(from transcript: String) -> String {
        guard transcript.count > 12_000 else { return transcript }
        // ponytail: Sample both ends within the small model's context window;
        // add hierarchical summarization only when long recordings prove this insufficient.
        return String(transcript.prefix(9_000))
            + "\n[…]\n"
            + String(transcript.suffix(3_000))
    }

    private func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        command: String
    ) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ClientError.invalidResponse(command)
        }
    }

    private func run(_ arguments: [String], standardInput: Data? = nil) async throws -> Data {
        let executableURL = self.executableURL
        return try await Task.detached(priority: .userInitiated) {
            let temporary = FileManager.default.temporaryDirectory
            let identifier = UUID().uuidString
            let outputURL = temporary.appending(path: "timestamp-\(identifier).out")
            let errorURL = temporary.appending(path: "timestamp-\(identifier).err")
            let inputURL = temporary.appending(path: "timestamp-\(identifier).in")
            defer {
                try? FileManager.default.removeItem(at: outputURL)
                try? FileManager.default.removeItem(at: errorURL)
                try? FileManager.default.removeItem(at: inputURL)
            }

            FileManager.default.createFile(atPath: outputURL.path, contents: nil)
            FileManager.default.createFile(atPath: errorURL.path, contents: nil)
            let output = try FileHandle(forWritingTo: outputURL)
            let error = try FileHandle(forWritingTo: errorURL)
            defer {
                try? output.close()
                try? error.close()
            }

            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments
            process.standardOutput = output
            process.standardError = error
            if let standardInput {
                try standardInput.write(to: inputURL)
                process.standardInput = try FileHandle(forReadingFrom: inputURL)
            } else {
                process.standardInput = FileHandle.nullDevice
            }

            try process.run()
            process.waitUntilExit()
            try output.close()
            try error.close()

            guard process.terminationStatus == 0 else {
                let data = (try? Data(contentsOf: errorURL)) ?? Data()
                let message = String(decoding: data, as: UTF8.self)
                    .replacingOccurrences(of: "Error: ", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                throw ClientError.commandFailed(message)
            }
            return try Data(contentsOf: outputURL)
        }.value
    }
}
