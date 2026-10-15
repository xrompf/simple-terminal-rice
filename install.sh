#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Visual formatting variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting installation for simple-terminal-rice...${NC}"

# 1. Detect AUR helper (Required for Arch/Hyprland setups)
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    echo -e "${RED}Error: Neither 'yay' nor 'paru' was found.${NC}"
    echo -e "${YELLOW}An AUR helper is required to fetch theme components on Arch Linux.${NC}"
    exit 1
fi

# 2. Comprehensive Dependency Lists
# System packages required for the core layout
SYSTEM_DEPS=(
    "foot"         # The main terminal emulator
    "zsh"          # The interactive shell environment
    "fastfetch"    # System information display tool
    "git"          # Version control to pull repositories
    "curl"         # Used to fetch external script managers
)

# Visual/Font dependencies to prevent broken layout icons
FONT_DEPS=(
    "ttf-nerd-fonts-symbols-common"  # Unified icon symbols
    "ttf-jetbrains-mono-nerd"       # Popular clean terminal font
)

# 3. Install System Dependencies
echo -e "${GREEN}Checking and installing system packages...${NC}"
for pkg in "${SYSTEM_DEPS[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null && ! command -v "$pkg" &> /dev/null; then
        echo -e "${YELLOW}Installing system dependency: $pkg...${NC}"
        $AUR_HELPER -S --noconfirm "$pkg"
    else
        echo -e "${GREEN}$pkg is already installed.${NC}"
    fi
done

# 4. Install Visual/Font Dependencies
echo -e "${GREEN}Checking and installing typography assets...${NC}"
for font in "${FONT_DEPS[@]}"; do
    if ! pacman -Qi "$font" &> /dev/null; then
        echo -e "${YELLOW}Installing icon font: $font...${NC}"
        $AUR_HELPER -S --noconfirm "$font"
    else
        echo -e "${GREEN}$font is already installed.${NC}"
    fi
done

# 5. Handle Oh My Zsh Deployment
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Oh My Zsh not found. Deploying framework...${NC}"
    sh -c "$(curl -fsSL https://githubusercontent.com)" "" --unattended
else
    echo -e "${GREEN}Oh My Zsh framework is already present.${NC}"
fi

# 6. Fetch Theme Source Files
REPO_URL="https://github.com"
TEMP_DIR=$(mktemp -d)

echo -e "${GREEN}Cloning theme repository layout...${NC}"
git clone "$REPO_URL" "$TEMP_DIR"

# 7. Safe Backup Pipeline
echo -e "${GREEN}Creating structural backups of active files...${NC}"
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

# 8. Asset Deployment Pathing
echo -e "${GREEN}Deploying layout configurations...${NC}"
mkdir -p "$HOME/.config"

# Copy Foot terminal profile
if [ -d "$TEMP_DIR/~/.config/foot" ]; then
    cp -r "$TEMP_DIR/~/.config/foot" "$HOME/.config/"
elif [ -d "$TEMP_DIR/foot" ]; then
    cp -r "$TEMP_DIR/foot" "$HOME/.config/"
fi

# Copy Fastfetch system readout template
if [ -d "$TEMP_DIR/fastfetch" ]; then
    cp -r "$TEMP_DIR/fastfetch" "$HOME/.config/"
fi

# Copy Custom Zsh interactive prompt structures
if [ -f "$TEMP_DIR/zsh config (with omz)/.zshrc" ]; then
    cp "$TEMP_DIR/zsh config (with omz)/.zshrc" "$HOME/.zshrc"
elif [ -f "$TEMP_DIR/.zshrc" ]; then
    cp "$TEMP_DIR/.zshrc" "$HOME/.zshrc"
fi

# 9. Clear installation footprint
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Installation finalized successfully!${NC}"
echo -e "${YELLOW}Notice: Refresh your workspace by running 'zsh' or initializing a new Foot terminal instance.${NC}"
echo -e "${YELLOW}Your legacy configurations are preserved at: $BACKUP_DIR${NC}"
