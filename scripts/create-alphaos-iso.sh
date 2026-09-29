#!/bin/bash
# Alpha OS - Create Bootable ISO using live-build
# Ubuntu 26.04 LTS (Resolute Raccoon) based
# Replaces the old multiboot2-based script with a proper live-build ISO

set -e

LIVE_CONFIG_DIR="${1:-live/config}"
OUTPUT_DIR="${2:-output}"
ISO_NAME="alpha-os-1.0.0-$(date +%Y%m%d)"
ISO_FILE="${OUTPUT_DIR}/${ISO_NAME}.iso"

echo "============================================"
echo "Alpha OS ISO Creator (live-build)"
echo "============================================"
echo ""

# Check for live-build
if ! command -v lb &> /dev/null; then
    echo "[ERROR] live-build not found. Install it:"
    echo "  sudo apt-get install live-build"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if live-build is already configured
if [ ! -d "$LIVE_CONFIG_DIR" ]; then
    echo "[ERROR] live-build configuration not found at: $LIVE_CONFIG_DIR"
    echo "Run: make live-config"
    exit 1
fi

# Clean previous build
echo "[CLEAN] Cleaning previous build..."
lb clean 2>/dev/null || true

# Build the ISO
echo "[BUILD] Building ISO with live-build..."
lb build

# Copy the resulting ISO
if [ -f "live-image-amd64.hybrid.iso" ]; then
    cp "live-image-amd64.hybrid.iso" "$ISO_FILE"
    echo ""
    echo "============================================"
    echo "ISO Created Successfully!"
    echo "============================================"
    echo ""
    echo "Output: $ISO_FILE"
    echo "Size: $(du -h "$ISO_FILE" | cut -f1)"
    echo ""
    echo "To test in QEMU:"
    echo "  make run"
    echo ""
    echo "To write to USB:"
    echo "  sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
else
    echo "[ERROR] ISO build failed. Check the output above for errors."
    exit 1
fi