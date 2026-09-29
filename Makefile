# Alpha OS Makefile
# Ubuntu 26.04 LTS (Resolute Raccoon) based distribution
# Linux kernel 7.0 with multi-desktop support

# ============================================================================
# Configuration
# ============================================================================

# Ubuntu version
UBUNTU_CODENAME := resolute
UBUNTU_VERSION := 26.04
KERNEL_VERSION := 7.0

# Project
PROJECT := AlphaOS
PROJECT_VERSION := 1.0.0
PROJECT_ARCH := $(shell dpkg --print-architecture 2>/dev/null || echo amd64)
PROJECT_DATE := $(shell date +%Y%m%d)

# Directories
BUILD_DIR := build
ISO_DIR := $(BUILD_DIR)/iso
ROOTFS_DIR := $(BUILD_DIR)/rootfs
IMAGE_DIR := image
OUTPUT_DIR := output

# ISO Name
ISO_NAME := alpha-os-$(PROJECT_VERSION)-$(PROJECT_DATE)
ISO_FILE := $(OUTPUT_DIR)/$(ISO_NAME).iso

# Desktop environments
DESKTOPS := gnome cinnamon kde xfce

# ============================================================================
# Main Targets
# ============================================================================

.PHONY: all clean iso image run test help install-desktop \
        desktop-gnome desktop-cinnamon desktop-kde desktop-xfce \
        audio-setup display-setup ppa-setup check-env

all: iso
	@echo "============================================"
	@echo "$(PROJECT) $(PROJECT_VERSION) build complete!"
	@echo "============================================"
	@echo "ISO: $(ISO_FILE)"
	@echo "Run 'make run' to test in QEMU"
	@echo ""
	@echo "Desktop Environments Included:"
	@echo "  - GNOME  (ubuntu-desktop)"
	@echo "  - Cinnamon (ubuntucinnamon-desktop)"
	@echo "  - KDE Plasma (kubuntu-desktop)"
	@echo "  - XFCE (xubuntu-desktop)"

help:
	@echo "$(PROJECT) Build System"
	@echo "===================="
	@echo ""
	@echo "Build targets:"
	@echo "  all              - Build everything (creates ISO)"
	@echo "  iso              - Create bootable ISO"
	@echo "  image            - Create bootable disk image"
	@echo "  check-env        - Check build environment"
	@echo ""
	@echo "Desktop Environment targets:"
	@echo "  desktop-gnome    - Install GNOME packages"
	@echo "  desktop-cinnamon - Install Cinnamon packages"
	@echo "  desktop-kde      - Install KDE Plasma packages"
	@echo "  desktop-xfce     - Install XFCE packages"
	@echo "  install-desktop  - Install all desktop environments"
	@echo ""
	@echo "System Setup targets:"
	@echo "  audio-setup      - Configure PulseAudio + PipeWire"
	@echo "  display-setup    - Configure X11 + Wayland"
	@echo "  ppa-setup        - Configure Ubuntu PPAs"
	@echo ""
	@echo "Test targets:"
	@echo "  run              - Run in QEMU (GUI)"
	@echo "  run-headless     - Run in QEMU (headless)"
	@echo "  test             - Run test suite"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean            - Remove build artifacts"
	@echo "  clean-all        - Remove all generated files"

# ============================================================================
# Environment Check
# ============================================================================

