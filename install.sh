#!/usr/bin/env bash

# Exit on error
set -e

REPO_URL="https://github.com/xrompf/simple-terminal-rice.git"
CLONE_DIR="$HOME/.local/share/simple-terminal-rice"
CONFIG_DEST="$HOME/.config"

# --- COLOR DEFINITIONS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- PACKAGE INSTALLATION ---
install_dependencies() {
    echo -e "${BLUE}==> Installing missing dependencies...${NC}"
    if command -v pacman &>/dev/null; then
        sudo pacman -Sy --needed --noconfirm git zsh neovim tmux starship fastfetch fzf ripgrep ttf-nerd-fonts-symbols-common
    elif command -v apt-get &>/dev/null; then
        sudo apt update
        sudo apt install -y git zsh neovim tmux fzf ripgrep
        if ! command -v starship &>/dev/null; then
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
    elif command -v dnf &>/dev/null; then
        sudo dnf check-update || true
        sudo dnf install -y git zsh neovim tmux fzf ripgrep
        if ! command -v starship &>/dev/null; then
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
    elif command -v brew &>/dev/null; then
        brew install git zsh neovim tmux starship fastfetch fzf ripgrep
    else
        echo -e "${YELLOW}Warning: Unknown package manager. Please manually install git, zsh, neovim, tmux, starship, fastfetch, fzf, ripgrep.${NC}"
    fi
}

# --- SYMLINK DEPLOYMENT ---
link_configs() {
    mkdir -p "$CONFIG_DEST"
    echo -e "${BLUE}==> Linking configuration files...${NC}"

    # Link directories into ~/.config
    for item in "$CLONE_DIR"/*; do
        item_name=$(basename "$item")

        # Skip non-config metadata
        [[ "$item_name" =~ ^\. ]] && continue
        [[ "$item_name" == "README.md" || "$item_name" == "LICENSE" || "$item_name" == "install.sh" ]] && continue

        target="$CONFIG_DEST/$item_name"

        # Backup existing target if it isn't already a symlink pointing to our repo
        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ "$(readlink -f "$target")" != "$(readlink -f "$item")" ]; then
                backup="$target.bak.$(date +%Y%m%d_%H%M%S)"
                echo -e "${YELLOW}--> Backing up $target to $backup${NC}"
                mv "$target" "$backup"
                ln -s "$item" "$target"
            fi
        else
            ln -s "$item" "$target"
        fi
    done

    # Link root dotfiles (.zshrc, .tmux.conf, etc.)
    for dotfile in zshrc tmux.conf Xresources; do
        if [ -f "$CLONE_DIR/.$dotfile" ]; then
            target="$HOME/.$dotfile"
            source_file="$CLONE_DIR/.$dotfile"

            if [ -e "$target" ] || [ -L "$target" ]; then
                if [ "$(readlink -f "$target")" != "$(readlink -f "$source_file")" ]; then
                    backup="$target.bak.$(date +%Y%m%d_%H%M%S)"
                    echo -e "${YELLOW}--> Backing up $target to $backup${NC}"
                    mv "$target" "$backup"
                    ln -s "$source_file" "$target"
                fi
            else
                ln -s "$source_file" "$target"
            fi
        fi
    done
}

# --- ACTIONS ---
do_install() {
    echo -e "${GREEN}==> Starting Installation...${NC}"
    install_dependencies

    if [ -d "$CLONE_DIR" ]; then
        echo -e "${BLUE}==> Repository already cloned. Pulling latest updates...${NC}"
        git -C "$CLONE_DIR" pull
    else
        echo -e "${BLUE}==> Cloning repository into $CLONE_DIR...${NC}"
        git clone "$REPO_URL" "$CLONE_DIR"
    fi

    link_configs
    echo -e "${GREEN}✔ Installation completed successfully!${NC}"
}

do_update() {
    echo -e "${GREEN}==> Updating configurations...${NC}"
    if [ ! -d "$CLONE_DIR" ]; then
        echo -e "${YELLOW}Repository not found locally. Running full install instead...${NC}"
        do_install
        return
    fi

    echo -e "${BLUE}==> Pulling latest changes from git...${NC}"
    git -C "$CLONE_DIR" pull

    link_configs
    echo -e "${GREEN}✔ Update complete!${NC}"
}

do_uninstall() {
    echo -e "${RED}==> Starting Uninstallation...${NC}"

    # Remove symlinks in ~/.config
    if [ -d "$CLONE_DIR" ]; then
        for item in "$CLONE_DIR"/*; do
            item_name=$(basename "$item")
            target="$CONFIG_DEST/$item_name"
            if [ -L "$target" ]; then
                echo -e "--> Removing symlink: $target"
                rm "$target"
            fi
        done
    fi

    # Remove root dotfile symlinks
    for dotfile in zshrc tmux.conf Xresources; do
        target="$HOME/.$dotfile"
        if [ -L "$target" ]; then
            echo -e "--> Removing symlink: $target"
            rm "$target"
        fi
    done

    # Restore recent backups if they exist
    echo -e "${BLUE}==> Checking for backups to restore...${NC}"
    for backup in "$CONFIG_DEST"/*.bak.*; do
        if [ -e "$backup" ]; then
            original="${backup%.bak.*}"
            if [ ! -e "$original" ]; then
                echo -e "${GREEN}--> Restoring $backup -> $original${NC}"
                mv "$backup" "$original"
            fi
        fi
    done

    echo -e "${GREEN}✔ Uninstallation complete!${NC}"
}

# --- MENU INTERFACE ---
show_menu() {
    # Direct stdin to terminal so reading input works when piped via curl
    exec < /dev/tty

    clear
    echo "=================================================="
    echo "       Simple Terminal Rice Setup Manager         "
    echo "=================================================="
    echo "1) Install   - Install dependencies & deploy configs"
    echo "2) Update    - Pull latest configs & update symlinks"
    echo "3) Uninstall - Remove symlinks & restore backups"
    echo "4) Exit"
    echo "=================================================="
    read -p "Please select an option [1-4]: " choice

    case $choice in
        1)
            do_install
            ;;
        2)
            do_update
            ;;
        3)
            do_uninstall
            ;;
        4)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option! Exiting.${NC}"
            exit 1
            ;;
    esac
}

# Run the menu
show_menu
