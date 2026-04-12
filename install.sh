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

# Core Apps (from Hyprland config)
CORE_APPS=(kitty dolphin)

# Essential Apps from official repos (user-installed apps only)
ESSENTIAL_APPS=(
    firefox                 # Web browser
    vlc                     # Media player
    obs-studio              # Screen recorder/streaming
    qbittorrent             # Torrent client
    mpv                     # Video player
    neovim                  # Text editor
    starship                # Shell prompt
    fzf                     # Fuzzy finder
    bat                     # Cat clone with syntax highlighting
    eza                     # Modern ls replacement
    btop                    # System monitor
    ripgrep                 # Grep replacement
)

# Install Core Apps
sudo pacman -S --needed --noconfirm "${CORE_APPS[@]}"

# Install Essential Apps
for app in "${ESSENTIAL_APPS[@]}"; do
    if pacman -Qq "$app" &>/dev/null; then
        echo -e "${GREEN}  ✔ $app already installed${NC}"
    else
        echo -e "${BLUE}  Installing $app...${NC}"
        sudo pacman -S --needed --noconfirm "$app" 2>/dev/null || echo -e "${YELLOW}  ⚠ $app not found, skipping${NC}"
    fi
done

# Install AUR packages (if yay/paru is available)
if command -v yay &>/dev/null || command -v paru &>/dev/null; then
    echo -e "${BLUE}Installing AUR packages...${NC}"
    AUR_PACMAN="paru"
    command -v yay &>/dev/null && AUR_PACMAN="yay"
    
    AUR_APPS=(
        "visual-studio-code-bin"  # VS Code (proprietary)
        "brave-bin"               # Brave browser
        "antigravity"            # Game launcher
        "ani-cli"                # CLI anime player
        "miniconda3"             # Conda Python environment
    )
    
    for aur_app in "${AUR_APPS[@]}"; do
        echo -e "${BLUE}  Installing $aur_app...${NC}"
        $AUR_PACMAN -S --noconfirm "$aur_app" 2>/dev/null || echo -e "${YELLOW}  ⚠ $aur_app failed, skipping${NC}"
    done
else
    echo -e "${YELLOW}  ⚠ yay/paru not found, skipping AUR packages${NC}"
fi

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
echo -e "${YELLOW}Step 4: Setting up Refresh Rate Automation...${NC}"

# Get current user dynamically
USER_NAME=$(whoami)
USER_ID=$(id -u)

# Create the bulletproof refresh rate script
mkdir -p "$DOTFILES_DIR/scripts/.local/bin"
cat <<EOF >"$DOTFILES_DIR/scripts/.local/bin/power_profile.sh"
#!/bin/bash
USER_ID="\$(id -u)"
export XDG_RUNTIME_DIR="/run/user/\$USER_ID"

# Find the active Hyprland socket
SOCKET_FILE=\$(find /run/user/\$USER_ID/hypr/ -name ".socket.sock" | head -n 1)
if [ -z "\$SOCKET_FILE" ]; then exit 1; fi

HYPR_SIG=\$(basename \$(dirname "\$SOCKET_FILE"))
export HYPRLAND_INSTANCE_SIGNATURE="\$HYPR_SIG"

# Wait for power state to settle
sleep 1

# Check AC status and apply monitor settings (120Hz / 60Hz @ 1.25 scale)
if grep -q "0" /sys/class/power_supply/AC*/online; then
    /usr/bin/hyprctl --instance "\$HYPR_SIG" keyword monitor "eDP-1, 1920x1080@60, 0x0, 1.25"
    /usr/bin/notify-send "Power Status" "Battery Mode: 60Hz" -i battery
else
    /usr/bin/hyprctl --instance "\$HYPR_SIG" keyword monitor "eDP-1, 1920x1080@120, 0x0, 1.25"
    /usr/bin/notify-send "Power Status" "AC Mode: 120Hz" -i ac-adapter
fi
EOF
chmod +x "$DOTFILES_DIR/scripts/.local/bin/power_profile.sh"

# Write the Udev Rule with dynamic username
sudo bash -c "cat << EOF > /etc/udev/rules.d/99-monitor-refresh.rules
SUBSYSTEM==\"power_supply\", ACTION==\"change\", RUN+=\"/usr/bin/sudo -u $USER_NAME /home/$USER_NAME/.local/bin/power_profile.sh\"
EOF"

# --- 6. Stowing Dotfiles ---
echo -e "${YELLOW}Step 5: Symlinking Dotfiles with Stow...${NC}"

# Backup existing configs to avoid stow conflicts
CONFIGS=(hypr waybar kitty fastfetch)
for cfg in "${CONFIGS[@]}"; do
  if [ -d "$HOME/.config/$cfg" ] && [ ! -L "$HOME/.config/$cfg" ]; then
    echo -e "${BLUE}Backing up existing $cfg config...${NC}"
    mv "$HOME/.config/$cfg" "$HOME/.config/${cfg}_bak"
  fi
  stow -R "$cfg"
done

# Stow custom scripts (ensures power_profile.sh is linked)
stow -R scripts -t "$HOME"

# --- 7. Finalization ---
echo -e "${GREEN}--- ALL SYSTEMS GO ---${NC}"
echo -e "${BLUE}1. Hybrid GPU Active (use prime-run)${NC}"
echo -e "${BLUE}2. auto-cpufreq & TLP Coexisting${NC}"
echo -e "${BLUE}3. Refresh rate: 120Hz (AC) / 60Hz (BAT) @ 1.25 Scale${NC}"
echo -e "${YELLOW}Please REBOOT to apply all changes.${NC}"