# Alpha OS Makefile
# Ubuntu 26.04 LTS (Resolute Raccoon) based distribution
# Using live-build for ISO creation

# ============================================================================
# Configuration
# ============================================================================

# Ubuntu version
UBUNTU_CODENAME := resolute
UBUNTU_VERSION := 26.04
KERNEL_VERSION := $(shell uname -r)

# Project
PROJECT := AlphaOS
PROJECT_VERSION := 1.0.0
PROJECT_ARCH := $(shell dpkg --print-architecture 2>/dev/null || echo amd64)
PROJECT_DATE := $(shell date +%Y%m%d)

# Directories
LIVE_CONFIG_DIR := live/config
PACKAGES_DIR := packages
OUTPUT_DIR := output
LIVE_IMAGE := live-image-amd64.hybrid.iso
ISO_FILE := $(OUTPUT_DIR)/alpha-os-$(PROJECT_VERSION)-$(PROJECT_DATE).iso

# ============================================================================
# Main Targets
# ============================================================================

.PHONY: all clean iso image run test help \
        check-env live-config live-build \
        clean-live clean-cache

all: iso
	@echo "============================================"
	@echo "$(PROJECT) $(PROJECT_VERSION) build complete!"
	@echo "============================================"
	@echo "ISO: $(ISO_FILE)"
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
	@echo "  iso              - Create bootable ISO using live-build"
	@echo "  live-config      - Configure live-build only"
	@echo "  live-build       - Build ISO with live-build (after config)"
	@echo "  check-env        - Check build environment"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean            - Remove build artifacts"
	@echo "  clean-all        - Remove all generated files and live-build cache"
	@echo "  clean-live       - Clean live-build state"
	@echo "  clean-cache      - Clean apt cache inside chroot"

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
	@command -v lb >/dev/null 2>&1 && echo "  [OK] live-build" || echo "  [WARN] live-build not found (install: sudo apt-get install live-build)"
	@command -v xorriso >/dev/null 2>&1 && echo "  [OK] xorriso" || echo "  [WARN] xorriso not found"
	@command -v mksquashfs >/dev/null 2>&1 && echo "  [OK] mksquashfs" || echo "  [WARN] mksquashfs not found"
	@command -v qemu-system-x86_64 >/dev/null 2>&1 && echo "  [OK] QEMU x86_64" || echo "  [WARN] QEMU x86_64 not found"
	@command -v qemu-system-aarch64 >/dev/null 2>&1 && echo "  [OK] QEMU ARM64" || echo "  [WARN] QEMU ARM64 not found"
	@echo ""
	@echo "Live-build config:"
	@if [ -d "$(LIVE_CONFIG_DIR)" ]; then echo "  [OK] live-build configured"; else echo "  [WARN] live-build not configured"; fi
	@echo ""
	@echo "To configure live-build: make live-config"

# ============================================================================
# Live-build Targets
# ============================================================================

live-config: clean-live
	@echo "============================================"
	@echo "Configuring live-build for Alpha OS"
	@echo "============================================"
	@./scripts/build-iso.sh config-only

live-build: live-config
	@echo "============================================"
	@echo "Building Alpha OS ISO with live-build"
	@echo "============================================"
	@if [ "$(USER)" != "root" ]; then \
		echo "Building as root (required for live-build)..."; \
		sudo lb build; \
	else \
		lb build; \
	fi
	@if [ -f "$(LIVE_IMAGE)" ]; then \
		mkdir -p "$(OUTPUT_DIR)"; \
		cp "$(LIVE_IMAGE)" "$(ISO_FILE)"; \
		echo ""; \
		echo "ISO created successfully: $(ISO_FILE)"; \
		echo "Size: $$(du -h "$(ISO_FILE)" | cut -f1)"; \
	else \
		echo "[ERROR] ISO build failed"; \
		exit 1; \
	fi

iso: live-build

# ============================================================================
# Testing
# ============================================================================

run: iso
	@echo "[RUN] Starting Alpha OS in QEMU (GUI)..."
	@qemu-system-x86_64 \
		-m 4G \
		-cpu host \
		-smp $$(nproc) \
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
	@qemu-system-x86_64 \
		-m 2G \
		-cpu host \
		-smp $$(nproc) \
		-drive if=none,id=hd0,format=raw,file="$(ISO_FILE)" \
		-device virtio-blk-device,drive=hd0 \
		-nographic \
		-boot d

test: iso
	@echo "[TEST] Running Alpha OS tests..."
	@./scripts/run-tests.sh
	@echo "Tests completed."

# ============================================================================
# Clean
# ============================================================================

clean:
	@echo "[CLEAN] Removing build artifacts..."
	@rm -rf "$(OUTPUT_DIR)"
	@rm -f alpha-os-*.iso alpha-os-*.img

clean-live:
	@echo "[CLEAN] Cleaning live-build state..."
	@lb clean

clean-cache:
	@echo "[CLEAN] Cleaning chroot apt cache..."
	@lb clean --cache

clean-all: clean clean-live clean-cache
	@echo "[DISTCLEAN] Removing all generated files..."
	@rm -rf live
	@rm -f $(LIVE_IMAGE)
	@rm -f alpha-os-*.iso alpha-os-*.img

.PHONY: all clean iso image run test help \
        check-env live-config live-build \
        clean-live clean-cache