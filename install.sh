#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Dotfiles Installation...${NC}"

# 1. Ensure we are in the dotfiles directory
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$DOTFILES_DIR"

# 2. Check for dependencies (CachyOS/Arch)
echo -e "${YELLOW}Checking dependencies...${NC}"
DEPENDENCIES=(stow git hyprland waybar kitty brightnessctl)

for tool in "${DEPENDENCIES[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo -e "${YELLOW}$tool not found. Installing...${NC}"
    sudo pacman -S --needed --noconfirm "$tool"
  else
    echo -e "${GREEN}✔ $tool is installed.${NC}"
  fi
done

# 3. Create necessary directories
echo -e "${YELLOW}Creating local directories...${NC}"
mkdir -p ~/.config
mkdir -p ~/.local/bin

# 4. Stow the packages
# Each folder in ~/dotfiles corresponds to a package
PACKAGES=(hypr waybar kitty)

echo -e "${YELLOW}Symlinking configurations with Stow...${NC}"
for pkg in "${PACKAGES[@]}"; do
  if [ -d "$pkg" ]; then
    echo -e "${BLUE}Stowing: $pkg${NC}"
    stow -R "$pkg" # -R flag restows (updates links if they exist)
  else
    echo -e "${YELLOW}Warning: Directory $pkg not found, skipping.${NC}"
  fi
done

# 5. Handle custom scripts (Stowing to a specific target)
if [ -d "scripts" ]; then
  echo -e "${BLUE}Stowing scripts to ~/.local/bin...${NC}"
  stow -R scripts -t ~/.local/bin
fi

# 6. Final Refresh
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${YELLOW}Note: You may need to reload Hyprland (Super+M) or Waybar to see changes.${NC}"
