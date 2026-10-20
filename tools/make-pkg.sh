#!/bin/bash
# make-pkg.sh <apps dir> <version> [out dir]
# Builds "Mac Game Installer-<version>.pkg" from the app bundles in <apps dir>:
#   "Sky Recomp.app"  (Skyward Sword HD, from Apolinario-coder/SkyRecomp)
#   "Mush8.app"       (Mario Kart 8 Deluxe, from c22dev/mush8)
# and the "Build Tears of the Kingdom.app" helper, which this script builds itself (tools/build-totk-helper.sh).
# Each app becomes its own component package installed into /Applications; productbuild joins them behind one
# Installer window where every component can be unticked. The result is unsigned (no Developer ID), so macOS
# asks for a right-click > Open the first time.
set -euo pipefail
cd "$(dirname "$0")/.."
APPS=${1:?apps dir}
VERSION=${2:?version}
OUT=${3:-out}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
ID=com.macgameinstaller

component() {  # id, app path
    local id=$1 app=$2
    [ -d "$app" ] || { echo "missing $app" >&2; return 1; }
    if ! codesign --verify --strict "$app" 2>/dev/null; then
        # the ad-hoc seal does not always survive a zip round trip: sign it again (ad hoc, like upstream does)
        echo "  $app: signature invalid after transfer, re-signing ad hoc"
        codesign --force --deep --sign - "$app"
        codesign --verify --strict "$app" || { echo "$app: cannot be signed" >&2; return 1; }
    fi
    pkgbuild --component "$app" --install-location /Applications --identifier "$ID.$id" --version "$VERSION" \
        "$WORK/$id.pkg" >/dev/null
    echo "  $id.pkg <- $app ($(du -sh "$app" | cut -f1))"
}

echo "Building the helper app"
tools/build-totk-helper.sh "$APPS"

echo "Component packages"
component skyrecomp "$APPS/Sky Recomp.app"
component mush8 "$APPS/Mush8.app"
component totk "$APPS/Build Tears of the Kingdom.app"

sed "s/@VERSION@/$VERSION/g" pkg/distribution.xml > "$WORK/distribution.xml"
mkdir -p "$OUT"
PKG="$OUT/Mac Game Installer-$VERSION.pkg"
rm -f "$PKG"
productbuild --distribution "$WORK/distribution.xml" --resources pkg/resources --package-path "$WORK" "$PKG" >/dev/null
echo "$PKG ($(du -h "$PKG" | cut -f1))"
