#!/bin/bash
# power-profile.sh - Power profile display and switcher for Waybar
# Usage:
#   power-profile.sh           -> outputs JSON for waybar custom module
#   power-profile.sh toggle    -> opens wofi menu to pick a profile

declare -A PROFILE_ICONS
PROFILE_ICONS["performance"]="󱐌"
PROFILE_ICONS["balanced"]="󰾅"
PROFILE_ICONS["power-saver"]="󰾆"

declare -A PROFILE_LABELS
PROFILE_LABELS["performance"]="Performance"
PROFILE_LABELS["balanced"]="Balanced"
PROFILE_LABELS["power-saver"]="Power Saver"

get_current_profile() {
  powerprofilesctl get 2>/dev/null || echo "balanced"
}

get_battery_info() {
  local capacity status
  capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
  status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
  echo "${capacity:-??}|${status:-Unknown}"
}

battery_icon() {
  local pct="$1" charging="$2"
  if [[ "$charging" == "Charging" || "$charging" == "Full" ]]; then
    echo "󰂄"
    return
  fi
  if   [ "$pct" -ge 95 ]; then echo "󰁹"
  elif [ "$pct" -ge 88 ]; then echo "󰂂"
  elif [ "$pct" -ge 75 ]; then echo "󰂁"
  elif [ "$pct" -ge 63 ]; then echo "󰂀"
  elif [ "$pct" -ge 50 ]; then echo "󰁿"
  elif [ "$pct" -ge 38 ]; then echo "󰁾"
  elif [ "$pct" -ge 25 ]; then echo "󰁽"
  elif [ "$pct" -ge 13 ]; then echo "󰁼"
  elif [ "$pct" -ge 5  ]; then echo "󰁻"
  else echo "󰁺"
  fi
}

if [[ "$1" == "toggle" ]]; then
  # Kill any stale instance before opening a new one
  pkill -f "wofi.*Power Profile" 2>/dev/null
  sleep 0.05

  current=$(get_current_profile)
  menu=""
  for profile in "performance" "balanced" "power-saver"; do
    icon="${PROFILE_ICONS[$profile]}"
    label="${PROFILE_LABELS[$profile]}"
    if [[ "$profile" == "$current" ]]; then
      menu+="● ${icon}  ${label}\n"
    else
      menu+="  ${icon}  ${label}\n"
    fi
  done

  # --- Close-on-outside-click via Hyprland IPC focus monitor ---
  # Listen on the Hyprland event socket; kill wofi the moment focus
  # leaves it (i.e. user clicks anywhere outside the dropdown).
  SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  (
    sleep 0.25   # give wofi time to map its window
    socat - "UNIX-CONNECT:$SOCK" 2>/dev/null | while IFS= read -r event; do
      if [[ "$event" == activewindow* || "$event" == closewindow* ]]; then
        active_class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""')
        if [[ "$active_class" != "wofi" ]]; then
          pkill -f "wofi.*Power Profile" 2>/dev/null
          break
        fi
      fi
    done
  ) &
  MONITOR_PID=$!

  chosen=$(printf "%b" "$menu" | wofi \
    --dmenu \
    --prompt "Power Profile" \
    --width 260 \
    --height 155 \
    --hide-search \
    --no-actions \
    --hide-scroll \
    --location top_right \
    --yoffset 38 \
    --xoffset -6 \
    --style "$HOME/.config/wofi/power-profile.css" \
    --cache-file /dev/null \
    2>/dev/null)

  # Clean up the monitor regardless of how wofi exited
  kill "$MONITOR_PID" 2>/dev/null

  if echo "$chosen" | grep -qi "performance"; then
    powerprofilesctl set performance
  elif echo "$chosen" | grep -qi "balanced"; then
    powerprofilesctl set balanced
  elif echo "$chosen" | grep -qi "power.saver"; then
    powerprofilesctl set power-saver
  fi

  # Signal waybar to refresh the battery module
  pkill -RTMIN+8 waybar 2>/dev/null

else
  current=$(get_current_profile)
  bat_info=$(get_battery_info)
  pct="${bat_info%%|*}"
  status="${bat_info##*|}"

  profile_icon="${PROFILE_ICONS[$current]}"
  bat_icon=$(battery_icon "${pct:-50}" "$status")

  profile_label="${PROFILE_LABELS[$current]:-$current}"
  tooltip="${profile_label} profile active\\nBattery: ${pct}% (${status})"

  # Build CSS class string
  css_class="$current"
  if [[ "$status" == "Charging" ]]; then
    css_class="${css_class} charging"
  fi
  if [[ "${pct:-100}" -le 15 ]]; then
    css_class="${css_class} critical"
  elif [[ "${pct:-100}" -le 30 ]]; then
    css_class="${css_class} warning"
  fi

  printf '{"text":"%s %s%%","tooltip":"%s","class":"%s"}\n' \
    "$bat_icon" \
    "$pct" \
    "$tooltip" \
    "$css_class"
fi
