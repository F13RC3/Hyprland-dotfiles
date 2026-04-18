#!/bin/bash

# --- 1. Setup & Aesthetics ---
set -e # Exit on error
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starting Kei0s Lab: HyDE & Power Automation Install...${NC}"

# Ensure we are in the dotfiles directory
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$DOTFILES_DIR"

# --- 2. System Dependency Check ---
echo -e "${YELLOW}Step 1: Installing Core Dependencies...${NC}"
DEPENDENCIES=(stow git brightnessctl tlp auto-cpufreq envycontrol powertop thermald fastfetch libnotify)
sudo pacman -S --needed --noconfirm "${DEPENDENCIES[@]}"

# --- 2b. Application Dependencies ---
echo -e "${YELLOW}Step 1b: Installing Applications...${NC}"

CORE_APPS=(kitty dolphin)
ESSENTIAL_APPS=(
    firefox vlc obs-studio qbittorrent mpv neovim 
    starship fzf bat eza btop ripgrep
)

sudo pacman -S --needed --noconfirm "${CORE_APPS[@]}"

for app in "${ESSENTIAL_APPS[@]}"; do
    if pacman -Qq "$app" &>/dev/null; then
        echo -e "${GREEN}  ✔ $app already installed${NC}"
    else
        echo -e "${BLUE}  Installing $app...${NC}"
        sudo pacman -S --needed --noconfirm "$app" 2>/dev/null || echo -e "${YELLOW}  ⚠ $app not found, skipping${NC}"
    fi
done

# Install AUR packages
if command -v yay &>/dev/null || command -v paru &>/dev/null; then
    echo -e "${BLUE}Installing AUR packages...${NC}"
    AUR_PACMAN=$(command -v yay || command -v paru)
    AUR_APPS=("visual-studio-code-bin" "brave-bin" "antigravity" "ani-cli" "miniconda3")
    
    for aur_app in "${AUR_APPS[@]}"; do
        echo -e "${BLUE}  Installing $aur_app...${NC}"
        $AUR_PACMAN -S --noconfirm "$aur_app" 2>/dev/null || echo -e "${YELLOW}  ⚠ $aur_app failed, skipping${NC}"
    done
fi

# --- 3. HyDE Framework Check ---
if [ ! -d "$HOME/.local/lib/hyde" ]; then
  echo -e "${YELLOW}Step 2: Installing HyDE Framework...${NC}"
  git clone https://github.com/prasanthrangan/hyprdots.git /tmp/hyde-install
  cd /tmp/hyde-install/Scripts
  ./install.sh
  cd "$DOTFILES_DIR"
else
  echo -e "${GREEN}✔ HyDE Framework already installed.${NC}"
fi

# --- 4. Separation of Powers (Clean CPU Management) ---
echo -e "${YELLOW}Step 3: Configuring Silent Power Management...${NC}"

# A. Configure auto-cpufreq as the ONLY CPU Manager
echo -e "${BLUE}Configuring auto-cpufreq (The CPU Master)...${NC}"
sudo bash -c "cat << EOF > /etc/auto-cpufreq.conf
[charger]
governor = powersave
energy_performance_preference = balance_power
turbo = auto

[battery]
governor = powersave
energy_performance_preference = power
turbo = never
EOF"

# B. Disable TLP CPU Management to avoid conflicts (The Fan Killer)
echo -e "${BLUE}Configuring TLP (Hardware only)...${NC}"
# Comment out all CPU-related lines in TLP config
sudo sed -i 's/^\(CPU_.*\)/#\1/' /etc/tlp.conf

# C. Disable conflicting Power Profiles Daemon
sudo systemctl mask power-profiles-daemon.service || true

# D. Enable Services
sudo systemctl enable --now tlp
sudo systemctl enable --now auto-cpufreq
sudo systemctl enable --now thermald

# E. Set EnvyControl to Hybrid
sudo envycontrol -s hybrid

# --- 5. Custom System Rules (Refresh Rate Switcher) ---
echo -e "${YELLOW}Step 4: Setting up Refresh Rate Automation...${NC}"

USER_NAME=$(whoami)
USER_ID=$(id -u)

mkdir -p "$DOTFILES_DIR/scripts/.local/bin"
cat <<'EOF' >"$DOTFILES_DIR/scripts/.local/bin/power_profile.sh"
#!/bin/bash
USER_NAME=$(whoami)
USER_ID=$(id -u)
export XDG_RUNTIME_DIR="/run/user/$USER_ID"

# Locate Hyprland Socket
SOCKET_FILE=$(find /run/user/$USER_ID/hypr/ -name ".socket.sock" | head -n 1)
if [ -z "$SOCKET_FILE" ]; then exit 1; fi

HYPR_SIG=$(basename $(dirname "$SOCKET_FILE"))
export HYPRLAND_INSTANCE_SIGNATURE="$HYPR_SIG"

sleep 1

# Apply logic: 120Hz (AC) / 60Hz (Battery) @ 1.25 Scale
if grep -q "0" /sys/class/power_supply/AC*/online; then
    /usr/bin/hyprctl --instance "$HYPR_SIG" keyword monitor "eDP-1, 1920x1080@60, 0x0, 1.25"
    /usr/bin/notify-send "Power Status" "Battery Mode: 60Hz" -i battery
else
    /usr/bin/hyprctl --instance "$HYPR_SIG" keyword monitor "eDP-1, 1920x1080@120, 0x0, 1.25"
    /usr/bin/notify-send "Power Status" "AC Mode: 120Hz" -i ac-adapter
fi
EOF
chmod +x "$DOTFILES_DIR/scripts/.local/bin/power_profile.sh"

# Write Udev Rule
sudo bash -c "cat << EOF > /etc/udev/rules.d/99-monitor-refresh.rules
SUBSYSTEM==\"power_supply\", ACTION==\"change\", RUN+=\"/usr/bin/sudo -u $USER_NAME /home/$USER_NAME/.local/bin/power_profile.sh\"
EOF"

# --- 6. Stowing Dotfiles ---
echo -e "${YELLOW}Step 5: Symlinking Dotfiles with Stow...${NC}"

CONFIGS=(hypr waybar kitty fastfetch)
for cfg in "${CONFIGS[@]}"; do
  if [ -d "$HOME/.config/$cfg" ] && [ ! -L "$HOME/.config/$cfg" ]; then
    mv "$HOME/.config/$cfg" "$HOME/.config/${cfg}_bak"
  fi
  stow -R "$cfg"
done

stow -R scripts -t "$HOME"

# --- 7. Finalization ---
echo -e "${GREEN}--- ALL SYSTEMS GO ---${NC}"
echo -e "${BLUE}1. auto-cpufreq handles CPU (Fans will stay quiet)${NC}"
echo -e "${BLUE}2. TLP handles Hardware (PCIe/USB/WiFi)${NC}"
echo -e "${BLUE}3. Monitor: 120Hz/60Hz @ 1.25 Scale Active${NC}"
echo -e "${YELLOW}Please REBOOT to apply all changes.${NC}"