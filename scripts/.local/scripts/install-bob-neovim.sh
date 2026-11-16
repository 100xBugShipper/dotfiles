#!/usr/bin/env bash
set -e

NVIM_VERSION="v0.11.5"
OS="$(uname -s)"

echo "Detected OS: $OS"

# 1. Install Bob & determine Bob's binary path per OS
if [[ "$OS" == "Darwin" ]]; then
    # Remove Homebrew neovim if installed to prevent PATH conflicts
    if command -v brew >/dev/null 2>&1 && brew list neovim >/dev/null 2>&1; then
        echo "Removing Homebrew Neovim to avoid conflicts..."
        brew uninstall neovim
    fi

    # Install bob via Homebrew if missing
    if ! command -v bob >/dev/null 2>&1; then
        echo "Installing bob via Homebrew..."
        brew install bob
    fi

    BOB_BIN_DIR="$HOME/Library/Application Support/bob/nvim-bin"

elif [[ "$OS" == "Linux" ]] && [[ -f /etc/arch-release ]]; then
    # Remove pacman neovim if installed to prevent PATH conflicts
    if pacman -Qi neovim >/dev/null 2>&1; then
        echo "Removing Arch pacman Neovim to avoid conflicts..."
        sudo pacman -Rns --noconfirm neovim
    fi

    # Install bob via pacman if missing
    if ! command -v bob >/dev/null 2>&1; then
        echo "Installing bob via pacman..."
        sudo pacman -S --noconfirm --needed bob
    fi

    BOB_BIN_DIR="$HOME/.local/share/bob/nvim-bin"

else
    echo "Unsupported OS. This script supports macOS and Arch Linux only."
    exit 1
fi

# 2. Install and activate the target Neovim version
echo "Installing and activating Neovim $NVIM_VERSION via bob..."
bob install "$NVIM_VERSION"
bob use "$NVIM_VERSION"

# 3. Detect shell config file and safely add BOB_BIN_DIR to PATH
if [[ "$SHELL" == *"zsh"* ]]; then
    RC_FILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    RC_FILE="$HOME/.bashrc"
else
    RC_FILE="$HOME/.profile"
fi

EXPORT_LINE="export PATH=\"$BOB_BIN_DIR:\$PATH\""

if ! grep -Fq "$BOB_BIN_DIR" "$RC_FILE" 2>/dev/null; then
    echo "Adding Bob binary path to $RC_FILE..."
    echo "" >> "$RC_FILE"
    echo "# Added by Neovim Bob setup script" >> "$RC_FILE"
    echo "$EXPORT_LINE" >> "$RC_FILE"
else
    echo "Bob binary path already exists in $RC_FILE."
fi

# 4. Export for current subshell and verify
export PATH="$BOB_BIN_DIR:$PATH"
echo "Done! Installed version:"
nvim --version | head -n 1
echo "Run 'source $RC_FILE' or restart your terminal to apply changes."

