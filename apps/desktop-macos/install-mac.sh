#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "⚡ Compiling SAYN macOS Desktop App..."
swiftc -framework Cocoa -framework SwiftUI -framework Carbon -framework AVFoundation \
  Sources/SaynMac/*.swift -o /tmp/sayn_mac_bin

APP_DIR="/Applications/SAYN.app/Contents/MacOS"
mkdir -p "$APP_DIR"
cp /tmp/sayn_mac_bin "$APP_DIR/SAYN"
chmod +x "$APP_DIR/SAYN"

cat << 'EOF' > /Applications/SAYN.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SAYN</string>
    <key>CFBundleIdentifier</key>
    <string>com.sayn.desktop</string>
    <key>CFBundleName</key>
    <string>SAYN</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.5</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ SAYN.app successfully installed in /Applications/SAYN.app!"
echo "🚀 You can launch it from Spotlight or run: open /Applications/SAYN.app"
echo "👉 Global Hotkey: Option + Space activates the Wispr 3-Piece Pill overlay!"