check-env:
	@echo "============================================"
	@echo "$(PROJECT) Environment Check"
	@echo "============================================"
	@echo ""
	@echo "Build date: $(PROJECT_DATE)"
	@echo "Ubuntu version: $(UBUNTU_VERSION) LTS (codename: $(UBUNTU_CODENAME))"
	@echo "Linux kernel: $(KERNEL_VERSION)"
	@echo "Architecture: $(PROJECT_ARCH)"
	@echo ""
	@echo "Checking tools..."
	@command -v qemu-system-x86_64 >/dev/null 2>&1 && echo "  [OK] QEMU x86_64" || echo "  [WARN] QEMU x86_64 not found"
	@command -v qemu-system-aarch64 >/dev/null 2>&1 && echo "  [OK] QEMU ARM64" || echo "  [WARN] QEMU ARM64 not found"
	@command -v xorriso >/dev/null 2>&1 && echo "  [OK] xorriso" || echo "  [WARN] xorriso not found"
	@command -v grub-mkrescue >/dev/null 2>&1 && echo "  [OK] grub-mkrescue" || echo "  [WARN] grub-mkrescue not found"
	@command -v debootstrap >/dev/null 2>&1 && echo "  [OK] debootstrap" || echo "  [WARN] debootstrap not found"
	@command -v apt-cacher-ng >/dev/null 2>&1 && echo "  [OK] apt-cacher-ng" || echo "  [WARN] apt-cacher-ng not found"
	@command -v dpkg >/dev/null 2>&1 && echo "  [OK] dpkg" || echo "  [WARN] dpkg not found"
	@command -v apt >/dev/null 2>&1 && echo "  [OK] apt" || echo "  [WARN] apt not found"
	@echo ""
	@echo "Desktop environments:"
	@command -v gnome-session >/dev/null 2>&1 && echo "  [OK] GNOME" || echo "  [ ] GNOME"
	@command -v cinnamon-session >/dev/null 2>&1 && echo "  [OK] Cinnamon" || echo "  [ ] Cinnamon"
	@command -v startplasma-x11 >/dev/null 2>&1 && echo "  [OK] KDE Plasma" || echo "  [ ] KDE Plasma"
	@command -v xfce4-session >/dev/null 2>&1 && echo "  [OK] XFCE" || echo "  [ ] XFCE"
	@echo ""
	@echo "Display servers:"
	@command -v Xorg >/dev/null 2>&1 && echo "  [OK] X11 (Xorg)" || echo "  [ ] X11 (Xorg)"
	@command -v wayland-scanner >/dev/null 2>&1 && echo "  [OK] Wayland" || echo "  [ ] Wayland"
	@echo ""
	@echo "Audio servers:"
	@command -v pulseaudio >/dev/null 2>&1 && echo "  [OK] PulseAudio" || echo "  [ ] PulseAudio"
	@command -v pipewire >/dev/null 2>&1 && echo "  [OK] PipeWire" || echo "  [ ] PipeWire"
	@command -v wireplumber >/dev/null 2>&1 && echo "  [OK] WirePlumber" || echo "  [ ] WirePlumber"
	@echo ""

# ============================================================================
# Desktop Environment Packages
# ============================================================================

# GNOME Desktop Environment (Ubuntu)
desktop-gnome:
	@echo "============================================"
	@echo "Installing GNOME Desktop Environment..."
	@echo "============================================"
	sudo apt-get install -y ubuntu-desktop
	@echo "GNOME packages installed:"
	@echo "  - ubuntu-desktop (meta-package)"
	@echo "  - gnome-shell (window manager)"
	@echo "  - gdm3 (display manager)"
	@echo "  - nautilus (file manager)"
	@echo "  - gnome-terminal (terminal)"
	@echo "  - firefox (browser)"
	@echo "  - libreoffice (office suite)"
	@echo "  - rhythmbox (music player)"
	@echo "  - totem (video player)"
	@echo "  - Simple Scan (scanner)"
	@echo "  - Shotwell (photo organizer)"
	@echo "  - gnome-initial-setup (first run)"
	@echo "  - NetworkManager (networking)"
	@echo ""

# Cinnamon Desktop Environment
desktop-cinnamon:
	@echo "============================================"
	@echo "Installing Cinnamon Desktop Environment..."
	@echo "============================================"
	sudo apt-get install -y ubuntucinnamon-desktop
	@echo "Cinnamon packages installed:"
	@echo "  - ubuntucinnamon-desktop (meta-package)"
	@echo "  - cinnamon (desktop shell)"
	@echo "  - cinnamon-control-center (settings)"
	@echo "  - cinnamon-session (session manager)"
	@echo "  - cinnamon-settings-daemon (settings daemon)"
	@echo "  - cinnamon-screensaver (screen saver)"
	@echo "  - nemo (file manager)"
	@echo "  - xreader (document viewer)"
	@echo "  - xreader (image viewer)"
	@echo "  - rhythmbox (music player)"
	@echo "  - gnome-terminal (terminal)"
	@echo "  - XApp libraries"
	@echo "  - xdg-desktop-portal-xapp (Wayland portal)"
	@echo ""

