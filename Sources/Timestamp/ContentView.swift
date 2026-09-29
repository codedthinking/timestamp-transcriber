import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var isImporterPresented = false
    @State private var isDropTargeted = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.055, green: 0.067, blue: 0.082),
                         Color(red: 0.09, green: 0.12, blue: 0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header
                dropZone
                status
                Spacer(minLength: 0)
                Label("Audio and text stay on this Mac", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
        .frame(minWidth: 680, minHeight: 500)
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.mpeg4Audio],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                model.accept(url)
            }
        }
        .onOpenURL { url in
            model.accept(url)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color(red: 0.57, green: 0.92, blue: 0.72))
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 3) {
                Text("Timestamp Transcriber")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("A titled transcript from one recording")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("ON-DEVICE")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(Color(red: 0.57, green: 0.92, blue: 0.72))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1), in: Capsule())
        }
    }

    private var dropZone: some View {
        Button {
            isImporterPresented = true
        } label: {
            VStack(spacing: 14) {
                Image(systemName: model.selectedURL == nil ? "arrow.down.doc" : "waveform")
                    .font(.system(size: 35, weight: .light))
                    .foregroundStyle(isDropTargeted ? .white : .secondary)
                if let selectedURL = model.selectedURL {
                    Text(selectedURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                    Text(model.isWorking ? "Processing this recording" : "Choose another M4A")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Drop an M4A here")
                        .font(.headline)
                    Text("or click to choose a recording")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(.white.opacity(isDropTargeted ? 0.11 : 0.055))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        isDropTargeted ? Color.white.opacity(0.8) : Color.white.opacity(0.17),
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 7])
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .disabled(model.isWorking)
        .keyboardShortcut("o", modifiers: .command)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            model.accept(url)
            return url.pathExtension.lowercased() == "m4a"
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .accessibilityLabel("Choose an M4A recording")
    }

    @ViewBuilder
    private var status: some View {
        switch model.state {
        case .idle:
            Label("Ear detects the language. Voz transcribes. Title names the document.",
                  systemImage: "point.3.connected.trianglepath.dotted")
                .statusCard()
        case .working(let message):
            HStack(spacing: 14) {
                ProgressView()
                    .controlSize(.small)
                Text(message)
                    .fontWeight(.medium)
                Spacer()
                Text("First use downloads the models")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .statusCard()
        case .failed(let message):
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .textSelection(.enabled)
                Spacer()
                if model.selectedURL != nil {
                    Button("Try again") { model.retry() }
                        .buttonStyle(.bordered)
                }
            }
            .statusCard()
        case .complete(let result):
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(result.title)
                            .font(.title3.weight(.semibold))
                            .textSelection(.enabled)
                        Text(completionDetail(result))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.57, green: 0.92, blue: 0.72))
                }
                HStack {
                    Button("Open transcript") { model.openTranscript() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.22, green: 0.56, blue: 0.39))
                    Button("Show in Finder") { model.revealTranscript() }
                        .buttonStyle(.bordered)
                    Spacer()
                    Text(result.outputURL.lastPathComponent)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .statusCard()
        }
    }

    private func completionDetail(_ result: AppModel.Completion) -> String {
        let language = Locale.current.localizedString(forLanguageCode: result.languageCode)
            ?? result.languageCode.uppercased()
        let confidence = Int((result.confidence * 100).rounded())
        return "\(language) · \(confidence)% detection · \(TranscriptDocument.timestamp(result.duration))"
    }
}

private extension View {
    func statusCard() -> some View {
        padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.08))
            }
    }
}
