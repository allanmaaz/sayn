#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "⚡ Compiling San Universal 2 Binary (Apple Silicon + Intel)..."
swiftc -O -target arm64-apple-macos11.0 -framework Cocoa -framework SwiftUI -framework Carbon -framework AVFoundation -framework Speech \
  Sources/SaynMac/*.swift -o /tmp/san_mac_arm64

swiftc -O -target x86_64-apple-macos11.0 -framework Cocoa -framework SwiftUI -framework Carbon -framework AVFoundation -framework Speech \
  Sources/SaynMac/*.swift -o /tmp/san_mac_x86_64

lipo -create -output /tmp/san_mac_universal /tmp/san_mac_arm64 /tmp/san_mac_x86_64
file /tmp/san_mac_universal

APP_DIR="/Applications/San.app/Contents/MacOS"
RES_DIR="/Applications/San.app/Contents/Resources"
mkdir -p "$APP_DIR"
mkdir -p "$RES_DIR"

cp /tmp/san_mac_universal "$APP_DIR/San"
chmod +x "$APP_DIR/San"

# Copy Icon and Logo resources
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$RES_DIR/AppIcon.icns"
fi
if [ -f "Resources/logo.png" ]; then
    cp Resources/logo.png "$RES_DIR/logo.png"
fi

cat << 'EOF' > /Applications/San.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>San</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.san.desktop</string>
    <key>CFBundleName</key>
    <string>San</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>San uses your microphone for high-speed voice dictation and AI polishing.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>San uses speech recognition to transcribe your voice directly into your active apps.</string>
</dict>
</plist>
EOF

echo "🔒 Code-signing /Applications/San.app..."
codesign --force --deep --sign - --identifier "com.san.desktop" /Applications/San.app

touch /Applications/San.app
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f /Applications/San.app 2>/dev/null || true

# Kill any existing running instance
pkill -f "/Applications/San.app/Contents/MacOS/San" 2>/dev/null || true
pkill -f "/Applications/SAYN.app/Contents/MacOS/SAYN" 2>/dev/null || true
sleep 0.5

# Launch the newly compiled app
open /Applications/San.app

echo "=========================================================="
echo "✅ San.app successfully compiled, branded, and installed in /Applications/San.app!"
echo "🚀 Launched San background voice assistant!"
echo "👉 Global Hotkey: Press Fn key (or Option + Space) to trigger San dictation with auto-paste!"
echo "=========================================================="
