#!/bin/sh
# Launch only this checkout's custom app. No installation or updater is involved.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
app="$root/build/LiveCaptioner.app"

if [ ! -f "$app/Contents/Info.plist" ] || [ ! -x "$app/Contents/MacOS/LiveCaptioner" ]; then
    echo "Build the app first with scripts/build-app.sh." >&2
    exit 1
fi

if pgrep -f '/LiveCaptioner[.]app/Contents/MacOS/LiveCaptioner' >/dev/null; then
    echo "Live Captioner is already running. Quit it from its menu before launching this custom copy." >&2
    exit 1
fi

open -n "$app"
