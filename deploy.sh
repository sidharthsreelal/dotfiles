#!/bin/bash
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/kitty ~/.config/wofi ~/.config/dunst ~/.config/gtk-3.0 ~/.config/gtk-4.0
cp "$DOTFILES/.config/hypr/hyprland.lua"       ~/.config/hypr/
cp "$DOTFILES/.config/hypr/hyprpaper.conf"     ~/.config/hypr/
cp "$DOTFILES/.config/hypr/hyprlock.conf"      ~/.config/hypr/
cp "$DOTFILES/.config/hypr/hypridle.conf"      ~/.config/hypr/
cp "$DOTFILES/.config/kitty/kitty.conf"        ~/.config/kitty/
cp "$DOTFILES/.config/waybar/config.jsonc"     ~/.config/waybar/
cp "$DOTFILES/.config/waybar/style.css"        ~/.config/waybar/
cp "$DOTFILES/.config/wofi/style.css"          ~/.config/wofi/
cp "$DOTFILES/.config/wofi/config"             ~/.config/wofi/
cp "$DOTFILES/.config/dunst/dunstrc"           ~/.config/dunst/
cp "$DOTFILES/.config/gtk-3.0/settings.ini"   ~/.config/gtk-3.0/
cp "$DOTFILES/.config/gtk-4.0/settings.ini"   ~/.config/gtk-4.0/
echo "Done."