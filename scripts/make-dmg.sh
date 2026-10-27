#!/bin/sh
# Package the built app using macOS tools; no third-party packaging download.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
build_dir=${BUILD_DIR:-"$root/build"}
app="$build_dir/LiveCaptioner.app"

if [ ! -f "$app/Contents/Info.plist" ] || [ ! -x "$app/Contents/MacOS/LiveCaptioner" ]; then
    echo "Build the app first with scripts/build-app.sh." >&2
    exit 1
fi
codesign --verify --deep --strict "$app"

work=$(mktemp -d "$build_dir/dmg.XXXXXX")
trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM
mkdir "$work/contents"
# Keep local extended attributes and quarantine metadata out of the payload.
ditto --norsrc --noextattr --noqtn "$app" "$work/contents/LiveCaptioner.app"
codesign --verify --deep --strict "$work/contents/LiveCaptioner.app"
ln -s /Applications "$work/contents/Applications"
cp "$root/Packaging/Installation.txt" "$work/contents/Installation.txt"

hdiutil create -volname "Live Captioner" -srcfolder "$work/contents" \
    -fs HFS+ -format UDZO -imagekey zlib-level=9 "$work/LiveCaptioner.dmg"
hdiutil verify "$work/LiveCaptioner.dmg"
mv -f "$work/LiveCaptioner.dmg" "$build_dir/LiveCaptioner.dmg"
(cd "$build_dir" && shasum -a 256 LiveCaptioner.dmg > LiveCaptioner.dmg.sha256)
echo "$build_dir/LiveCaptioner.dmg"
