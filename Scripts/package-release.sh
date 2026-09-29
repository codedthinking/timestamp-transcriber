#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Sources/Info.plist")
APP="$ROOT/build/Timestamp Transcriber.app"
DIST="$ROOT/dist"
STAGING="$ROOT/build/dmg"
BASE="Timestamp-Transcriber-$VERSION-macOS-arm64"
DMG="$DIST/$BASE.dmg"
ZIP="$DIST/$BASE.zip"

"$ROOT/Scripts/build-app.sh"
rm -rf "$DIST" "$STAGING"
mkdir -p "$DIST" "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
cp "$ROOT/LICENSE" "$STAGING/LICENSE.txt"

hdiutil create \
    -volname "Timestamp Transcriber" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG"

ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
(
    cd "$DIST"
    shasum -a 256 "$(basename "$DMG")" "$(basename "$ZIP")" > SHA256SUMS.txt
)

printf 'Packaged %s\n' "$DMG"
printf 'Packaged %s\n' "$ZIP"
