#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Visual formatting variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting removal of simple-terminal-rice...${NC}"

# 1. Remove the active configuration items
echo -e "${GREEN}Removing custom configurations...${NC}"

if [ -d "$HOME/.config/foot" ]; then
    rm -rf "$HOME/.config/foot"
    echo -e "Removed Foot terminal configuration."
fi

if [ -f "$HOME/.zshrc" ]; then
    rm -f "$HOME/.zshrc"
    echo -e "Removed .zshrc configuration."
fi

if [ -d "$HOME/.config/fastfetch" ]; then
    rm -rf "$HOME/.config/fastfetch"
    echo -e "Removed Fastfetch configuration."
fi

# 2. Attempt to locate the latest backup folder
echo -e "${GREEN}Checking for existing backups to restore...${NC}"
# Finds the most recent terminal backup directory in ~/.config/
LATEST_BACKUP=$(ls -d $HOME/.config/terminal_rice_backup_* 2>/dev/null | sort | tail -n 1 || true)

if [ -n "$LATEST_BACKUP" ] && [ -d "$LATEST_BACKUP" ]; then
    echo -e "${GREEN}Found backup folder: $LATEST_BACKUP${NC}"
    echo -e "${GREEN}Restoring your original settings...${NC}"
    
    if [ -d "$LATEST_BACKUP/foot" ]; then
        mv "$LATEST_BACKUP/foot" "$HOME/.config/"
        echo -e "Restored original Foot configuration."
    fi
    
    if [ -f "$LATEST_BACKUP/.zshrc" ]; then
        mv "$LATEST_BACKUP/.zshrc" "$HOME/.zshrc"
        echo -e "Restored original .zshrc."
    fi
    
    if [ -d "$LATEST_BACKUP/fastfetch" ]; then
        mv "$LATEST_BACKUP/fastfetch" "$HOME/.config/"
        echo -e "Restored original Fastfetch configuration."
    fi
    
    # Remove the backup directory now that it is empty/processed
    rm -rf "$LATEST_BACKUP"
    echo -e "${GREEN}Backup successfully restored and cleared.${NC}"
else
    echo -e "${YELLOW}No automated backup folder found. Reverting to empty/default states.${NC}"
    # Recreate an empty foot folder and trigger a basic zsh configuration prompt for the next launch
    mkdir -p "$HOME/.config/foot"
    touch "$HOME/.zshrc"
fi

# 3. Optional dependency removal note
echo -e "\n${YELLOW}Note on system packages:${NC}"
echo -e "Core packages ('foot', 'zsh', 'fastfetch', and 'Oh My Zsh') were left installed to keep your terminal environment functional."
echo -e "If you wish to remove them entirely, run your package manager's remove command (e.g., 'yay -R foot fastfetch')."

echo -e "\n${GREEN}Uninstallation process complete! Please restart your terminal application.${NC}"