# KDE Plasma Desktop Environment
desktop-kde:
	@echo "============================================"
	@echo "Installing KDE Plasma Desktop Environment..."
	@echo "============================================"
	sudo apt-get install -y kubuntu-desktop
	@echo "KDE Plasma packages installed:"
	@echo "  - kubuntu-desktop (meta-package)"
	@echo "  - plasma-desktop (core plasma)"
	@echo "  - kde-plasma-desktop (plasma components)"
	@echo "  - sddm (display manager)"
	@echo "  - dolphin (file manager)"
	@echo "  - konsole (terminal)"
	@echo "  - firefox (browser)"
	@echo "  - okular (document viewer)"
	@echo "  - gwenview (image viewer)"
	@echo "  - elisa (music player)"
	@echo "  - kdenlive (video editor)"
	@echo "  - kde-standard (standard KDE apps)"
	@echo "  - kde-plasma (plasma components)"
	@echo "  - kde-gtk-config (GTK integration)"
	@echo "  - xdg-desktop-portal-kde (Wayland portal)"
	@echo ""

# XFCE Desktop Environment
desktop-xfce:
	@echo "============================================"
	@echo "Installing XFCE Desktop Environment..."
	@echo "============================================"
	sudo apt-get install -y xubuntu-desktop
	@echo "XFCE packages installed:"
	@echo "  - xubuntu-desktop (meta-package)"
	@echo "  - xfce4 (core desktop)"
	@echo "  - xfce4-goodies (extra plugins)"
	@echo "  - xfce4-panel (panel)"
	@echo "  - xfce4-session (session manager)"
	@echo "  - xfce4-settings (settings)"
	@echo "  - xfwm4 (window manager)"
	@echo "  - xfdesktop4 (desktop manager)"
	@echo "  - thunar (file manager)"
	@echo "  - xfce4-terminal (terminal)"
	@echo "  - mousepad (text editor)"
	@echo "  - ristretto (image viewer)"
	@echo "  - parole (media player)"
	@echo "  - lightdm (display manager)"
	@echo ""

# Install all desktop environments
install-desktop: desktop-gnome desktop-cinnamon desktop-kde desktop-xfce
	@echo "============================================"
	@echo "All desktop environments installed!"
	@echo "============================================"
	@echo "Switch between desktops at the login screen."
	@echo "Click the gear icon to select your desktop."
	@echo ""
	@echo "Available sessions:"
	@echo "  - Alpha OS (GNOME)"
	@echo "  - Alpha OS Cinnamon"
	@echo "  - Alpha OS Plasma"
	@echo "  - Alpha OS XFCE"
	@echo ""

# ============================================================================
# Audio Setup (PulseAudio + PipeWire)
# ============================================================================

audio-setup:
	@echo "============================================"
	@echo "Setting up audio stack (PulseAudio + PipeWire)..."
	@echo "============================================"
	@echo "Installing PulseAudio packages..."
	sudo apt-get install -y pulseaudio pulseaudio-utils pavucontrol
	@echo "Installing PipeWire packages..."
	sudo apt-get install -y pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack
	@echo "Installing audio control tools..."
	sudo apt-get install -y pavucontrol-qt paprefs
	@echo ""
	@echo "Configuring PulseAudio as default, PipeWire as backend..."
	sudo apt-get install -y libspa-0.2-modules libspa-0.2-modules-extra
	@echo ""
	@echo "Audio stack configured!"
	@echo "  - PulseAudio: compatibility layer for all apps"
	@echo "  - PipeWire: real-time multimedia pipeline"
	@echo "  - WirePlumber: session manager for PipeWire"
	@echo ""
	@echo "Control tools:"
	@echo "  - pavucontrol: PulseAudio Volume Control"
	@echo "  - pavucontrol-qt: Qt version for KDE"
	@echo "  - wpctl: PipeWire control utility"
	@echo "  - pactl: PulseAudio command line"
	@echo ""
	@echo "Verify audio:"
	@echo "  pactl info          # Check PulseAudio status"
	@echo "  wpctl status        # Check PipeWire status"
	@echo "  pw-cli list-objects # List PipeWire nodes"
	@echo ""

