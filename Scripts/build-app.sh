#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

swift build --configuration release --arch arm64
BIN_PATH=$(swift build --configuration release --arch arm64 --show-bin-path)
APP="$ROOT/build/Timestamp Transcriber.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_PATH/Timestamp" "$APP/Contents/MacOS/Timestamp"
cp "$ROOT/Sources/Info.plist" "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"

printf 'Built %s\n' "$APP"
