#!/bin/sh
# Builds Stay Awake.app and installs it into ~/Applications.
set -eu
cd "$(dirname "$0")"

APP="build/Stay Awake.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS"
swiftc -O -swift-version 5 -parse-as-library -o "$APP/Contents/MacOS/StayAwake" StayAwake.swift
cp Info.plist "$APP/Contents/Info.plist"

# App icon: render the 1024px master, then scale it into an .icns.
ICONSET=build/AppIcon.iconset
mkdir -p "$ICONSET" "$APP/Contents/Resources"
swift make-icon.swift build/icon.png
for px in 16 32 128 256 512; do
    sips -z $px $px build/icon.png --out "$ICONSET/icon_${px}x${px}.png" >/dev/null
    sips -z $((px * 2)) $((px * 2)) build/icon.png --out "$ICONSET/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP"

mkdir -p "$HOME/Applications"
pkill -x StayAwake 2>/dev/null || true
rm -rf "$HOME/Applications/Stay Awake.app"
cp -R "$APP" "$HOME/Applications/"
open "$HOME/Applications/Stay Awake.app"
echo "Installed: $HOME/Applications/Stay Awake.app"
