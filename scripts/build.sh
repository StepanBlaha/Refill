#!/bin/zsh
# Build Refill.app (release, ad-hoc signed). Usage: scripts/build.sh [--install] [--run]
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
APP=build/Refill.app
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS"
cp .build/release/Refill "$APP/Contents/MacOS/Refill"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>cz.stepanblaha.refill</string>
  <key>CFBundleName</key><string>Refill</string>
  <key>CFBundleExecutable</key><string>Refill</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force -s - "$APP"
if [[ "${1:-}" == "--install" || "${2:-}" == "--install" ]]; then
  rm -rf /Applications/Refill.app && cp -R "$APP" /Applications/ && APP=/Applications/Refill.app
fi
if [[ " $* " == *" --run "* ]]; then pkill -x Refill && sleep 1 || true; open "$APP"; fi
echo "Built $APP"
