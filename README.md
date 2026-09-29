# Alpha OS

**Ubuntu-Based Operating System with Multi-Desktop Support**

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Platform](https://img.shields.io/badge/platform-AMD64%20%7C%20ARM64-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04%20LTS%20(Resolute%20Raccoon)-orange)
![License](https://img.shields.io/badge/license-MIT-green)

```
        _  _         ___  ____ 
 __   _(_)| |__     / _ \/ ___| 
 \ \ / / || '_ \   | | | \___ \ 
  \ V /| || |_) |  | |_| |___) |
   \_/ |_||_.__/    \___/|____/ 
```

Alpha OS v1.0.0 - Ubuntu-Based Multi-Desktop Distribution

<p align="center">
  <img src="screenshots/main.png" alt="Alpha OS Desktop" width="800">
</p>

## Overview

Alpha OS is an Ubuntu 26.04 LTS (Resolute Raccoon) based distribution that brings together four world-class desktop environments in a single, cohesive operating system. Built on the latest Ubuntu 26.04 with Linux kernel 7.0, Alpha OS features **GNOME**, **Cinnamon**, **KDE Plasma**, and **XFCE** desktop environments, each with full X11 and Wayland display server support.

## 🎯 Supported Architectures

| Architecture | Status | Hardware |
|--------------|--------|----------|
| **AMD64 (x86_64)** | ✅ | Modern PCs, VirtualBox, VMware, Real Hardware |
| **ARM64** | ✅ | Raspberry Pi 5, Apple Silicon (via UTM), QEMU virt |

## 📸 Screenshots

### GNOME Desktop
![GNOME](screenshots/gnome.png)
*Modern, touch-friendly GNOME desktop with Wayland support*

### Cinnamon Desktop
![Cinnamon](screenshots/cinnamon.png)
*Traditional layout Cinnamon desktop with GNOME 2 aesthetics*

### KDE Plasma Desktop
![KDE](screenshots/plasma.png)
*Feature-rich KDE Plasma 6 desktop with full hardware acceleration*

### XFCE Desktop
![XFCE](screenshots/xfce.png)
*Lightweight XFCE 4.20 desktop for optimal performance*

## 🛠 Desktop Environments

Alpha OS includes all four major desktop environments, selectable at the login screen:

### GNOME (Default)
- **Package**: `ubuntu-desktop`
- **Display Manager**: GDM3
- **Display Server**: X11 + Wayland
- **Features**: Modern UI, integrated services, touch optimizations
- **Recommended**: 4GB RAM minimum, 25GB disk space

### Cinnamon
- **Package**: `ubuntucinnamon-desktop`
- **Display Manager**: GDM3 or LightDM
- **Display Server**: X11 + Wayland
- **Features**: Traditional desktop layout, GNOME 2 compatibility, lightweight
- **Recommended**: 2GB RAM minimum, 20GB disk space

### KDE Plasma
- **Package**: `kubuntu-desktop`
- **Display Manager**: SDDM
- **Display Server**: X11 + Wayland
- **Features**: Highly customizable, Plasma 6, full Qt integration
- **Recommended**: 2GB RAM minimum, 25GB disk space

### XFCE
- **Package**: `xubuntu-desktop`
- **Display Manager**: LightDM
- **Display Server**: X11 + Wayland
- **Features**: Lightweight, traditional layout, low resource usage
- **Recommended**: 1GB RAM minimum, 15GB disk space

## 🐌 Audio & Media

### PulseAudio + PipeWire
Alpha OS features modern audio stack with both PulseAudio and PipeWire:

- **PulseAudio**: Compatible sound server for all applications
- **PipeWire**: Next-generation multimedia pipeline replacing PulseAudio/ALSA
- **WirePlumber**: PipeWire session manager
- **PulseAudio-BlueZ**: Bluetooth audio support
- **apulse**: PulseAudio compatibility layer for Wayland

**Audio Stack**: Applications → PulseAudio (via libpulse) → PipeWire → ALSA/JACK

**Control Tools**:
- `pavucontrol` - PulseAudio Volume Control
- `pavucontrol-qt` - Qt version for Plasma
- `wpctl` - PipeWire control utility
- `pactl` - PulseAudio command line control

### Multi-Media Support
- **MP3 Decoder**: minimp3 library
- **JPEG Decoder**: libjpeg integration
- **Video Playback**: GStreamer framework with hardware acceleration
- **Screen Capture**: xdg-desktop-portal with Wayland support

## 🖥 Display Server Support

Alpha OS supports both **X11** and **Wayland** display servers across all desktop environments:

### X11 (Xorg)
- Legacy compatibility mode
- Universal application support
- Proven stability and maturity
- Available as fallback in all DEs

### Wayland
- Modern display server protocol
- Reduced latency and tearing
- Native GNOME session (default)
- KDE Plasma Wayland session
- XFCE X11 fallback with Wayland support via xdg-desktop-portal

**Environment Variables**:
- `QT_QPA_PLATFORM=wayland` - Force Qt Wayland
- `GDK_BACKEND=wayland` - Force GTK Wayland
- `MOZ_ENABLE_WAYLAND=1` - Firefox Wayland support

## 📦 Ubuntu PPAs

Alpha OS includes support for third-party PPAs to get the latest software:

### Added PPAs:
- `ubuntu-desktop-ppa` - Latest GNOME packages
- `kubuntu-ppa/ppa` - Latest KDE Plasma updates
- `cinnamon-team/ppa` - Latest Cinnamon desktop
- `xfce-gooders/ppa` - XFCE goodies and plugins

**Adding/Removing PPAs**:
```bash
# Add a PPA
sudo add-apt-repository ppa:ubuntu-desktop/ppa
sudo apt update

# Remove a PPA
sudo add-apt-repository --remove ppa:kubuntu/ppa
sudo apt update

# List all PPAs
sudo add-apt-repository --list-type ppa
```

## 🚀 Quick Start

### Installation

Alpha OS can be installed from a USB drive or run live from ISO:

```bash
# Download Alpha OS ISO from the releases page
# Write to USB: sudo dd if=alpha-os.iso of=/dev/sdX bs=4M status=progress

# Boot from USB and select desired desktop environment at login
```

### First Boot
1. Select your preferred desktop environment at the login screen
2. Login with your credentials
3. Choose your display server (X11 or Wayland) at the session selector
4. Start exploring!

### Switching Between Desktops
At the login screen, click the gear icon or session selector to choose:
- Alpha OS (GNOME)
- Alpha OS Cinnamon
- Alpha OS Plasma
- Alpha OS XFCE

### Updating System
```bash
sudo apt update && sudo apt upgrade
sudo do-release-upgrade  # For future Ubuntu LTS upgrades
```

## 🛠 System Requirements

| Desktop | RAM | Disk Space | GPU |
|---------|-----|------------|-----|
| **GNOME** | 4GB+ | 25GB+ | Modern with 3D acceleration |
| **Cinnamon** | 2GB+ | 20GB+ | Integrated or dedicated |
| **KDE Plasma** | 2GB+ | 25GB+ | Modern with 3D acceleration |
| **XFCE** | 1GB+ | 15GB+ | Any |

## 🌐 Networking

Alpha OS includes full networking support:
- DHCP client (NetworkManager)
- WiFi support (nm-applet)
- IPv4/IPv6 dual stack
- VPN support
- Firewall (ufw)

## 📦 Package Management

- **APT**: `apt`, `apt-get`, `apt-cache`
- **Snap**: Pre-installed for sandboxed applications
- **Flatpak**: Support for cross-distro applications
- **PPAs**: Third-party package repositories

## 🛡 Security

- **Full Disk Encryption**: LUKS during installation
- **AppArmor**: Mandatory access control profiles
- **Firewall**: UFW enabled by default
- **Regular Security Updates**: Via Ubuntu Pro

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Canonical**: Ubuntu 26.04 LTS foundation
- **GNOME Project**: GNOME desktop environment
- **Cinnamon Team**: Cinnamon desktop environment (Linux Mint)
- **KDE Community**: KDE Plasma 6 desktop
- **XFCE Project**: XFCE desktop environment
- **PipeWire Developers**: Multimedia framework
- **PulseAudio Team**: Sound server
- **Ubuntu Community**: Testing and feedback

## 📞 Contact

- **Website**: [alpha-os.example.com](https://alpha-os.example.com)
- **GitHub**: [github.com/ilovecheez/Alpha-OS](https://github.com/ilovecheez/Alpha-OS)
- **Issues**: [GitHub Issues](https://github.com/ilovecheez/Alpha-OS/issues)

*"The future of desktop computing, unified in a single distribution."*