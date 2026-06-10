#!/usr/bin/env bash
# goto_empty_workspace.sh
# Jump to the lowest-numbered workspace that has no windows.
# Searches 1–9 (add more to the sequence if needed).

# Get list of occupied workspace IDs
occupied=$(hyprctl workspaces -j | python3 -c "
import json, sys
ws = json.load(sys.stdin)
print(' '.join(str(w['id']) for w in ws))
")

for n in 1 2 3 4 5 6 7 8 9; do
    if ! echo "$occupied" | grep -qw "$n"; then
        hyprctl dispatch workspace "$n"
        exit 0
    fi
done

# All 1-9 are occupied; fall back to workspace 10
hyprctl dispatch workspace 10
