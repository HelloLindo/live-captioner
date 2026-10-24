#!/bin/sh
# Builds build/LiveCaptioner.app (Apple silicon, macOS 15+).
# FORK_VERSION defaults to 0.1.0; the build number is the commit count.
# Uses SIGN_IDENTITY, an available Developer ID, or ad-hoc signing.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
build_dir=${BUILD_DIR:-"$root/build"}
app="$build_dir/LiveCaptioner.app"
version=${FORK_VERSION:-0.1.0}
build=$(git -C "$root" rev-list --count HEAD)
identities=$(security find-identity -p codesigning)
identity=${SIGN_IDENTITY:-$(echo "$identities" | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -1)}

swift build -c release --arch arm64 --package-path "$root/app"
bin=$(swift build -c release --arch arm64 --package-path "$root/app" --show-bin-path)

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/LiveCaptioner" "$app/Contents/MacOS/LiveCaptioner"
# PermissionFlow's strings, where its lookup finds them.
ditto "$bin/PermissionFlow_PermissionFlow.bundle" "$app/Contents/Resources/PermissionFlow_PermissionFlow.bundle"
cp "$root/app/Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
licenses="$app/Contents/Resources/Licenses"
checkouts="$root/app/.build/checkouts"
mkdir -p "$licenses"
cp "$root/LICENSE" "$licenses/LiveCaptioner.txt"
cp "$checkouts/FluidAudio/LICENSE" "$licenses/FluidAudio.txt"
cp "$checkouts/FluidAudio/ThirdPartyLicenses/"* "$licenses/"
cp "$checkouts/PermissionFlow/LICENSE" "$licenses/PermissionFlow.txt"
for catalog in Localizable InfoPlist; do
    xcrun xcstringstool compile "$root/app/Resources/$catalog.xcstrings" --output-directory "$app/Contents/Resources"
done
mkdir -p "$app/Contents/Resources/en.lproj"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>io.github.hellolindo.livecaptioner</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleName</key><string>Live Captioner</string>
  <key>CFBundleDisplayName</key><string>Live Captioner</string>
  <key>CFBundleExecutable</key><string>LiveCaptioner</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$build</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
  <key>LSUIElement</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHumanReadableCopyright</key><string>Based on Parakeet © 2026 LPFchan. Live Captioner contributors.</string>
  <key>NSAudioCaptureUsageDescription</key><string>Live Captioner listens to system audio to show live captions. Audio never leaves this Mac.</string>
</dict>
</plist>
PLIST

if [ -n "$identity" ]; then
    case $identity in Developer\ ID*) flags="--timestamp --options runtime" ;; *) flags= ;; esac
    codesign --force $flags --sign "$identity" "$app"
    echo "signed: $identity"
else
    codesign --force --sign - "$app"
    echo "signed: ad-hoc (macOS may ask for audio permission again after rebuilding)"
fi
echo "$app ($version, build $build)"