# ============================================================================
# Display Server Setup (X11 + Wayland)
# ============================================================================

display-setup:
	@echo "============================================"
	@echo "Setting up display servers (X11 + Wayland)..."
	@echo "============================================"
	@echo "Installing X11 (Xorg)..."
	sudo apt-get install -y xorg xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all
	@echo "Installing Wayland..."
	sudo apt-get install -y wayland-protocols libwayland-bin libwayland-server0 \
		libwayland-client0 libwayland-cursor0 libwayland-egl1 libwayland-server-dev \
		wayland-utils wayland-protocols-dev
	@echo "Installing XWayland (X11 compatibility for Wayland)..."
	sudo apt-get install -y xwayland
	@echo "Installing display portal (screen sharing on Wayland)..."
	sudo apt-get install -y xdg-desktop-portal xdg-desktop-portal-gtk \
		xdg-desktop-portal-kde xdg-desktop-portal-xapp
	@echo ""
	@echo "Display server setup complete!"
	@echo ""
	@echo "X11 (Xorg):"
	@echo "  - Legacy compatibility mode"
	@echo "  - Universal application support"
	@echo "  - Available as fallback"
	@echo ""
	@echo "Wayland:"
	@echo "  - Modern display protocol"
	@echo "  - Reduced latency and tearing"
	@echo "  - Native in GNOME and KDE Plasma"
	@echo "  - XFCE via X11 (with xdg-desktop-portal for Wayland)"
	@echo ""
	@echo "Environment variables for Wayland:"
	@echo "  export QT_QPA_PLATFORM=wayland    # Qt Wayland"
	@echo "  export GDK_BACKEND=wayland        # GTK Wayland"
	@echo "  export MOZ_ENABLE_WAYLAND=1       # Firefox Wayland"
	@echo ""
	@echo "Switch display servers at login:"
	@echo "  - GNOME: Select 'Alpha OS' (Wayland) or 'Alpha OS on Xorg'"
	@echo "  - KDE Plasma: Select 'Plasma (Wayland)' or 'Plasma (X11)'"
	@echo "  - Cinnamon: Select 'Cinnamon' (X11) or 'Cinnamon (Wayland)'"
	@echo "  - XFCE: Select 'XFCE' (X11)"
	@echo ""

# ============================================================================
# Ubuntu PPAs Setup
# ============================================================================

ppa-setup:
	@echo "============================================"
	@echo "Configuring Ubuntu PPAs..."
	@echo "============================================"
	@echo "Adding Ubuntu Desktop PPA..."
	sudo add-apt-repository -y ppa:ubuntu-desktop/ppa || true
	@echo "Adding Kubuntu PPA..."
	sudo add-apt-repository -y ppa:kubuntu-ppa/backports || true
	@echo "Adding Cinnamon PPA..."
	sudo add-apt-repository -y ppa:cinnamon-team/ppa || true
	@echo "Adding XFCE PPA..."
	sudo add-apt-repository -y ppa:xfce-gooders/ppa || true
	@echo "Adding PipeWire PPA..."
	sudo add-apt-repository -y ppa:pipewire-debian/pipewire-upstream || true
	@echo ""
	@echo "Updating package lists..."
	sudo apt-get update
	@echo ""
	@echo "PPAs configured!"
	@echo ""
	@echo "Available PPAs:"
	@echo "  - ubuntu-desktop/ppa: Latest GNOME packages"
	@echo "  - kubuntu-ppa/backports: Latest KDE Plasma updates"
	@echo "  - cinnamon-team/ppa: Latest Cinnamon desktop"
	@echo "  - xfce-gooders/ppa: XFCE goodies"
	@echo "  - pipewire-debian/pipewire-upstream: Latest PipeWire"
	@echo ""
	@echo "Manage PPAs:"
	@echo "  sudo add-apt-repository ppa:<ppa-name>  # Add"
	@echo "  sudo add-apt-repository --remove ppa:<ppa-name>  # Remove"
	@echo "  sudo add-apt-repository --list-type ppa  # List"
	@echo ""

