#!/bin/bash
# ZestSync Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jakerains/zestsync/main/install.sh | bash

set -e

REPO="jakerains/zestsync"
INSTALL_DIR="$HOME/.local/share/zestsync"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/zestsync"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${CYAN}🍋 Installing ZestSync...${NC}"
echo ""

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR/jobs"
mkdir -p "$CONFIG_DIR/logs"

# Download or copy files
if [[ -d "$(dirname "$0")/lib" ]]; then
    # Local install
    cp -r "$(dirname "$0")/"* "$INSTALL_DIR/"
else
    # Remote install
    echo -e "${DIM}Downloading from GitHub...${NC}"
    curl -fsSL "https://github.com/$REPO/archive/main.tar.gz" | tar -xz -C "$INSTALL_DIR" --strip-components=1
fi

# Make executable
chmod +x "$INSTALL_DIR/zestsync"
chmod +x "$INSTALL_DIR/lib/"*.sh

# Create symlink
ln -sf "$INSTALL_DIR/zestsync" "$BIN_DIR/zestsync"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    echo -e "${DIM}Adding ~/.local/bin to PATH...${NC}"
    
    SHELL_RC=""
    case "$SHELL" in
        */zsh)  SHELL_RC="$HOME/.zshrc" ;;
        */bash) SHELL_RC="$HOME/.bashrc" ;;
    esac
    
    if [[ -n "$SHELL_RC" ]]; then
        echo '' >> "$SHELL_RC"
        echo '# ZestSync' >> "$SHELL_RC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo -e "${DIM}Added to $SHELL_RC${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ ZestSync installed successfully!${NC}"
echo ""
echo -e "${DIM}To get started:${NC}"
echo -e "  ${CYAN}zestsync${NC}          Open the menu"
echo -e "  ${CYAN}zestsync --help${NC}   Show all options"
echo ""
echo -e "${DIM}You may need to restart your terminal or run:${NC}"
echo -e "  source ~/.zshrc"
echo ""
