# Timestamp Transcriber

## Mission

Choose or drop an M4A recording, transcribe it locally, title it in the detected language, and save a timestamped text document beside the source.

## Working slices

- [ ] Select or drop an audio file and detect its spoken language.
- [ ] Transcribe it locally with sentence timestamps.
- [ ] Generate a title from the transcript and save a named text document.

## Real

- Native SwiftUI macOS interface.
- Desert Ant Ear, Voz, and Title models through the local `desertant` runtime.
- Model weights download once and stay in Desert Ant's managed cache.
- Audio and transcript stay on the Mac.

## Disavowed

- No recording, batch queue, speaker diarization, or cloud fallback.
- Align is intentionally unused: Voz already supplies word timestamps.
- The Desert Ant command-line runtime is installed separately with Homebrew.
