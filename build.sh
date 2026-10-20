#!/bin/sh
# Builds Stay Awake.app and installs it into ~/Applications.
set -eu
cd "$(dirname "$0")"

APP="build/Stay Awake.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS"
swiftc -O -swift-version 5 -parse-as-library -o "$APP/Contents/MacOS/StayAwake" StayAwake.swift
cp Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"

mkdir -p "$HOME/Applications"
pkill -x StayAwake 2>/dev/null || true
rm -rf "$HOME/Applications/Stay Awake.app"
cp -R "$APP" "$HOME/Applications/"
open "$HOME/Applications/Stay Awake.app"
echo "Installed: $HOME/Applications/Stay Awake.app"
