#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
mkdir -p .build/checks

swiftc \
    -swift-version 6 \
    Sources/Timestamp/TranscriptDocument.swift \
    Sources/Timestamp/DesertAntClient.swift \
    Tests/Checks.swift \
    -o .build/checks/TimestampChecks

.build/checks/TimestampChecks
