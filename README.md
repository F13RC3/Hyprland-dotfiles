# F13RC3 // Hyprland Dotfiles

![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue?style=for-the-badge&logo=arch-linux)
![Distro](https://img.shields.io/badge/Distro-CachyOS-orange?style=for-the-badge&logo=linux)
![Framework](https://img.shields.io/badge/Framework-HyDE-purple?style=for-the-badge&logo=gnometerminal)

A performance-tuned and battery-optimized Hyprland environment built for **CachyOS** using the **HyDE** framework. This setup is managed via **GNU Stow** for portability and version-controlled configuration.

## 🔋 The "Separation of Powers" Strategy

This configuration implements a strict power management hierarchy to maximize battery life on hybrid-GPU laptops without sacrificing performance:

* **TLP**: Manages system-level power (USB, PCIe, Audio, Disk). CPU management is disabled in `/etc/tlp.conf` to avoid conflicts.
* **auto-cpufreq**: Exclusively handles CPU frequency scaling, governors, and EPP.
* **EnvyControl**: Configured in **Hybrid Mode**. The Nvidia dGPU is allowed to enter `D3cold` (deep sleep) while idle.
* **Refresh-Rate Automator**: A custom udev-triggered script that dynamically drops the display to 60Hz on battery and restores 144Hz+ on AC power.

## 🛠️ Tech Stack

- **Compositor:** [Hyprland](https://hyprland.org/)
- **Framework:** [HyDE](https://github.com/prasanthrangan/hyprdots) (Architecture-independent Hyprland configs)
- **Status Bar:** Waybar (Modular)
- **Terminal:** Kitty
- **Shell:** Zsh / Bash
- **File Manager:** Dolphin
- **App Launcher:** Rofi / Wofi

## 📦 Installation

This repository includes a "one-click" installation script that handles dependencies, the HyDE framework, power services, and symlinking.

```bash
# Clone the repository
git clone git@github.com:F13RC3/Hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer
chmod +x install.sh
./install.sh