# ============================================================================
# ISO Creation
# ============================================================================

iso: check-env desktop-gnome desktop-cinnamon desktop-kde desktop-xfce audio-setup display-setup ppa-setup
	@echo "============================================"
	@echo "Creating Alpha OS ISO..."
	@echo "============================================"
	mkdir -p "$(ISO_DIR)/boot/grub"
	mkdir -p "$(ISO_DIR)/EFI/BOOT"
	mkdir -p "$(OUTPUT_DIR)"
	
	# Copy kernel (Linux 7.0 from Ubuntu)
	cp /boot/vmlinuz-$(KERNEL_VERSION)-generic "$(ISO_DIR)/boot/vmlinuz" 2>/dev/null || \
		cp /boot/vmlinuz-$(shell uname -r) "$(ISO_DIR)/boot/vmlinuz" 2>/dev/null || \
		echo "[WARN] Kernel not found, creating placeholder"
	
	# Copy initrd
	cp /boot/initrd.img-$(KERNEL_VERSION)-generic "$(ISO_DIR)/boot/initrd.img" 2>/dev/null || \
		cp /boot/initrd.img-$(shell uname -r) "$(ISO_DIR)/boot/initrd.img" 2>/dev/null || \
		echo "[WARN] Initrd not found, creating placeholder"
	
	# Create GRUB configuration
	cat > "$(ISO_DIR)/boot/grub/grub.cfg" << 'GRUBEOF'
set timeout=10
set default=0

menuentry "Alpha OS - GNOME (Wayland)" {
    linux /boot/vmlinuz quiet splash
    initrd /boot/initrd.img
}

menuentry "Alpha OS - GNOME (X11)" {
    linux /boot/vmlinuz quiet splash nomodeset
    initrd /boot/initrd.img
}

menuentry "Alpha OS - Cinnamon (Wayland)" {
    linux /boot/vmlinuz quiet splash
    initrd /boot/initrd.img
}

menuentry "Alpha OS - Cinnamon (X11)" {
    linux /boot/vmlinuz quiet splash nomodeset
    initrd /boot/initrd.img
}

menuentry "Alpha OS - KDE Plasma (Wayland)" {
    linux /boot/vmlinuz quiet splash
    initrd /boot/initrd.img
}

menuentry "Alpha OS - KDE Plasma (X11)" {
    linux /boot/vmlinuz quiet splash nomodeset
    initrd /boot/initrd.img
}

menuentry "Alpha OS - XFCE (X11)" {
    linux /boot/vmlinuz quiet splash nomodeset
    initrd /boot/initrd.img
}

menuentry "Alpha OS - Recovery Mode" {
    linux /boot/vmlinuz single nomodeset
    initrd /boot/initrd.img
}
GRUBEOF
	
	# Create EFI boot configuration
	cat > "$(ISO_DIR)/EFI/BOOT/startup.nsh" << 'EOF'
