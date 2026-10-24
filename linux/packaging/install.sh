#!/usr/bin/env bash
set -e

# Gitora Linux Installer
APP_NAME="gitora"
DISPLAY_NAME="Gitora"
VERSION="1.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}========================================${NC}"
echo -e "${BLUE}${BOLD}  ${DISPLAY_NAME} v${VERSION} — Linux Installer    ${NC}"
echo -e "${BLUE}${BOLD}========================================${NC}"

# Handle uninstall flag
if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
    echo -e "${BLUE}==> Uninstalling ${DISPLAY_NAME}...${NC}"
    if [ "$EUID" -eq 0 ]; then
        INSTALL_DIR="/usr/local/lib/gitora"
        BIN_LINK="/usr/local/bin/gitora"
        DESKTOP_FILE="/usr/share/applications/dev.skrinvex.gitora.desktop"
        ICON_PNG="/usr/share/icons/hicolor/512x512/apps/dev.skrinvex.gitora.png"
        ICON_SVG="/usr/share/icons/hicolor/scalable/apps/dev.skrinvex.gitora.svg"
    else
        INSTALL_DIR="$HOME/.local/lib/gitora"
        BIN_LINK="$HOME/.local/bin/gitora"
        DESKTOP_FILE="$HOME/.local/share/applications/dev.skrinvex.gitora.desktop"
        ICON_PNG="$HOME/.local/share/icons/hicolor/512x512/apps/dev.skrinvex.gitora.png"
        ICON_SVG="$HOME/.local/share/icons/hicolor/scalable/apps/dev.skrinvex.gitora.svg"
    fi

    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_LINK" "$DESKTOP_FILE" "$ICON_PNG" "$ICON_SVG"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$(dirname "$DESKTOP_FILE")" >/dev/null 2>&1 || true
    fi

    echo -e "${GREEN}==> ${DISPLAY_NAME} has been uninstalled successfully.${NC}"
    exit 0
fi

# Detect install target
if [ "$EUID" -eq 0 ]; then
    echo -e "Installing for: ${BOLD}System-wide (all users)${NC}"
    INSTALL_DIR="/usr/local/lib/gitora"
    BIN_DIR="/usr/local/bin"
    DESKTOP_DIR="/usr/share/applications"
    ICON_DIR_PNG="/usr/share/icons/hicolor/512x512/apps"
    ICON_DIR_SVG="/usr/share/icons/hicolor/scalable/apps"
else
    echo -e "Installing for: ${BOLD}Current user (~/.local)${NC}"
    echo -e "${BLUE}(Hint: Run with 'sudo ./install.sh' for system-wide installation)${NC}"
    INSTALL_DIR="$HOME/.local/lib/gitora"
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"
    ICON_DIR_PNG="$HOME/.local/share/icons/hicolor/512x512/apps"
    ICON_DIR_SVG="$HOME/.local/share/icons/hicolor/scalable/apps"
fi

echo -e "\n${BLUE}==> [1/4] Preparing directories...${NC}"
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR_PNG" "$ICON_DIR_SVG"

echo -e "${BLUE}==> [2/4] Copying application files...${NC}"
rm -rf "$INSTALL_DIR"/*
cp -r "$SCRIPT_DIR/bundle/"* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/gitora"

# Create launcher symlink / script
cat << EOF > "$BIN_DIR/gitora"
#!/bin/sh
exec "$INSTALL_DIR/gitora" "\$@"
EOF
chmod +x "$BIN_DIR/gitora"

echo -e "${BLUE}==> [3/4] Installing application icon and desktop launcher...${NC}"
if [ -f "$SCRIPT_DIR/dev.skrinvex.gitora.png" ]; then
    cp "$SCRIPT_DIR/dev.skrinvex.gitora.png" "$ICON_DIR_PNG/"
fi
if [ -f "$SCRIPT_DIR/dev.skrinvex.gitora.svg" ]; then
    cp "$SCRIPT_DIR/dev.skrinvex.gitora.svg" "$ICON_DIR_SVG/"
fi

# Create desktop file with correct Exec path
cat << EOF > "$DESKTOP_DIR/dev.skrinvex.gitora.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Gitora
GenericName=Git Client
Comment=Powerful Git. Beautifully Simple.
Exec=$INSTALL_DIR/gitora %U
Icon=dev.skrinvex.gitora
Terminal=false
Categories=Development;RevisionControl;
Keywords=git;version;control;gitora;
StartupWMClass=gitora
MimeType=x-scheme-handler/gitora;
EOF
chmod +x "$DESKTOP_DIR/dev.skrinvex.gitora.desktop"

echo -e "${BLUE}==> [4/4] Updating desktop databases...${NC}"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$(dirname "$(dirname "$(dirname "$ICON_DIR_PNG")")")" >/dev/null 2>&1 || true
fi

echo -e "\n${GREEN}${BOLD}✔ Installation completed successfully!${NC}"
echo -e "You can now launch Gitora from your applications menu or by running: ${BOLD}gitora${NC}"
echo -e "To uninstall in the future, run: ${BOLD}./install.sh --uninstall${NC}\n"
