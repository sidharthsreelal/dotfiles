#!/bin/bash

id="$1"
persistent="$2"

# Get active workspace ID
active_ws=$(hyprctl activeworkspace -j | jq -r '.id')

# Get occupied workspace IDs (workspaces containing windows)
occupied_ws=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id > 0) | .workspace.id' | sort -nu)

if [ "$id" -eq "$active_ws" ]; then
    echo "<span color='#b4befe'>[<span color='#ff3333'>●</span>]</span>"
elif echo "$occupied_ws" | grep -q -x "$id"; then
    echo "<span color='#6c7086'>[<span color='#cdd6f4'>$id</span>]</span>"
elif [ "$persistent" = "true" ]; then
    echo "<span color='#6c7086'>[$id]</span>"
else
    # Output empty string so Waybar hides the module
    echo ""
fi
