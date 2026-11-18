
#!/usr/bin/env bash

set -Eeuo pipefail

# Configuration
NVIM_VERSION="${NVIM_VERSION:-v0.11.5}"
OS="$(uname -s)"
ARCH="$(uname -m)"

LOCAL_DIR="$HOME/.local"
INSTALL_DIR="$LOCAL_DIR/nvim-${NVIM_VERSION}"
BIN_DIR="$LOCAL_DIR/bin"
BIN_LINK="$BIN_DIR/nvim"

mkdir -p "$LOCAL_DIR" "$BIN_DIR"

# Temporary directory
TMP_DIR="$(mktemp -d "$LOCAL_DIR/nvim-install.XXXXXX")"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

echo "Installing Neovim ${NVIM_VERSION}"
echo "OS: $OS"
echo "Architecture: $ARCH"

# Detect platform and archive
case "$OS" in
    Darwin)
        case "$ARCH" in
            arm64)
                TARBALL="nvim-macos-arm64.tar.gz"
                EXTRACTED_DIR="nvim-macos-arm64"
                ;;
            x86_64)
                TARBALL="nvim-macos-x86_64.tar.gz"
                EXTRACTED_DIR="nvim-macos-x86_64"
                ;;
            *)
                echo "Unsupported macOS architecture: $ARCH"
                exit 1
                ;;
        esac
        ;;

    Linux)
        case "$ARCH" in
            x86_64)
                TARBALL="nvim-linux-x86_64.tar.gz"
                EXTRACTED_DIR="nvim-linux-x86_64"
                ;;
            aarch64|arm64)
                TARBALL="nvim-linux-arm64.tar.gz"
                EXTRACTED_DIR="nvim-linux-arm64"
                ;;
            *)
                echo "Unsupported Linux architecture: $ARCH"
                exit 1
                ;;
        esac
        ;;

    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Download
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${TARBALL}"

echo "Downloading: $DOWNLOAD_URL"

curl -fL --retry 3 "$DOWNLOAD_URL" -o "$TMP_DIR/$TARBALL"

# Remove macOS quarantine attribute from archive
if [[ "$OS" == "Darwin" ]] && command -v xattr >/dev/null 2>&1; then
    xattr -c "$TMP_DIR/$TARBALL"
fi

# Extract
echo "Extracting archive..."

tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR"

# Verify extracted binary
NEW_BINARY="$TMP_DIR/$EXTRACTED_DIR/bin/nvim"

if [[ ! -x "$NEW_BINARY" ]]; then
    echo "Error: Neovim binary not found or not executable."
    exit 1
fi

# Replace old version only after successful extraction
echo "Installing to $INSTALL_DIR"

rm -rf "$INSTALL_DIR"
mv "$TMP_DIR/$EXTRACTED_DIR" "$INSTALL_DIR"

# Create/update symlink
ln -sfn "$INSTALL_DIR/bin/nvim" "$BIN_LINK"

# Verify installation
echo ""
echo "Neovim installed successfully!"

"$BIN_LINK" --version | head -n 1

# PATH check
case ":$PATH:" in
    *":$BIN_DIR:"*)
        echo "PATH is configured correctly."
        ;;
    *)
        echo ""
        echo "Add this to your ~/.zshrc or ~/.bashrc:"
        echo "export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

