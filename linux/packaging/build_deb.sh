#!/usr/bin/env bash
set -e

# Build script for Debian / Ubuntu .deb package
VERSION="1.0.0"
ARCH="amd64"
APP_NAME="gitora"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
DEB_ROOT="$PROJECT_ROOT/build/deb_package"
OUTPUT_DIR="$PROJECT_ROOT/dist"

echo "==> [1/4] Checking Linux build bundle..."
if [ ! -d "$BUILD_DIR" ]; then
    echo "Bundle not found at $BUILD_DIR. Running flutter build linux --release..."
    cd "$PROJECT_ROOT"
    flutter build linux --release
fi

echo "==> [2/4] Preparing DEB package structure..."
rm -rf "$DEB_ROOT"
mkdir -p "$DEB_ROOT/DEBIAN"
mkdir -p "$DEB_ROOT/usr/lib/gitora"
mkdir -p "$DEB_ROOT/usr/bin"
mkdir -p "$DEB_ROOT/usr/share/applications"
mkdir -p "$DEB_ROOT/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$DEB_ROOT/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$OUTPUT_DIR"

# Copy binary bundle
cp -r "$BUILD_DIR/"* "$DEB_ROOT/usr/lib/gitora/"

# Create symlink launcher in /usr/bin
cat << 'EOF' > "$DEB_ROOT/usr/bin/gitora"
#!/bin/sh
exec /usr/lib/gitora/gitora "$@"
EOF
chmod +x "$DEB_ROOT/usr/bin/gitora"

# Copy desktop file and icons
cp "$SCRIPT_DIR/dev.skrinvex.gitora.desktop" "$DEB_ROOT/usr/share/applications/"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.png" "$DEB_ROOT/usr/share/icons/hicolor/512x512/apps/"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.svg" "$DEB_ROOT/usr/share/icons/hicolor/scalable/apps/"

# Create control file
cat << EOF > "$DEB_ROOT/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Section: devel
Priority: optional
Architecture: $ARCH
Maintainer: SkrinVex <dev@skrinvex.dev>
Depends: libc6, libgtk-3-0, git
Recommends: libgit2-dev | libgit2-1.7 | libgit2-1.5 | libgit2-1.3
Description: Powerful Git. Beautifully Simple.
 Gitora is a professional, high-performance cross-platform desktop Git client
 built with Flutter and Material 3 Expressive aesthetics.
EOF

echo "==> [3/4] Building .deb package..."
dpkg-deb --build "$DEB_ROOT" "$OUTPUT_DIR/gitora_${VERSION}_${ARCH}.deb"

echo "==> [4/4] Package created successfully: $OUTPUT_DIR/gitora_${VERSION}_${ARCH}.deb"
