# Alpha OS Makefile
# Ubuntu 26.04 LTS ("resolute") live distribution built with live-build.
#
# ============================================================================
# Flow
# ============================================================================
#   make config   -> ./auto/config   -> lb config   (writes config/ + cache/)
#   make build    -> ./auto/build    -> lb build    (needs root, makes the ISO)
#   make iso/all  -> clean + config + build, then stage the ISO in output/
#
# The ISO is produced entirely by live-build. This Makefile never installs
# packages on the build host, never copies the host's kernel into an image,
# and never hand-writes a bootloader config. Output is either
# binary.hybrid.iso (LB_BINARY_IMAGES=iso-hybrid, our default) or binary.iso;
# the name is fixed by live-build, there is no --image-name option.
#
# ============================================================================
# live-build version warning - READ THIS
# ============================================================================
# Ubuntu 26.04 ships live-build 3.0~a57-1ubuntu54, a 2012-era tree. Debian's
# modern live-build is NOT API-compatible and must not be used instead. Two
# consequences bite hard:
#
#   1. In "ubuntu" mode this version hard-codes the distribution to "precise".
#      If --distribution is not passed, you silently build a 12.04 image
#      instead of resolute. --distribution resolute is MANDATORY.
#   2. --syslinux-theme live-build is MANDATORY; the default theme path does
#      not exist in this tree and the binary stage aborts.
#
# Options such as --image-type, --hybrid-iso, --squashfs, --backports,
# --hostname, --timezone and --output-directory do NOT exist in this version.
# Do not add them.
# ============================================================================

UBUNTU_CODENAME := resolute
UBUNTU_VERSION  := 26.04

PROJECT         := Alpha OS
PROJECT_VERSION := 1.0.0

ISO_NAME    := alpha-os-$(PROJECT_VERSION)-$(shell date +%Y%m%d)
OUTPUT_DIR  := output
RELEASE_ISO := $(OUTPUT_DIR)/$(ISO_NAME).iso

QEMU        ?= qemu-system-x86_64
QEMU_MEM    ?= 4G
OVMF_CODE   ?= /usr/share/OVMF/OVMF_CODE.fd
OVMF_VARS   ?= /usr/share/OVMF/OVMF_VARS.fd

SHELL := /bin/bash

.PHONY: all iso config build clean distclean check-env test run run-uefi help

all: iso

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

# `lb build` mounts and populates a chroot: it must run as root.
iso:
	@echo "============================================================"
	@echo " $(PROJECT) $(PROJECT_VERSION) - full live-build run"
	@echo " Ubuntu $(UBUNTU_VERSION) ($(UBUNTU_CODENAME))"
	@echo " NOTE: this target requires root (lb build mounts a chroot)."
	@echo "============================================================"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "error: 'make iso' must run as root. Try: sudo make iso" >&2; \
		echo "       (the build host is not modified: no packages are" >&2; \
		echo "        installed and no host kernel is copied)." >&2; \
		exit 1; \
	fi
	@./scripts/build-iso.sh all

config:
	@echo "[config] ./auto/config (lb config)"
	@./scripts/build-iso.sh config

build:
	@echo "[build] ./auto/build (lb build)"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "error: 'make build' must run as root. Try: sudo make build" >&2; \
		exit 1; \
	fi
	@./scripts/build-iso.sh build

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------

clean:
	@echo "[clean] ./auto/clean (lb clean)"
	@if [ -x ./auto/clean ]; then \
		sudo ./auto/clean 2>/dev/null || ./auto/clean 2>/dev/null || \
			echo "  (skipped: needs root)"; \
	else \
		echo "  ./auto/clean not present, nothing to clean"; \
	fi
	@rm -f binary.hybrid.iso binary.iso

distclean: clean
	@echo "[distclean] removing $(OUTPUT_DIR)/ and the live-build cache/"
	@rm -rf "$(OUTPUT_DIR)"
	@rm -rf cache chroot config.new .build

# ---------------------------------------------------------------------------
# Environment check - diagnostic only, NEVER exits non-zero
# ---------------------------------------------------------------------------

