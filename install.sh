#!/bin/bash

# --- 1. Setup & Aesthetics ---
set -e # Exit on error
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starting Ashish's Ultimate HyDE & Power Install...${NC}"

# Ensure we are in the dotfiles directory
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$DOTFILES_DIR"

# --- 2. System Dependency Check ---
echo -e "${YELLOW}Step 1: Installing Core Dependencies...${NC}"
DEPENDENCIES=(stow git brightnessctl tlp auto-cpufreq envycontrol powertop thermald)
sudo pacman -S --needed --noconfirm "${DEPENDENCIES[@]}"

# --- 3. HyDE Framework Check ---
if [ ! -d "$HOME/.local/lib/hyde" ]; then
    echo -e "${YELLOW}Step 2: HyDE not detected. Installing HyDE Framework...${NC}"
    git clone https://github.com/prasanthrangan/hyprdots.git /tmp/hyde-install
    cd /tmp/hyde-install/Scripts
    ./install.sh
    cd "$DOTFILES_DIR"
else
    echo -e "${GREEN}✔ HyDE Framework already installed.${NC}"
fi

# --- 4. Separation of Powers (Battery Strategy) ---
echo -e "${YELLOW}Step 3: Configuring Power Management...${NC}"

# A. Disable TLP CPU Management (letting auto-cpufreq take over)
echo -e "${BLUE}Configuring TLP...${NC}"
sudo sed -i 's/^#\(CPU_SCALING_GOVERNOR_ON_AC=\).*/\1performance/' /etc/tlp.conf
sudo sed -i 's/^#\(CPU_SCALING_GOVERNOR_ON_BAT=\).*/\1powersave/' /etc/tlp.conf
# Ensure TLP ignores CPU energy policy
sudo sed -i 's/^\(CPU_ENERGY_PERF_POLICY\)/#\1/' /etc/tlp.conf

# B. Disable conflicting Power Profiles Daemon
echo -e "${BLUE}Disabling power-profiles-daemon...${NC}"
sudo systemctl mask power-profiles-daemon.service || true

# C. Enable Services
sudo systemctl enable --now tlp
sudo systemctl enable --now auto-cpufreq
sudo systemctl enable --now powertop
sudo systemctl enable --now thermald

# D. Set EnvyControl to Hybrid
echo -e "${BLUE}Setting GPU to Hybrid mode...${NC}"
sudo envycontrol -s hybrid

# --- 5. Custom System Rules (Refresh Rate Switcher) ---
echo -e "${YELLOW}Step 4: Setting up Refresh Rate Udev Rules...${NC}"

# Create the refresh rate script in the dotfiles/scripts folder if it doesn't exist
if [ ! -f "$DOTFILES_DIR/scripts/.local/bin/power_profile.sh" ]; then
    mkdir -p "$DOTFILES_DIR/scripts/.local/bin"
    cat << 'EOF' > "$DOTFILES_DIR/scripts/.local/bin/power_profile.sh"
#!/bin/bash
if grep -q "0" /sys/class/power_supply/AC/online; then
    hyprctl keyword monitor "eDP-1, 1920x1080@60, 0x0, 1"
else
    hyprctl keyword monitor "eDP-1, 1920x1080@144, 0x0, 1"
fi
EOF
    chmod +x "$DOTFILES_DIR/scripts/.local/bin/power_profile.sh"
fi

# Write the Udev Rule
sudo bash -c "cat << EOF > /etc/udev/rules.d/99-monitor-refresh.rules
SUBSYSTEM==\"power_supply\", ATTR{online}==\"0\", RUN+=\"/usr/bin/su $USER -c '$HOME/.local/bin/power_profile.sh'\"
SUBSYSTEM==\"power_supply\", ATTR{online}==\"1\", RUN+=\"/usr/bin/su $USER -c '$HOME/.local/bin/power_profile.sh'\"
EOF"

# --- 6. Stowing Dotfiles ---
echo -e "${YELLOW}Step 5: Symlinking Dotfiles with Stow...${NC}"

# Backup existing configs to avoid stow conflicts
CONFIGS=(hypr waybar kitty)
for cfg in "${CONFIGS[@]}"; do
    if [ -d "$HOME/.config/$cfg" ] && [ ! -L "$HOME/.config/$cfg" ]; then
        echo -e "${BLUE}Backing up existing $cfg config...${NC}"
        mv "$HOME/.config/$cfg" "$HOME/.config/${cfg}_bak"
    fi
    stow -R "$cfg"
done

# Stow custom scripts
stow -R scripts -t "$HOME"

# --- 7. Finalization ---
echo -e "${GREEN}--- ALL SYSTEMS GO ---${NC}"
echo -e "${BLUE}1. Hybrid GPU Active (use prime-run)${NC}"
echo -e "${BLUE}2. auto-cpufreq & TLP Coexisting${NC}"
echo -e "${BLUE}3. Refresh rate will auto-switch on plug/unplug${NC}"
echo -e "${YELLOW}Please REBOOT to apply all kernel and udev changes.${NC}"