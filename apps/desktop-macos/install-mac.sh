#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "⚡ Building SAYN production release binary..."
swift build -c release
BIN_SOURCE=".build/release/SaynMac"
if [ ! -f "$BIN_SOURCE" ]; then
    BIN_SOURCE=".build/debug/SaynMac"
fi

APP_DIR="/Applications/SAYN.app/Contents/MacOS"
RES_DIR="/Applications/SAYN.app/Contents/Resources"
mkdir -p "$APP_DIR"
mkdir -p "$RES_DIR"

cp "$BIN_SOURCE" "$APP_DIR/SAYN"
chmod +x "$APP_DIR/SAYN"

# Copy Icon and Logo resources
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$RES_DIR/AppIcon.icns"
fi
if [ -f "Resources/logo.png" ]; then
    cp Resources/logo.png "$RES_DIR/logo.png"
fi

cat << 'EOF' > /Applications/SAYN.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SAYN</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.sayn.desktop</string>
    <key>CFBundleName</key>
    <string>SAYN</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSMicrophoneUsageDescription</key>
    <string>SAYN uses your microphone for high-speed voice dictation and AI polishing.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>SAYN uses speech recognition to transcribe your voice directly into your active apps.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>SAYN uses automation to type your polished speech directly into active applications and terminals.</string>
</dict>
</plist>
EOF

echo "🔒 Code-signing /Applications/SAYN.app..."
codesign --force --deep --sign - --identifier "com.sayn.desktop" /Applications/SAYN.app

touch /Applications/SAYN.app
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f /Applications/SAYN.app 2>/dev/null || true

# Kill any existing running instance
pkill -f "/Applications/San.app/Contents/MacOS/San" 2>/dev/null || true
pkill -f "/Applications/SAYN.app/Contents/MacOS/SAYN" 2>/dev/null || true
pkill -f "SAYN" 2>/dev/null || true
pkill -f "San" 2>/dev/null || true
sleep 0.5

# Also remove old San.app if present
rm -rf /Applications/San.app 2>/dev/null || true

# Launch the newly compiled app
open /Applications/SAYN.app

echo "=========================================================="
echo "✅ SAYN.app successfully compiled, branded, and installed in /Applications/SAYN.app!"
echo "🚀 Launched SAYN background voice assistant!"
echo "👉 Global Hotkey: Press Fn key (or Option + Space) to trigger SAYN dictation with auto-paste!"
echo "=========================================================="
