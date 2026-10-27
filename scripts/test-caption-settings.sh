#!/bin/sh
# Native UI regression checks; requires a logged-in macOS desktop session.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
out="$root/build/caption-tests"
mkdir -p "$out"
xcrun swiftc -swift-version 5 -Onone -parse-as-library -target arm64-apple-macos15.0 \
    -module-cache-path "$out/module-cache" \
    "$root/app/Sources/Parakeet/CaptionPanel.swift" "$root/tests/CaptionSettingsValidation.swift" \
    -o "$out/caption-settings-tests"
cd "$root"
"$out/caption-settings-tests"
