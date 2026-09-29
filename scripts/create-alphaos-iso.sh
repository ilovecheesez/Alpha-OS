#!/usr/bin/env bash
# Alpha OS - create the release ISO and stage it in output/.
#
# This is a thin alias over scripts/build-iso.sh. There is no hand-rolled ISO
# assembly here: no legacy bootloader stub, no hand-written grub.cfg, no host
# kernel copy.
# live-build (via auto/config + auto/build) produces binary.hybrid.iso or
# binary.iso, and this script only names, checksums and reports it.
#
# The legacy custom bootloader and dead OS codenames that used to appear here
# are gone; see scripts/run-tests.sh, which fails the build if they come back.

set -euo pipefail

PROJECT="Alpha OS"
PROJECT_VERSION="1.0.0"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SH="$REPO_ROOT/scripts/build-iso.sh"
OUTPUT_DIR="$REPO_ROOT/output"

TODAY="$(date +%Y%m%d)"
RELEASE_NAME="alpha-os-${PROJECT_VERSION}-${TODAY}"
RELEASE_ISO="${OUTPUT_DIR}/${RELEASE_NAME}.iso"

cd "$REPO_ROOT"

if [ ! -x "$BUILD_SH" ]; then
	echo "error: $BUILD_SH is missing or not executable" >&2
	exit 1
fi

echo "============================================================"
echo " $PROJECT $PROJECT_VERSION - release ISO"
echo " target: $RELEASE_NAME.iso"
echo "============================================================"

"$BUILD_SH" all "$@"

SRC=""
for candidate in binary.hybrid.iso binary.iso; do
	if [ -f "$REPO_ROOT/$candidate" ]; then
		SRC="$REPO_ROOT/$candidate"
		break
	fi
done

if [ -z "$SRC" ]; then
	echo "error: live-build produced no binary.hybrid.iso or binary.iso" >&2
	exit 1
fi

mkdir -p "$OUTPUT_DIR"
cp -f "$SRC" "$RELEASE_ISO"

echo
echo "------------------------------------------------------------"
echo "ISO:    $RELEASE_ISO"
echo "Size:   $(du -h "$RELEASE_ISO" | cut -f1) ($(stat -c %s "$RELEASE_ISO") bytes)"

(cd "$OUTPUT_DIR" && sha256sum "${RELEASE_NAME}.iso" >SHA256SUMS)
echo "SHA256: $(cut -d' ' -f1 <"$OUTPUT_DIR/SHA256SUMS")"
echo "Sum file: $OUTPUT_DIR/SHA256SUMS"
echo
echo "Write to a USB stick (replace /dev/sdX with your device):"
echo "  sudo dd if=$RELEASE_ISO of=/dev/sdX bs=4M status=progress conv=fsync"
echo
echo "Test it in QEMU (BIOS):"
echo "  make run"
echo "  # or: qemu-system-x86_64 -m 4G -smp 2 -enable-kvm \\"
echo "  #      -drive file=$RELEASE_ISO,media=cdrom,readonly=on -boot d"
echo "------------------------------------------------------------"
