# Timestamp Transcriber

Native macOS transcription for `.m4a` recordings. Processing stays on the Mac.

## Run

```sh
brew install desert-ant-labs/tap/desertant
./Scripts/build-app.sh
open build/Timestamp\ Transcriber.app
```

Drop an M4A on the window, choose one with `⌘O`, or open a file with the app from Finder. The app detects the spoken language, transcribes the recording, generates a title from the transcript, and writes `<generated title>.txt` beside the audio. Existing files are never overwritten.

The first transcription downloads Ear, Voz, and Title model weights. Later runs use the local cache.

Requires macOS 15 or later on Apple silicon.

## Check

```sh
./Scripts/test.sh
```
