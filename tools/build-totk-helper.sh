#!/bin/bash
# build-totk-helper.sh [out dir]: builds "Build Tears of the Kingdom.app" (default: into build/).
# A small AppleScript app: it asks for your game file, prod.keys (and firmware / update when needed) with file
# pickers, then runs tools/build-totk.sh in Terminal, which clones MacNativeGames and builds the game into
# /Applications. The helper carries no game data and nothing from MacNativeGames; it fetches that at build time.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:-build}
APP="$OUT/Build Tears of the Kingdom.app"
mkdir -p "$OUT"
rm -rf "$APP"
osacompile -o "$APP" totk-helper/main.applescript
cp tools/build-totk.sh "$APP/Contents/Resources/build-totk.sh"
chmod +x "$APP/Contents/Resources/build-totk.sh"
P="$APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string com.macgameinstaller.totk-builder "$P"
plutil -replace CFBundleName -string "Build Tears of the Kingdom" "$P"
plutil -replace CFBundleShortVersionString -string "${VERSION:-0.1}" "$P"
plutil -replace LSMinimumSystemVersion -string "14.0" "$P"
plutil -replace LSApplicationCategoryType -string public.app-category.games "$P"
plutil -replace NSAppleEventsUsageDescription -string "Build Tears of the Kingdom runs the build in Terminal." "$P"
codesign --force --deep --sign - "$APP"
codesign --verify --strict "$APP"
echo "$APP"
