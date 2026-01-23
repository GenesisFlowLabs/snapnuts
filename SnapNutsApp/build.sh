#!/bin/bash
set -e

# SnapNuts Build Script
# Creates a proper macOS app bundle with Sparkle auto-updates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="SnapNuts"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SPARKLE_FRAMEWORK="$SCRIPT_DIR/Frameworks/Sparkle.framework"

echo "Building SnapNuts..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"

# Compile Swift sources
echo "Compiling Swift sources..."
swiftc \
    -O \
    -whole-module-optimization \
    -target arm64-apple-macosx13.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Carbon \
    -framework ApplicationServices \
    -F "$SCRIPT_DIR/Frameworks" \
    -framework Sparkle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -parse-as-library \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "$SCRIPT_DIR/Sources/SnapNuts/SnapNutsApp.swift" \
    "$SCRIPT_DIR/Sources/SnapNuts/WindowManager.swift" \
    "$SCRIPT_DIR/Sources/SnapNuts/HotkeyManager.swift" \
    "$SCRIPT_DIR/Sources/SnapNuts/AlertWindow.swift" \
    "$SCRIPT_DIR/Sources/SnapNuts/SettingsView.swift" \
    "$SCRIPT_DIR/Sources/SnapNuts/ShortcutRecorder.swift" \
    "$SCRIPT_DIR/Sources/SnapNuts/OnboardingView.swift"

echo "Swift compilation complete."

# Copy Info.plist
cp "$SCRIPT_DIR/Sources/SnapNuts/Info.plist" "$APP_BUNDLE/Contents/"

# Copy Sparkle framework
echo "Embedding Sparkle framework..."
cp -R "$SPARKLE_FRAMEWORK" "$APP_BUNDLE/Contents/Frameworks/"

# Copy Resources
echo "Copying resources..."

# Copy app icons
if [ -d "$SCRIPT_DIR/Resources/AppIcon.appiconset" ]; then
    # Create icns from iconset
    mkdir -p "$BUILD_DIR/AppIcon.iconset"
    cp "$SCRIPT_DIR/Resources/AppIcon.appiconset/"*.png "$BUILD_DIR/AppIcon.iconset/" 2>/dev/null || true

    # Rename to match iconutil expectations
    cd "$BUILD_DIR/AppIcon.iconset"
    [ -f "icon_16x16.png" ] && mv "icon_16x16.png" "icon_16x16.png" 2>/dev/null || true
    [ -f "icon_16x16@2x.png" ] && mv "icon_16x16@2x.png" "icon_16x16@2x.png" 2>/dev/null || true
    [ -f "icon_32x32.png" ] && mv "icon_32x32.png" "icon_32x32.png" 2>/dev/null || true
    [ -f "icon_32x32@2x.png" ] && mv "icon_32x32@2x.png" "icon_32x32@2x.png" 2>/dev/null || true
    [ -f "icon_128x128.png" ] && mv "icon_128x128.png" "icon_128x128.png" 2>/dev/null || true
    [ -f "icon_128x128@2x.png" ] && mv "icon_128x128@2x.png" "icon_128x128@2x.png" 2>/dev/null || true
    [ -f "icon_256x256.png" ] && mv "icon_256x256.png" "icon_256x256.png" 2>/dev/null || true
    [ -f "icon_256x256@2x.png" ] && mv "icon_256x256@2x.png" "icon_256x256@2x.png" 2>/dev/null || true
    [ -f "icon_512x512.png" ] && mv "icon_512x512.png" "icon_512x512.png" 2>/dev/null || true
    [ -f "icon_512x512@2x.png" ] && mv "icon_512x512@2x.png" "icon_512x512@2x.png" 2>/dev/null || true
    cd "$SCRIPT_DIR"

    # Generate icns
    iconutil -c icns "$BUILD_DIR/AppIcon.iconset" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null || {
        echo "Warning: Could not create icns file, copying PNG directly"
        cp "$SCRIPT_DIR/Resources/AppIcon.appiconset/icon_512x512@2x.png" "$APP_BUNDLE/Contents/Resources/AppIcon.png" 2>/dev/null || true
    }
fi

# Copy status bar icons
[ -f "$SCRIPT_DIR/Resources/StatusBarIcon.png" ] && cp "$SCRIPT_DIR/Resources/StatusBarIcon.png" "$APP_BUNDLE/Contents/Resources/"
[ -f "$SCRIPT_DIR/Resources/StatusBarIcon@2x.png" ] && cp "$SCRIPT_DIR/Resources/StatusBarIcon@2x.png" "$APP_BUNDLE/Contents/Resources/"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Sign the app and embedded frameworks
echo "Signing app..."
codesign --force --deep --sign - "$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "Build complete!"
echo "App location: $APP_BUNDLE"
echo ""
echo "To run: open \"$APP_BUNDLE\""
