#!/usr/bin/env bash
# Alpha OS ISO builder - thin wrapper around the live-build wrappers in auto/.
#
# This script deliberately does NOT hand-assemble an ISO. It does not copy the
# build host's kernel, it does not write its own grub.cfg, and it never installs
# packages on the build host. All of that is live-build's job.
#
#   stage "config" -> ./auto/config   (lb config)
#   stage "build"  -> ./auto/build    (lb build)
#
# lb build MUST run as root.

set -euo pipefail

UBUNTU_CODENAME="resolute"
PROJECT="Alpha OS"
PROJECT_VERSION="1.0.0"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

ARCH="${DEB_ARCH:-amd64}"
VARIANT=""
DO_CLEAN=1
ACTION="all"

usage() {
	cat <<EOF
Usage: $(basename "$0") [config|build|all] [options]

Actions:
  config          run ./auto/config only (lb config)
  build           run ./auto/build only  (lb build, requires root)
  all             config then build (default)

Options:
  --arch <amd64|arm64>   target architecture (default: $ARCH)
  --variant <name>       append an LB_* variant suffix, e.g. "gnome"
  --no-clean             skip ./auto/clean before configuring
  -h, --help             this help
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		config | build | all) ACTION="$1" ;;
		--arch)
			shift || true
			ARCH="${1:-}"
			;;
		--variant)
			shift || true
			VARIANT="${1:-}"
			;;
		--no-clean) DO_CLEAN=0 ;;
		-h | --help)
			usage
			exit 0
			;;
		*) echo "error: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
	esac
	shift
done

case "$ARCH" in
	amd64 | arm64) ;;
	*) echo "error: --arch must be amd64 or arm64 (got '$ARCH')" >&2; exit 2 ;;
esac

if [ -n "$VARIANT" ] && ! printf '%s' "$VARIANT" | grep -qE '^[A-Za-z0-9_]+$'; then
	echo "error: --variant must be alphanumeric/underscore (got '$VARIANT')" >&2
	exit 2
fi

LB_HELPER="lb"
[ "$ARCH" = "arm64" ] && LB_HELPER="lb"

banner() {
	echo "============================================================"
	echo " $PROJECT $PROJECT_VERSION  -  live-build ISO builder"
	echo " Ubuntu ${UBUNTU_CODENAME%%[!0-9.]*} (${UBUNTU_CODENAME})  arch=${ARCH}${VARIANT:+ variant=${VARIANT}}"
	echo " repo: $REPO_ROOT"
	echo "============================================================"
}

fail_stage() {
	local stage="$1"
	shift
	cat >&2 <<EOF

------------------------------------------------------------
FAILED during stage: $stage
------------------------------------------------------------
Likely causes, most common first:

 1. Missing --distribution resolute
    live-build 3.0~a57-1ubuntu54 is the 2012-era tree. In "ubuntu" mode it
    hard-codes the distribution to "precise". If --distribution is not passed
    explicitly you silently get a 12.04 image instead of $UBUNTU_CODENAME.
    ./auto/config must pass --distribution $UBUNTU_CODENAME.

 2. Missing --syslinux-theme live-build
    Without it live-build looks for a theme directory that does not exist and
    the binary stage aborts while building syslinux config.

 3. syslinux package not installed
    isohybrid images need the syslinux package on the build host; without it
    the hybrid boot record cannot be created.

 4. UEFI builds only
    UEFI additionally needs a hand-built boot/grub/efi.img (FAT image
    containing the EFI binaries) dropped into the build tree. BIOS builds do
    not need it.
EOF
	for line in "$@"; do
		echo "  - $line"
	done
	echo "------------------------------------------------------------"
}

require_lb() {
	if ! command -v "$LB_HELPER" >/dev/null 2>&1; then
		echo "error: live-build ($LB_HELPER) is not installed." >&2
		echo "       install it with:" >&2
		echo "         sudo apt-get install live-build" >&2
		echo "       Ubuntu 26.04 ships 3.0~a57-1ubuntu54; do NOT install" >&2
		echo "       Debian's modern live-build, it is incompatible." >&2
		exit 3
	fi
}

require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "error: 'lb build' must run as root." >&2
		echo "       re-run with: sudo $0 $ACTION" >&2
		exit 4
	fi
}

cd "$REPO_ROOT"

banner

require_lb

if [ "$DO_CLEAN" -eq 1 ]; then
	echo "[stage] clean  -> ./auto/clean"
	if [ ! -x ./auto/clean ]; then
		fail_stage "clean" "./auto/clean is missing or not executable"
		exit 5
	fi
	sudo ./auto/clean || fail_stage "clean"
fi

if [ "$ACTION" = "config" ] || [ "$ACTION" = "all" ]; then
	echo "[stage] config -> ./auto/config"
	if [ ! -x ./auto/config ]; then
		fail_stage "config" "./auto/config is missing or not executable"
		exit 5
	fi
	if [ -n "$VARIANT" ]; then
		LB_VARIANT="$VARIANT" ./auto/config || fail_stage "config"
	else
		./auto/config || fail_stage "config"
	fi
fi

if [ "$ACTION" = "build" ] || [ "$ACTION" = "all" ]; then
	require_root
	echo "[stage] build  -> ./auto/build"
	if [ ! -x ./auto/build ]; then
		fail_stage "build" "./auto/build is missing or not executable"
		exit 5
	fi
	./auto/build || fail_stage "build"
	echo "[stage] build  OK"
fi

ISO=""
for candidate in binary.hybrid.iso binary.iso; do
	if [ -f "$candidate" ]; then
		ISO="$candidate"
		break
	fi
done

if [ -z "$ISO" ]; then
	fail_stage "$ACTION" "no binary.hybrid.iso or binary.iso was produced in $REPO_ROOT"
	exit 6
fi

echo
echo "build finished: $REPO_ROOT/$ISO"
