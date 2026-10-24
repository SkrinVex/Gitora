#!/usr/bin/env bash
set -e

# Package Gitora into a standalone portable tar.gz with installer script
VERSION="1.0.0"
ARCH="x64"
PACKAGE_NAME="Gitora-Linux-${ARCH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
STAGE_DIR="$PROJECT_ROOT/build/tarball_stage/$PACKAGE_NAME"
OUTPUT_DIR="$PROJECT_ROOT/dist"

echo "==> [1/3] Checking bundle at $BUILD_DIR..."
if [ ! -d "$BUILD_DIR" ]; then
    echo "Bundle not found. Running flutter build linux --release..."
    cd "$PROJECT_ROOT"
    flutter build linux --release
fi

echo "==> [2/3] Staging standalone package..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/bundle"
mkdir -p "$OUTPUT_DIR"

# Copy binary bundle
cp -r "$BUILD_DIR/"* "$STAGE_DIR/bundle/"

# Copy installer and assets
cp "$SCRIPT_DIR/install.sh" "$STAGE_DIR/"
chmod +x "$STAGE_DIR/install.sh"

cp "$SCRIPT_DIR/dev.skrinvex.gitora.desktop" "$STAGE_DIR/"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.png" "$STAGE_DIR/"
cp "$SCRIPT_DIR/dev.skrinvex.gitora.svg" "$STAGE_DIR/"

cat << 'EOF' > "$STAGE_DIR/README.txt"
Gitora - Powerful Git. Beautifully Simple.
=========================================

To install Gitora on your system:
  sudo ./install.sh       (for system-wide installation)
  ./install.sh            (for current user only, installs to ~/.local)

To uninstall:
  sudo ./install.sh --uninstall
EOF

echo "==> [3/3] Creating tar.gz archive..."
cd "$PROJECT_ROOT/build/tarball_stage"
tar -czf "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

echo "==> Package created: $OUTPUT_DIR/${PACKAGE_NAME}.tar.gz"
