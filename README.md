# F13RC3 // Kei0s Lab - Hyprland Dotfiles

![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue?style=for-the-badge&logo=arch-linux)
![Distro](https://img.shields.io/badge/Distro-CachyOS-orange?style=for-the-badge&logo=linux)
![Framework](https://img.shields.io/badge/Framework-HyDE-purple?style=for-the-badge&logo=gnometerminal)

> **Kei0s Lab** - A high-performance, battery-optimized Hyprland environment

A high-performance, battery-optimized Hyprland environment built for **CachyOS** using the **HyDE** framework. This repository is managed via **GNU Stow** to ensure configuration portability and seamless system updates.

---

## Table of Contents

- [The "Separation of Powers" Strategy](#the-separation-of-powers-strategy)
- [Directory Structure](#directory-structure)
- [Tech Stack](#tech-stack)
- [Features](#features)
  - [Power Management](#power-management)
  - [Window Manager](#window-manager)
  - [Status Bar](#status-bar)
  - [Terminal](#terminal)
  - [System Info](#system-info)
- [Installation](#installation)
- [Post-Installation](#post-installation)
- [Customization](#customization)
  - [Themes](#themes)
  - [Animations](#animations)
  - [Lock Screens](#lock-screens)
  - [Shaders](#shaders)
  - [Workflows](#workflows)
- [Troubleshooting](#troubleshooting)

---

## The "Separation of Powers" Strategy

To achieve maximum battery longevity on hybrid-GPU hardware without compromising the responsiveness of the CachyOS kernel, this setup partitions system management into three distinct layers:

- **TLP**: Handles system-wide hardware power (USB, PCIe, Audio, Disk). CPU scaling is explicitly disabled in `/etc/tlp.conf` to prevent governor conflicts.
- **auto-cpufreq**: Exclusively manages CPU frequency scaling, governors, and Energy Performance Preferences (EPP).
- **EnvyControl**: Manages GPU switching, defaulted to **Hybrid Mode**. This allows the Nvidia dGPU to enter the `D3cold` (deep sleep) state when not utilized by `prime-run`.
- **Refresh-Rate Automator**: A custom `udev` and `hyprctl` integration that dynamically switches the display between 60Hz (Battery) and 120Hz (AC) at 1.25 scale, with desktop notifications.

---

## Directory Structure

```
~/dotfiles/
├── hypr/                   # Hyprland Window Manager
│   └── .config/hypr/
│       ├── hyprland.conf   # Main configuration
│       ├── keybindings.conf # Custom keybindings
│       ├── windowrules.conf # Window rules
│       ├── monitors.conf   # Monitor configuration
│       ├── userprefs.conf  # User preferences
│       ├── animations/    # Animation presets (18 themes)
│       ├── hyprlock/      # Lock screen themes (8 themes)
│       ├── shaders/       # Visual shaders (11 shaders)
│       ├── themes/        # Color schemes
│       ├── workflows/     # Power profiles (5 modes)
│       ├── scripts/       # Custom scripts
│       └── nvidia.conf    # GPU configuration
├── waybar/                 # Status Bar
│   └── .config/waybar/
│       ├── config.jsonc   # Main config
│       ├── style.css      # Styling
│       ├── modules/       # Module configs
│       ├── layouts/      # Layout presets
│       └── includes/      # Shared includes
├── kitty/                  # Terminal Emulator
│   └── .config/kitty/
├── fastfetch/             # System Info Display
│   └── .config/fastfetch/
│       ├── config.jsonc   # Configuration
│       └── logo/          # Custom ASCII logos (18 themes)
├── scripts/               # Custom Scripts
│   └── .local/bin/        # User scripts
├── hyde/                  # HyDE Framework (placeholder)
├── bin/                   # Binary scripts
└── install.sh            # Installation script
```

---

## Tech Stack

- **Compositor:** [Hyprland](https://hyprland.org/) (VFR enabled)
- **Framework:** [HyDE](https://github.com/prasanthrangan/hyprdots)
- **Kernel:** [CachyOS](https://cachyos.org/) (Optimized for low-latency)
- **Status Bar:** [Waybar](https://github.com/Alexays/Waybar) (Modular Layouts)
- **Terminal:** [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Shell:** Zsh / Bash
- **System Info:** [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- **Dotfiles Manager:** GNU Stow
- **Power Management:** TLP + auto-cpufreq + EnvyControl

---

## Features

### Power Management

| Feature | Description |
|---------|-------------|
| TLP | System-wide power management (USB, PCIe, Audio, Disk) |
| auto-cpufreq | CPU frequency scaling and governors |
| EnvyControl | Hybrid GPU mode with dGPU sleep |
| Refresh Rate Switcher | Auto-switch between 60Hz (battery) and 120Hz (AC) with notifications |
| libnotify | Desktop notifications for power events |
| Powertop | Additional power optimization |
| Thermald | Thermal management |

### Window Manager

- **18 Animation Presets**: classic, diablo-1/2, disable, dynamic, end4, fast, high, ja, LimeFrenzy, me-1/2, minimal-1/2, moving, optimized, standard, vertical
- **8 Lock Screen Themes**: Anurati, Arfan on Clouds, greetd, greetd-wallbash, HyDE, IBM Plex, IMB Xtented, SF Pro
- **11 Shaders**: blue-light-filter, color-vision, custom, disable, grayscale, invert-colors, oled-saver, paper, vibrance, wallbash
- **5 Workflow Modes**: default, editing, gaming, powersaver, snappy

### Status Bar

- Modular waybar configuration with hot-swappable layouts
- Custom CSS styling with theme support
- Clock, power, and custom modules

### Terminal

- Kitty terminal emulator with custom styling support

### System Info

- Fastfetch with **18 Custom ASCII Logos**:
  - Anime: gojo1/2/3, jinwoo, midoria1/2, anime1, otaku
  - Characters: aisaka, geass, loli, pochita, ryuzaki
  - Misc: agk_clan, cartoon, face, hyprland, L1

---

## Installation

This repository includes an idempotent `install.sh` script that installs dependencies, the HyDE framework, and symlinks all configurations.

```bash
# Clone the repository
git clone git@github.com:F13RC3/Hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer
chmod +x install.sh
./install.sh
```

The installer performs the following steps:

1. **Installs Core Dependencies**: stow, git, brightnessctl, tlp, auto-cpufreq, envycontrol, powertop, thermald, fastfetch, **libnotify**
2. **Installs HyDE Framework** (if not already installed)
3. **Configures Power Management**:
   - Disables TLP CPU management (for auto-cpufreq)
   - Disables power-profiles-daemon
   - Enables TLP, auto-cpufreq, powertop, thermald services
   - Sets EnvyControl to Hybrid mode
4. **Sets up Refresh Rate Automation**:
   - Creates `power_profile.sh` with socket detection and notifications
   - Configures udev rules to trigger on power supply changes
   - Auto-switches between 60Hz (battery) and 120Hz (AC) at 1.25 scale
5. **Symlinks Dotfiles with Stow**: Creates proper symlinks in `~/.config/`
6. **Finalization**: Shows next steps

---

## Post-Installation

After running `install.sh`, you must **REBOOT** to apply all kernel and udev changes.

### Verify Services

```bash
# Check TLP status
systemctl status tlp

# Check auto-cpufreq status
systemctl status auto-cpufreq

# Check GPU mode
envycontrol --status
```

### Manual Commands

- **Switch GPU Mode**: `sudo envycontrol -s [hybrid|nvidia|integrated]`
- **Change Power Profile**: Use the scripts in `~/.local/bin/`
- **Switch Animation Theme**: Edit `~/.config/hypr/animations/theme.conf`
- **Switch Lock Screen**: Edit `~/.config/hypr/hyprlock/theme.conf`

---

## Customization

### Themes

Color schemes are stored in `~/.config/hypr/themes/colors.conf`.

### Animations

18 animation presets available in `~/.config/hypr/animations/`:

| Preset | Description |
|--------|-------------|
| classic | Classic fade animations |
| diablo-1/2 | Diablo-inspired animations |
| disable | No animations |
| dynamic | Dynamic transitions |
| end4 | End4-style animations |
| fast | Fast transitions |
| high | High-quality animations |
| ja | Japanese-style animations |
| LimeFrenzy | Lime-themed animations |
| me-1/2 | Custom animations |
| minimal-1/2 | Minimal animations |
| moving | Moving animations |
| optimized | Performance-optimized |
| standard | Standard animations |
| vertical | Vertical animations |

### Lock Screens

8 lock screen themes in `~/.config/hypr/hyprlock/`:

- Anurati, Arfan on Clouds, greetd, greetd-wallbash, HyDE, IBM Plex, IMB Xtented, SF Pro

### Shaders

11 visual shaders in `~/.config/hypr/shaders/`:

- blue-light-filter, color-vision, custom, disable, grayscale, invert-colors, oled-saver, paper, vibrance, wallbash

### Workflows

5 power profiles in `~/.config/hypr/workflows/`:

- default, editing, gaming, powersaver, snappy

---

## Troubleshooting

### Hyprland not starting

```bash
# Check for errors
Hyprland 2>&1 | less

# Check journal
journalctl -xe --no-pager | grep Hyprland
```

### GPU Issues

```bash
# Check GPU mode
envycontrol --status

# Switch to nvidia mode for better performance
sudo envycontrol -s nvidia

# Switch back to hybrid for battery
sudo envycontrol -s hybrid
```

### Services not running

```bash
# Enable and start a service
sudo systemctl enable --now tlp
sudo systemctl enable --now auto-cpufreq

# Check service status
systemctl status tlp
systemctl status auto-cpufreq
```

### Refresh rate not switching

```bash
# Check udev rules
cat /etc/udev/rules.d/99-monitor-refresh.rules

# Test the script manually
~/.local/bin/power_profile.sh

# Check notification permissions
notify-send "Test" "Hello" -i battery
```

---

## License

MIT License - Feel free to use and modify these dotfiles.

---

## Credits

- [Hyprland](https://hyprland.org/) - The compositor
- [HyDE](https://github.com/prasanthrangan/hyprdots) - The framework
- [CachyOS](https://cachyos.org/) - The distribution
- All the theme creators for the amazing visuals