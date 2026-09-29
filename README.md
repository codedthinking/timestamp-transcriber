# Timestamp Transcriber

Timestamp Transcriber is a native macOS app that turns an M4A recording into a titled, timestamped text document. Processing stays on the Mac.

## Powered by Desert Ant

The app is a deliberately thin SwiftUI front end for [Desert Ant Labs](https://desertant.com/). Their on-device models do the hard work:

- [Ear](https://desertant.com/models/ear/) detects the spoken language.
- [Voz](https://desertant.com/models/voz/) transcribes speech with word timestamps.
- [Title](https://desertant.com/models/title/) generates a short title from the transcript.

The models are fast, local, and require no account or per-minute API billing. Audio and transcript text are not uploaded. Voz already supplies the timestamps this app needs, so it does not run Align.

## Install

Timestamp Transcriber requires macOS 15 or later on Apple silicon.

1. Install the Desert Ant runtime:

   ```sh
   brew install desert-ant-labs/tap/desertant
   ```

2. Download the macOS ARM64 disk image from the [latest release](https://github.com/codedthinking/timestamp-transcriber/releases/latest).
3. Drag `Timestamp Transcriber.app` to Applications.
4. On first launch, right-click the app and choose Open. The release is ad-hoc signed because this project does not have an Apple Developer ID certificate.

The first transcription downloads the Ear, Voz, and Title model weights. Later runs use Desert Ant's local model cache.

## Use

Drop an M4A on the window, choose one with `Command-O`, or open a recording with the app from Finder. Timestamp Transcriber detects the language, transcribes the recording, generates a title in the transcript's language, and writes `<generated title>.txt` beside the audio. Existing files are never overwritten.

The document starts with the generated title and detected language, followed by one timestamped sentence per line.

## Build

```sh
brew install desert-ant-labs/tap/desertant
./Scripts/build-app.sh
open "build/Timestamp Transcriber.app"
```

Create the distributable DMG and ZIP with:

```sh
./Scripts/package-release.sh
```

## Check

```sh
./Scripts/test.sh
```

## License

Timestamp Transcriber's source code is available under the [MIT License](LICENSE).

The Desert Ant CLI is MIT licensed. Desert Ant model weights are separately licensed under the [Desert Ant Labs Source-Available License 1.0](https://license.desertant.com/1.0) and are not covered by this repository's MIT License.
