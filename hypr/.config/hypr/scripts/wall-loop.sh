
#!/bin/bash
while true; do
    if [[ $(cat /sys/class/power_supply/AC/online) -eq 1 ]]; then
        ~/.local/lib/hyde/wallpaper.sh -n
        sleep 900
    else
        # On battery? Just wait and don't trigger GPU-heavy transitions
        sleep 1800 
    fi
done