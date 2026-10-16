#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$DIR/../.." && pwd )"
RELEASE_DIR="$PROJECT_ROOT/release"
DMG_STAGE="/tmp/sayn_dmg_stage"
DMG_NAME="SAYN-macOS-Installer.dmg"
FINAL_DMG="$RELEASE_DIR/$DMG_NAME"

echo "=========================================="
echo "⚡ Building SAYN macOS Drag-and-Drop DMG"
echo "=========================================="

mkdir -p "$RELEASE_DIR"
rm -rf "$DMG_STAGE"
mkdir -p "$DMG_STAGE"

# 1. Compile Universal 2 binary (Apple Silicon arm64 + Intel x86_64)
echo "🔨 Compiling Universal macOS Binary for SAYN (Apple Silicon + Intel)..."
swiftc -O -target arm64-apple-macos11.0 -framework Cocoa -framework SwiftUI -framework Carbon -framework AVFoundation -framework Speech \
  "$DIR"/Sources/SaynMac/*.swift -o /tmp/sayn_mac_arm64

swiftc -O -target x86_64-apple-macos11.0 -framework Cocoa -framework SwiftUI -framework Carbon -framework AVFoundation -framework Speech \
  "$DIR"/Sources/SaynMac/*.swift -o /tmp/sayn_mac_x86_64

lipo -create -output /tmp/sayn_mac_universal /tmp/sayn_mac_arm64 /tmp/sayn_mac_x86_64
file /tmp/sayn_mac_universal

APP_BUNDLE="$DMG_STAGE/SAYN.app"
APP_DIR="$APP_BUNDLE/Contents/MacOS"
RES_DIR="$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_DIR"
mkdir -p "$RES_DIR"

cp /tmp/sayn_mac_universal "$APP_DIR/SAYN"
chmod +x "$APP_DIR/SAYN"

if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$RES_DIR/AppIcon.icns"
fi
if [ -f "$DIR/Resources/logo.png" ]; then
    cp "$DIR/Resources/logo.png" "$RES_DIR/logo.png"
fi

cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
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
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>SAYN uses your microphone for real-time speech dictation and AI polishing.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>SAYN uses speech recognition to transcribe your voice directly into your active apps.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>SAYN uses automation to type your polished speech directly into active applications and terminals.</string>
</dict>
</plist>
EOF

echo "🔒 Code-signing DMG app bundle..."
codesign --force --deep --sign - --identifier "com.sayn.desktop" "$APP_BUNDLE"

# 2. Add symlink to /Applications for Drag-and-Drop installation
echo "🔗 Creating /Applications symlink..."
ln -s /Applications "$DMG_STAGE/Applications"

# 3. Add clean installer README
cat << 'EOF' > "$DMG_STAGE/README.txt"
SAYN for macOS — Voice Dictation & AI Polish
============================================

Installation:
1. Drag "SAYN.app" into the "Applications" folder.
2. Launch SAYN from Applications or Spotlight.
3. Grant Accessibility & Microphone permissions when prompted.
4. Press 'Fn' (or Option + Space) anywhere on your Mac to start speaking!
   As soon as you finish, SAYN polishes your speech and automatically types it directly into your active text box or chat!

SAYN: Speak naturally. Polish instantly.
EOF

# 4. Generate compressed read-only DMG with hdiutil
echo "📦 Packing into $DMG_NAME..."
rm -f "$FINAL_DMG"
hdiutil create -volname "SAYN Installer" -srcfolder "$DMG_STAGE" -ov -format UDZO "$FINAL_DMG"

# Also maintain backward-compatible copy for San-macOS-Installer.dmg
cp "$FINAL_DMG" "$RELEASE_DIR/San-macOS-Installer.dmg"

# Clean up temporary staging
rm -rf "$DMG_STAGE"

echo "=========================================="
echo "✅ Successfully built: $FINAL_DMG"
ls -lh "$FINAL_DMG"
echo "=========================================="
