#!/usr/bin/env bash
# ============================================================
# SDDM Catppuccin Mocha Theme Installer
# Run this in a terminal: bash ~/.config/hypr/sddm-theme/install.sh
# ============================================================

set -e

THEME_SRC="$HOME/.config/hypr/sddm-theme"
THEME_DEST="/usr/share/sddm/themes/catppuccin-mocha"
WALLPAPER="$HOME/.config/hypr/wallpapers/a_red_object_in_the_sky.jpg"
SDDM_CONF="/etc/sddm.conf.d/autologin.conf"

echo "==> Installing Catppuccin Mocha SDDM theme..."

# 1. Copy theme files
sudo mkdir -p "$THEME_DEST"
sudo cp "$THEME_SRC/Main.qml"           "$THEME_DEST/Main.qml"
sudo cp "$THEME_SRC/theme.conf"         "$THEME_DEST/theme.conf"
sudo cp "$THEME_SRC/metadata.desktop"   "$THEME_DEST/metadata.desktop"

# 2. Copy wallpaper as background
sudo cp "$WALLPAPER" "$THEME_DEST/background.jpg"

echo "==> Theme files copied to $THEME_DEST"

# 3. Update SDDM config — disable autologin, set theme
sudo tee "$SDDM_CONF" > /dev/null << 'EOF'
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=start-hyprland -- --config /usr/share/sddm/hyprland.conf

[Theme]
Current=catppuccin-mocha
EOF

echo "==> SDDM config updated (autologin disabled, theme set)"
echo ""
echo "Done! The changes will take effect on next reboot."
echo "To preview the lock screen now, press Super+L."
