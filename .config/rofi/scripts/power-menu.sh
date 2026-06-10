#!/usr/bin/env bash

# Options
lock="  Lock"
suspend="󰒲  Suspend"
logout="󰍃  Log Out"
reboot="󰜉  Reboot"
shutdown="  Shut Down"

# Get selection from rofi
selected_option=$(echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi -dmenu -i -p "Power" -theme ~/.config/rofi/themes/powermenu.rasi)

# Perform action
case "$selected_option" in
    "$lock")
        hyprlock
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$logout")
        hyprctl dispatch exit
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac
