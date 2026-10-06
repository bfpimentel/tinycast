#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1
DERIVED="build/DerivedData"
BUILD_SETTINGS=(
    ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY=- OTHER_CODE_SIGN_FLAGS=--timestamp=none
)
if [ "$#" -gt 0 ]; then
    if [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "✗ Use a stable version such as 0.11.13." >&2
        exit 1
    fi
    BUILD_SETTINGS+=("MARKETING_VERSION=$1")
fi
if [ -n "${BUILD_NUMBER:-}" ]; then
    BUILD_SETTINGS+=("CURRENT_PROJECT_VERSION=$BUILD_NUMBER")
fi

echo "▸ Building ad-hoc signed Tinycast.app (arm64 Release)…"
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath "$DERIVED" \
    "${BUILD_SETTINGS[@]}" build

APP="$DERIVED/Build/Products/Release/Tinycast.app"
MINIMUM="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$APP/Contents/Info.plist")"
if [ "$MINIMUM" != "26.0" ]; then
    echo "✗ Expected a macOS 26.0 minimum, got $MINIMUM." >&2
    exit 1
fi
for BIN in "$APP/Contents/MacOS/Tinycast" "$APP/Contents/Helpers/ClipboardTextHelper" "$APP/Contents/Helpers/Tinycast Dictation.app/Contents/MacOS/Tinycast Dictation"; do
    SLICES="$(lipo -archs "$BIN")"
    if [ "$SLICES" != "arm64" ]; then
        echo "✗ ${BIN##*/}: expected arm64 alone, got '$SLICES'." >&2
        exit 1
    fi
done
./Scripts/verify-signature.sh "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
DMG="build/Tinycast-${VERSION}.dmg"
echo "▸ Packaging ${DMG}"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
diskutil image create from "$STAGE" --format UDZO --volumeName "Tinycast" "$DMG" >/dev/null
echo "✓ $DMG"
