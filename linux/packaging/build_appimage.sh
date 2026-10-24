#!/usr/bin/env bash
set -e

# Build script for Linux AppImage
VERSION="1.0.0"
APP_NAME="Gitora"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
APP_DIR="$PROJECT_ROOT/build/AppDir"
OUTPUT_DIR="$PROJECT_ROOT/dist"

echo "==> [1/4] Checking Linux build bundle..."
if [ ! -d "$BUILD_DIR" ]; then
    echo "Bundle not found at $BUILD_DIR. Running flutter build linux --release..."
    cd "$PROJECT_ROOT"
    flutter build linux --release
fi

echo "==> [2/4] Assembling AppDir structure..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$OUTPUT_DIR"

# Copy flutter bundle into AppDir
cp -r "$BUILD_DIR/"* "$APP_DIR/usr/bin/"

# AppRun script
cat << 'EOF' > "$APP_DIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/gitora" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# Desktop file and icon at root of AppDir (required by AppImage standard)
cp "$SCRIPT_DIR/dev.skrinvex.gitora.desktop" "$APP_DIR/gitora.desktop"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.desktop" "$APP_DIR/usr/share/applications/"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.png" "$APP_DIR/gitora.png"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.png" "$APP_DIR/dev.skrinvex.gitora.png"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.png" "$APP_DIR/usr/share/icons/hicolor/512x512/apps/"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.svg" "$APP_DIR/usr/share/icons/hicolor/scalable/apps/"

echo "==> [3/4] Downloading / checking appimagetool..."
if ! command -v appimagetool &> /dev/null; then
    APPIMAGETOOL="$PROJECT_ROOT/build/appimagetool-x86_64.AppImage"
    if [ ! -f "$APPIMAGETOOL" ]; then
        curl -L -o "$APPIMAGETOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
        chmod +x "$APPIMAGETOOL"
    fi
else
    APPIMAGETOOL="appimagetool"
fi

echo "==> [4/4] Generating AppImage..."
ARCH=x86_64 "$APPIMAGETOOL" "$APP_DIR" "$OUTPUT_DIR/Gitora-${VERSION}-x86_64.AppImage"

echo "==> AppImage created successfully: $OUTPUT_DIR/Gitora-${VERSION}-x86_64.AppImage"
