#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Visual formatting variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting installation for simple-terminal-rice...${NC}"

# 1. Detect AUR helper
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    echo -e "${YELLOW}Warning: Neither 'yay' nor 'paru' was found. Falling back to pacman (requires sudo).${NC}"
    AUR_HELPER="sudo pacman"
fi

# 2. Install core package dependencies
echo -e "${GREEN}Checking and installing system packages...${NC}"
DEPENDENCIES=(foot zsh fastfetch git)
for pkg in "${DEPENDENCIES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        echo -e "${YELLOW}Installing $pkg...${NC}"
        $AUR_HELPER -S --noconfirm "$pkg"
    else
        echo -e "${GREEN}$pkg is already installed.${NC}"
    fi
done

# 3. Handle Oh My Zsh dependency
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Oh My Zsh not found. Installing now...${NC}"
    # Runs the installer unattended so it doesn't interrupt the script flow
    sh -c "$(curl -fsSL https://githubusercontent.com)" "" --unattended
else
    echo -e "${GREEN}Oh My Zsh is already installed.${NC}"
fi

# 4. Clone the repository
REPO_URL="https://github.com/xrompf/simple-terminal-rice"
TEMP_DIR=$(mktemp -d)

echo -e "${GREEN}Cloning repository to temporary directory...${NC}"
git clone "$REPO_URL" "$TEMP_DIR"

# 5. Create backup directories for existing configurations
echo -e "${GREEN}Creating backups of your existing terminal configurations...${NC}"
BACKUP_DIR="$HOME/.config/terminal_rice_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -d "$HOME/.config/foot" ]; then
    mv "$HOME/.config/foot" "$BACKUP_DIR/"
fi
if [ -f "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$BACKUP_DIR/"
fi
if [ -d "$HOME/.config/fastfetch" ]; then
    mv "$HOME/.config/fastfetch" "$BACKUP_DIR/"
fi

# 6. Deploy the custom configuration files
echo -e "${GREEN}Deploying new configuration files...${NC}"
mkdir -p "$HOME/.config"

# Copy Foot terminal config
if [ -d "$TEMP_DIR/~/.config/foot" ]; then
    cp -r "$TEMP_DIR/~/.config/foot" "$HOME/.config/"
elif [ -d "$TEMP_DIR/foot" ]; then
    cp -r "$TEMP_DIR/foot" "$HOME/.config/"
fi

# Copy Fastfetch config
if [ -d "$TEMP_DIR/fastfetch" ]; then
    cp -r "$TEMP_DIR/fastfetch" "$HOME/.config/"
fi

# Copy Zsh config (handles naming quirks in the repository structure)
if [ -f "$TEMP_DIR/zsh config (with omz)/.zshrc" ]; then
    cp "$TEMP_DIR/zsh config (with omz)/.zshrc" "$HOME/.zshrc"
elif [ -f "$TEMP_DIR/.zshrc" ]; then
    cp "$TEMP_DIR/.zshrc" "$HOME/.zshrc"
fi

# 7. Clean up temporary directory
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Installation complete! Please restart your terminal or run 'zsh' to apply changes.${NC}"
echo -e "${YELLOW}Note: Your original configurations have been safely backed up to: $BACKUP_DIR${NC}"
