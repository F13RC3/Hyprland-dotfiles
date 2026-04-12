#!/bin/bash

# 1. Identity
USER_NAME="kei0s"
USER_ID="1000"
export XDG_RUNTIME_DIR="/run/user/$USER_ID"

# 2. Locate the actual socket file
# This finds the .socket.sock file regardless of the signature name
SOCKET_FILE=$(find /run/user/$USER_ID/hypr/ -name ".socket.sock" | head -n 1)

if [ -z "$SOCKET_FILE" ]; then
    echo "Error: No Hyprland socket found at $(date)" >> /tmp/power_profile.log
    exit 1
fi

# 3. Extract the Signature (the name of the directory containing the socket)
HYPR_SIG=$(basename $(dirname "$SOCKET_FILE"))
export HYPRLAND_INSTANCE_SIGNATURE="$HYPR_SIG"

# 4. Debug Logging
# exec > /tmp/power_profile.log 2>&1
# echo "--- Triggered at $(date) ---"
# echo "Found Signature: $HYPR_SIG"

# 5. Logic execution
# We use the --instance flag to be 100% sure hyprctl talks to the right session
if grep -q "0" /sys/class/power_supply/AC/online; then
    echo "Switching to Battery Mode (60Hz)"
    /usr/bin/hyprctl --instance "$HYPR_SIG" keyword monitor "eDP-1, 1920x1080@60, 0x0, 1.25"
    /usr/bin/notify-send "Power Status" "Battery Mode: 60Hz" -i battery
else
    echo "Switching to AC Mode (120Hz)"
    /usr/bin/hyprctl --instance "$HYPR_SIG" keyword monitor "eDP-1, 1920x1080@120, 0x0, 1.25"
    /usr/bin/notify-send "Power Status" "Performance Mode: 120Hz" -i ac-adapter
fi