# Timestamp Transcriber

Native macOS transcription for `.m4a` and other audio files. Processing stays on the Mac.

## Run

```sh
brew install desert-ant-labs/tap/desertant
./Scripts/build-app.sh
open build/Timestamp\ Transcriber.app
```

The first transcription downloads Ear, Voz, and Title model weights. Later runs use the local cache.

Requires macOS 15 or later on Apple silicon.
