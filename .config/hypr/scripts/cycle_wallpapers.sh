#!/usr/bin/env bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
STATE_FILE="$HOME/.cache/current_wallpaper"

# Create cache directory if it doesn't exist
mkdir -p "$(dirname "$STATE_FILE")"

# Find all image files in the directory
# Supported formats: jpg, jpeg, png, webp
mapfile -d '' WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 | sort -z)

NUM_WALLPAPERS=${#WALLPAPERS[@]}

if [ "$NUM_WALLPAPERS" -eq 0 ]; then
    notify-send -t 3000 "Hyprpaper" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Check if we are in restore/initialization mode
RESTORE_MODE=false
if [ "$1" = "--restore" ] || [ "$1" = "restore" ] || [ "$1" = "-r" ] || [ "$1" = "--init" ]; then
    RESTORE_MODE=true
fi

# Read current wallpaper from state file
CURRENT_WALLPAPER=""
if [ -f "$STATE_FILE" ]; then
    CURRENT_WALLPAPER=$(cat "$STATE_FILE")
fi

if [ "$RESTORE_MODE" = true ]; then
    # If state file has a valid wallpaper, use it; otherwise fallback to the first wallpaper
    if [ -n "$CURRENT_WALLPAPER" ] && [ -f "$CURRENT_WALLPAPER" ]; then
        NEXT_WALLPAPER="$CURRENT_WALLPAPER"
    else
        NEXT_WALLPAPER="${WALLPAPERS[0]}"
    fi
else
    # Find the index of the current wallpaper
    INDEX=-1
    for i in "${!WALLPAPERS[@]}"; do
        if [ "${WALLPAPERS[$i]}" = "$CURRENT_WALLPAPER" ]; then
            INDEX=$i
            break
        fi
    done

    # Determine the next wallpaper
    DIRECTION="next"
    if [ "$1" = "--prev" ] || [ "$1" = "prev" ] || [ "$1" = "-p" ] || [ "$1" = "backward" ]; then
        DIRECTION="prev"
    fi

    if [ "$INDEX" -eq -1 ]; then
        if [ "$DIRECTION" = "prev" ]; then
            NEXT_INDEX=$(( NUM_WALLPAPERS - 1 ))
        else
            NEXT_INDEX=0
        fi
    else
        if [ "$DIRECTION" = "prev" ]; then
            NEXT_INDEX=$(( (INDEX - 1 + NUM_WALLPAPERS) % NUM_WALLPAPERS ))
        else
            NEXT_INDEX=$(( (INDEX + 1) % NUM_WALLPAPERS ))
        fi
    fi
    NEXT_WALLPAPER="${WALLPAPERS[$NEXT_INDEX]}"
fi

# Get active monitors
MONITORS=$(hyprctl monitors | grep "Monitor" | awk '{print $2}')

# Set the wallpaper for each monitor
for MON in $MONITORS; do
    hyprctl hyprpaper wallpaper "$MON,$NEXT_WALLPAPER"
done

# Save the new wallpaper to the state file
echo "$NEXT_WALLPAPER" > "$STATE_FILE"

# Send a visual notification only if not in restore mode
if [ "$RESTORE_MODE" = false ]; then
    WALLPAPER_NAME=$(basename "$NEXT_WALLPAPER")
    notify-send -t 2000 -i "$NEXT_WALLPAPER" "Wallpaper Changed" "$WALLPAPER_NAME"
fi
