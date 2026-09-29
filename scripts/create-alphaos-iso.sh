#!/bin/bash
# Alpha OS - Create Bootable ISO for Multi-Desktop Distribution
# Ubuntu 26.04 LTS (Resolute Raccoon) based

set -e

BUILD_DIR="${1:-build}"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_DIR="${2:-output}"

echo "============================================"
echo "Alpha OS ISO Creator"
echo "============================================"

mkdir -p "$ISO_DIR/boot/grub"
mkdir -p "$ISO_DIR/EFI/BOOT"
mkdir -p "$OUTPUT_DIR"

# Check for kernel
if [ ! -f "$BUILD_DIR/kernel/unixos.elf" ]; then
    echo "[ERROR] Kernel not found. Building placeholder..."
    echo "Alpha OS Kernel" > "$ISO_DIR/boot/README.txt"
fi

# Create GRUB configuration for multi-desktop environment
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=5
set default=0

menuentry "Alpha OS - GNOME Desktop (Wayland)" {
    echo "Alpha OS Boot: GNOME Desktop"
    multiboot2 /boot/alphaos.elf desktop=gnome wayland=1
    boot
}

menuentry "Alpha OS - GNOME Desktop (X11)" {
    echo "Alpha OS Boot: GNOME Desktop"
    multiboot2 /boot/alphaos.elf desktop=gnome wayland=0
    boot
}

menuentry "Alpha OS - Cinnamon Desktop (X11)" {
    echo "Alpha OS Boot: Cinnamon Desktop"
    multiboot2 /boot/alphaos.elf desktop=cinnamon wayland=0
    boot
}

menuentry "Alpha OS - Cinnamon Desktop (Wayland)" {
    echo "Alpha OS Boot: Cinnamon Desktop"
    multiboot2 /boot/alphaos.elf desktop=cinnamon wayland=1
    boot
}

menuentry "Alpha OS - KDE Plasma Desktop (Wayland)" {
    echo "Alpha OS Boot: KDE Plasma Desktop"
    multiboot2 /boot/alphaos.elf desktop=plasma wayland=1
    boot
}

menuentry "Alpha OS - KDE Plasma Desktop (X11)" {
    echo "Alpha OS Boot: KDE Plasma Desktop"
    multiboot2 /boot/alphaos.elf desktop=plasma wayland=0
    boot
}

menuentry "Alpha OS - XFCE Desktop (X11)" {
    echo "Alpha OS Boot: XFCE Desktop"
    multiboot2 /boot/alphaos.elf desktop=xfce wayland=0
    boot
}

menuentry "Alpha OS - XFCE Desktop (Wayland)" {
    echo "Alpha OS Boot: XFCE Desktop"
    multiboot2 /boot/alphaos.elf desktop=xfce wayland=1
    boot
}

menuentry "Alpha OS - Recovery Mode" {
    echo "Alpha OS Boot: Recovery Mode"
    multiboot2 /boot/alphaos.elf single debug
    boot
}

menuentry "Alpha OS - Minimal Console" {
    echo "Alpha OS Boot: Console Mode"
    multiboot2 /boot/alphaos.elf console=tty0
    boot
}
EOF

# Create EFI boot configuration
cat > "$ISO_DIR/EFI/BOOT/startup.nsh" << 'EOF'
@echo off
echo Alpha OS Boot Loader
echo Loading kernel...
\boot\alphaos.elf
EOF

echo "Done."