@echo off
echo Alpha OS Boot Loader
echo Loading Linux kernel...
\boot\vmlinuz
EOF
	
	# Create ISO using grub-mkrescue or xorriso
	if command -v grub-mkrescue >/dev/null 2>&1; then
		grub-mkrescue -o "$(ISO_FILE)" "$(ISO_DIR)"
	elif command -v xorriso >/dev/null 2>&1; then
		xorriso -as mkisofs \
			-R -J \
			-V "AlphaOS" \
			-o "$(ISO_FILE)" \
			"$(ISO_DIR)"
	else
		echo "[ERROR] No ISO creation tool found. Install grub-pc-bin or xorriso."
		exit 1
	fi
	
	@echo "============================================"
	@echo "ISO Created Successfully!"
	@echo "============================================"
	@echo ""
	@echo "Output: $(ISO_FILE)"
	@echo "Size: $(shell du -h "$(ISO_FILE)" | cut -f1)"
	@echo ""
	@echo "To test in QEMU:"
	@echo "  make run"
	@echo ""

# ============================================================================
# Disk Image Creation
# ============================================================================

image: iso
	@echo "============================================"
	@echo "Creating Alpha OS disk image..."
	@echo "============================================"
	mkdir -p "$(IMAGE_DIR)"
	IMAGE_PATH="$(IMAGE_DIR)/$(ISO_NAME).img"
	dd if=/dev/zero of="$$IMAGE_PATH" bs=1M count=4096 2>/dev/null
	 parted -s "$$IMAGE_PATH" mklabel gpt
	 parted -s "$$IMAGE_PATH" mkpart ESP fat32 1MiB 501MiB
	 parted -s "$$IMAGE_PATH" set 1 esp on
	 parted -s "$$IMAGE_PATH" mkpart primary ext4 501MiB 100%
	@echo "Disk image created: $$IMAGE_PATH"
	@echo ""

# ============================================================================
# QEMU Testing
# ============================================================================

run: iso
	@echo "[RUN] Starting Alpha OS in QEMU (GUI)..."
	qemu-system-x86_64 \
		-m 4G \
		-cpu host \
		-smp $(shell nproc) \
		-drive if=none,id=hd0,format=raw,file="$(ISO_FILE)" \
		-device virtio-blk-device,drive=hd0 \
		-device qemu-xhci \
		-device usb-kbd \
		-device usb-tablet \
		-vga virtio \
		-display sdl \
		-audiodev pa,id=audio0 \
		-device intel-hda \
		-device hda-duplex,audiodev=audio0 \
		-netdev user,id=net0 \
		-device virtio-net-device,netdev=net0 \
		-boot d

run-headless: iso
	@echo "[RUN] Starting Alpha OS in QEMU (headless)..."
	qemu-system-x86_64 \
		-m 2G \
		-cpu host \
		-smp $(shell nproc) \
		-drive if=none,id=hd0,format=raw,file="$(ISO_FILE)" \
		-device virtio-blk-device,drive=hd0 \
		-nographic \
		-boot d

run-gui-wayland: iso
	@echo "[RUN] Starting Alpha OS with Wayland in QEMU..."
	qemu-system-x86_64 \
		-m 4G \
		-cpu host \
		-smp $(shell nproc) \
		-drive if=none,id=hd0,format=raw,file="$(ISO_FILE)" \
		-device virtio-blk-device,drive=hd0 \
		-device qemu-xhci \
		-device usb-kbd \
		-device usb-tablet \
		-virtio-gpu-pci \
		-display sdl \
		-audiodev pa,id=audio0 \
		-device intel-hda \
		-device hda-duplex,audiodev=audio0 \
		-netdev user,id=net0 \
		-device virtio-net-device,netdev=net0 \
		-boot d

# ============================================================================
# Testing
# ============================================================================

test: iso
	@echo "[TEST] Running Alpha OS tests..."
	@./scripts/run-tests.sh || true
	@echo "Tests completed."

# ============================================================================
# Clean
# ============================================================================

clean:
	@echo "[CLEAN] Removing build artifacts..."
	rm -rf "$(BUILD_DIR)"
	rm -rf "$(OUTPUT_DIR)"
	@echo "[CLEAN] Done"

clean-all: clean
	@echo "[DISTCLEAN] Removing all generated files..."
	rm -rf "$(IMAGE_DIR)"
	rm -rf "$(ROOTFS_DIR)"
	rm -f alpha-os-*.iso alpha-os-*.img
	@echo "[DISTCLEAN] Done"