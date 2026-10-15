#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

REPO_URL="https://github.com/xrompf/simple-terminal-rice.git"
CLONE_DIR="$HOME/.local/share/simple-terminal-rice"
CONFIG_DEST="$HOME/.config"

echo "=================================================="
echo "    Installing Simple Terminal Rice & Dependencies"
echo "=================================================="

# Detect Package Manager
detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)

# 1. Install Dependencies
echo "==> Installing missing dependencies..."

install_packages() {
    case "$PKG_MANAGER" in
        pacman)
            sudo pacman -Sy --needed --noconfirm git zsh neovim tmux starship fastfetch fzf ripgrep ttf-nerd-fonts-symbols-common
            ;;
        apt)
            sudo apt update
            sudo apt install -y git zsh neovim tmux fzf ripgrep
            # Check for starship or fastfetch if available via apt/cargo/curl
            if ! command -v starship &>/dev/null; then
                echo "--> Installing Starship prompt..."
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi
            ;;
        dnf)
            sudo dnf check-update || true
            sudo dnf install -y git zsh neovim tmux fzf ripgrep
            if ! command -v starship &>/dev/null; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi
            ;;
        brew)
            brew install git zsh neovim tmux starship fastfetch fzf ripgrep
            ;;
        *)
            echo "Warning: Package manager not recognized. Please make sure the following dependencies are installed:"
            echo "  - git, zsh, neovim, tmux, starship, fastfetch, fzf, ripgrep"
            ;;
    esac
}

install_packages

# 2. Clone or Update the Repository
echo "==> Fetching repository..."
if [ -d "$CLONE_DIR" ]; then
    echo "--> Repository already exists. Pulling latest changes..."
    git -C "$CLONE_DIR" pull
else
    echo "--> Cloning repository into $CLONE_DIR..."
    git clone "$REPO_URL" "$CLONE_DIR"
fi

# 3. Create destination config directory
mkdir -p "$CONFIG_DEST"

# 4. Link Configuration Files to ~/.config
echo "==> Deploying configuration files..."

for item in "$CLONE_DIR"/*; do
    item_name=$(basename "$item")
    
    # Skip non-config metadata files
    [[ "$item_name" =~ ^\. ]] && continue
    [[ "$item_name" == "README.md" ]] && continue
    [[ "$item_name" == "LICENSE" ]] && continue
    [[ "$item_name" == "install.sh" ]] && continue

    target="$CONFIG_DEST/$item_name"

    # Backup existing configuration if present
    if [ -e "$target" ] || [ -L "$target" ]; then
        backup="$target.bak.$(date +%Y%m%d_%H%M%S)"
        echo "--> Backing up existing $target to $backup"
        mv "$target" "$backup"
    fi

    echo "--> Symlinking $item -> $target"
    ln -s "$item" "$target"
done

# 5. Link home dotfiles if present (e.g. .zshrc, .tmux.conf)
for dotfile in zshrc tmux.conf Xresources; do
    if [ -f "$CLONE_DIR/.$dotfile" ]; then
        target="$HOME/.$dotfile"
        if [ -e "$target" ] || [ -L "$target" ]; then
            backup="$target.bak.$(date +%Y%m%d_%H%M%S)"
            echo "--> Backing up existing $target to $backup"
            mv "$target" "$backup"
        fi
        echo "--> Symlinking $CLONE_DIR/.$dotfile -> $target"
        ln -s "$CLONE_DIR/.$dotfile" "$target"
    fi
done

# 6. Change default shell to zsh (optional check)
if [ "$SHELL" != "$(which zsh)" ] && command -v zsh &>/dev/null; then
    echo "==> Setting Zsh as default shell..."
    chsh -s "$(which zsh)" || echo "Note: Run 'chsh -s $(which zsh)' manually if shell change failed."
fi

echo "=================================================="
echo "    Installation Complete! Enjoy your new rice."
echo "=================================================="
