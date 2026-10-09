#!/bin/bash
# Baut path.app (Release) im Ordner build/
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP=build/path.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/path" "$APP/Contents/MacOS/path"
cp Resources/AppIcon.icns Resources/MenuBarIcon.png "$APP/Contents/Resources/"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Fertig: $APP"