check-env:
	@echo "============================================================"
	@echo " $(PROJECT) environment check (diagnostic only)"
	@echo "============================================================"
	@echo " expected live-build: 3.0~a57-1ubuntu54 (Ubuntu's 2012 tree)"
	@echo ""
	@for t in lb xorriso syslinux debootstrap mksquashfs sudo curl dosfstools \
	          grub-pc-bin grub-efi-amd64-bin shim-signed librsvg2-bin; do \
		if command -v $$t >/dev/null 2>&1; then \
			echo "  [OK]   $$t"; \
		elif [ -e "/usr/lib/grub/$$t" ] || [ -e "/usr/share/$$t" ]; then \
			echo "  [OK]   $$t (present, not on PATH)"; \
		else \
			echo "  [MISS] $$t"; \
		fi; \
	done
	@echo ""
	@for d in config auto scripts; do \
		if [ -d "$$d" ]; then echo "  [OK]   $$d/"; else echo "  [MISS] $$d/"; fi; \
	done
	@echo ""
	@if [ ! -e packages ] && [ -d config/package-lists ]; then \
		echo "  [OK]   package lists in config/package-lists/ (correct)"; \
	else \
		echo "  [WARN] package lists not in config/package-lists/"; \
	fi
	@echo ""
	@echo "Missing tools are reported above; this target never fails."
	@exit 0

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

# Static validation: no live-build, no ISO build, no root.
test:
	@./scripts/run-tests.sh

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

run: iso
	@echo "[run] booting $(RELEASE_ISO) in QEMU (BIOS)"
	@$(QEMU) \
		-m $(QEMU_MEM) \
		-smp $$(nproc) \
		-drive file=$(RELEASE_ISO),media=cdrom,readonly=on \
		-device virtio-net-device,netdev=net0 \
		-netdev user,id=net0 \
		-boot d \
		-display gtk,show-cursor=on || \
	$(QEMU) -m $(QEMU_MEM) -smp $$(nproc) \
		-drive file=$(RELEASE_ISO),media=cdrom,readonly=on \
		-boot d -display sdl

run-uefi: iso
	@if [ ! -f "$(OVMF_CODE)" ]; then \
		echo "OVMF firmware not found at $(OVMF_CODE)."; \
		echo "Install it with: sudo apt-get install ovmf"; \
		echo "Then re-run: make run-uefi"; \
		echo "(BIOS boot still works via: make run)"; \
		exit 0; \
	fi
	@echo "[run-uefi] booting $(RELEASE_ISO) under OVMF (UEFI)"
	@$(QEMU) \
		-m $(QEMU_MEM) \
		-smp $$(nproc) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-drive file=$(RELEASE_ISO),media=cdrom,readonly=on \
		-boot d \
		-display gtk,show-cursor=on || \
	$(QEMU) -m $(QEMU_MEM) -smp $$(nproc) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(OVMF_VARS) \
		-drive file=$(RELEASE_ISO),media=cdrom,readonly=on \
		-boot d -display sdl

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

help:
	@echo "$(PROJECT) $(PROJECT_VERSION) - Ubuntu $(UBUNTU_VERSION) ($(UBUNTU_CODENAME)) live distro"
	@echo "built with live-build 3.0~a57-1ubuntu54 (2012-era tree)."
	@echo ""
	@echo "Build:"
	@echo "  iso            clean + config + build, stage ISO in $(OUTPUT_DIR)/  (requires root)"
	@echo "  all            alias for iso"
	@echo "  config         ./auto/config only (lb config)"
	@echo "  build          ./auto/build only  (lb build, requires root)"
	@echo ""
	@echo "Maintenance:"
	@echo "  check-env      report missing build tools (never fails)"
	@echo "  test           static validation suite (no build, no root)"
	@echo "  clean          ./auto/clean + remove generated ISOs"
	@echo "  distclean      clean + remove $(OUTPUT_DIR)/ and the live-build cache"
	@echo ""
	@echo "Run:"
	@echo "  run            boot $(RELEASE_ISO) in QEMU (BIOS)"
	@echo "  run-uefi       boot the same ISO under OVMF, if firmware is present"
	@echo ""
	@echo "Traps (do not 'fix' these):"
	@echo "  - --distribution resolute is mandatory; without it live-build"
	@echo "    silently builds a 12.04 (precise) image."
	@echo "  - --syslinux-theme live-build is mandatory."
	@echo "  - This live-build has no --image-type/--hybrid-iso/--squashfs/"
	@echo "    --backports/--hostname/--timezone/--output-directory options."
	@echo "  - Output is always binary.hybrid.iso or binary.iso."
	@echo "  - UEFI also needs a hand-built boot/grub/efi.img; BIOS does not."
