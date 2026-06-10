#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===================================================="
echo "          Arch Linux Environment Installer          "
echo "===================================================="
echo "This script is a standalone installer. It will:"
echo "1. Install core native packages via pacman"
echo "2. Check for or install 'yay' AUR helper"
echo "3. Install AUR packages from the backup list"
echo "4. Symlink configurations to your home directory (~/)"
echo "5. Restore custom scratch scripts and systemd services"
echo ""
echo "WARNING: This script will overwrite or back up your existing"
echo "configs in ~/.config and your home folder."
echo "===================================================="

# Safe-guard: Ensure running interactively to prevent boot/startup run issues
if [[ ! -t 0 ]]; then
    echo "ERROR: This script must be run interactively. Aborting." >&2
    exit 1
fi

# Ask for manual confirmation
read -p "Do you want to proceed with the installation? (y/N): " confirm
if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
    echo "Installation aborted."
    exit 0
fi

# Function to back up and create symlinks safely
backup_and_link() {
    local src="$1"
    local dest="$2"
    
    # Ensure source exists
    if [[ ! -e "$src" ]]; then
        echo "Warning: Source $src does not exist. Skipping."
        return
    fi

    # Create destination parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # If destination exists and is not a symlink, back it up
    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" ]]; then
            # Clean up existing symlink
            rm "$dest"
        else
            echo "Backing up existing file: $dest -> ${dest}.bak"
            mv "$dest" "${dest}.bak"
        fi
    fi

    echo "Linking: $dest -> $src"
    ln -s "$src" "$dest"
}

# 1. Install Base Packages
echo "--> Syncing databases and installing git + base-devel..."
sudo pacman -Sy --needed --noconfirm git base-devel

if [[ -f "$SCRIPT_DIR/packages/pkglist.txt" ]]; then
    echo "--> Installing native packages from pkglist.txt..."
    # pacman doesn't always handle comments or blank lines well, so read line by line or filter
    grep -v '^#' "$SCRIPT_DIR/packages/pkglist.txt" | grep -v '^\s*$' | xargs -r sudo pacman -S --needed --noconfirm
else
    echo "Warning: pkglist.txt not found!"
fi

# 2. Ensure YAY AUR helper is installed
if ! command -v yay &> /dev/null; then
    echo "--> YAY is not installed. Building and installing yay-bin from AUR..."
    BUILD_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$BUILD_DIR"
    pushd "$BUILD_DIR" > /dev/null
    makepkg -si --noconfirm
    popd > /dev/null
    rm -rf "$BUILD_DIR"
else
    echo "--> YAY AUR helper is already installed."
fi

# 3. Install AUR Packages
if [[ -f "$SCRIPT_DIR/packages/foreignpkglist.txt" ]]; then
    echo "--> Installing AUR packages from foreignpkglist.txt..."
    grep -v '^#' "$SCRIPT_DIR/packages/foreignpkglist.txt" | grep -v '^\s*$' | xargs -r yay -S --needed --noconfirm
else
    echo "Warning: foreignpkglist.txt not found!"
fi

# 4. Link Configuration Folders
echo "--> Creating configuration symlinks..."
for item in "$SCRIPT_DIR"/.config/*; do
    name=$(basename "$item")
    if [[ "$name" == "Code" ]]; then
        # VS Code settings are nested inside Code/User/
        backup_and_link "$item/User/settings.json" "$HOME/.config/Code/User/settings.json"
    else
        backup_and_link "$item" "$HOME/.config/$name"
    fi
done

# 5. Link Home Dotfiles
echo "--> Linking home directory files..."
# Make sure dotglob is off or explicitly specify files to avoid linking .git / .config etc.
for file in "$SCRIPT_DIR"/home/.X*; do
    [[ -e "$file" ]] || continue
    name=$(basename "$file")
    backup_and_link "$file" "$HOME/$name"
done
for file in "$SCRIPT_DIR"/home/.bash*; do
    [[ -e "$file" ]] || continue
    name=$(basename "$file")
    backup_and_link "$file" "$HOME/$name"
done

# 6. Link and Restore Custom Scratch Scripts
echo "--> Restoring custom background/scratch scripts..."
mkdir -p "$HOME/.gemini/antigravity-ide/scratch"
for script in "$SCRIPT_DIR"/scripts/*; do
    [[ -e "$script" ]] || continue
    name=$(basename "$script")
    backup_and_link "$script" "$HOME/.gemini/antigravity-ide/scratch/$name"
    chmod +x "$HOME/.gemini/antigravity-ide/scratch/$name"
done

# 7. Enable systemd user services
echo "--> Reloading systemd user configuration..."
systemctl --user daemon-reload

if systemctl --user list-unit-files | grep -q "antigravity-sync.service"; then
    echo "--> Enabling and starting antigravity-sync.service..."
    systemctl --user enable --now antigravity-sync.service
else
    echo "Warning: antigravity-sync.service not found in systemd units."
fi

echo "===================================================="
echo "          Installation Completed Successfully!       "
echo "===================================================="
echo "Configurations linked and custom background services enabled."
echo "===================================================="
