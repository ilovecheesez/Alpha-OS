#!/usr/bin/env bash
# Alpha OS - static validation suite.
#
# This suite is STATIC. It runs with no live-build installed and builds no ISO.
# Its job is to catch the class of bug that shipped 40+ non-existent package
# names and a dead Vib-OS kernel cmdline, before anyone spends 40 minutes in a
# debootstrap chroot to find out.

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

PASSED=0
FAILED=0

echo "============================================================"
echo " Alpha OS Test Suite (static validation, no build required)"
echo " repo: $REPO_ROOT"
echo "============================================================"

pass() {
	# NOTE: PASSED=$((PASSED+1)), never ((PASSED++)) - post-increment returns
	# the pre-value, which is 1 (a failing exit status) when the counter is 0,
	# and kills the whole script under `set -e`.
	PASSED=$((PASSED + 1))
	printf '  %sPASS%s  %s\n' "$GREEN" "$NC" "$1"
}

fail() {
	FAILED=$((FAILED + 1))
	printf '  %sFAIL%s  %s\n' "$RED" "$NC" "$1"
	if [ $# -gt 1 ]; then
		shift
		printf '        %s\n' "$@"
	fi
}

check() {
	# check <description> <test-command...>
	local desc="$1"
	shift
	if "$@"; then pass "$desc"; else fail "$desc"; fi
}

expect_file() {
	if [ -f "$1" ]; then pass "file exists: $1"; else fail "file exists: $1"; fi
}

expect_exec() {
	if [ -x "$1" ]; then pass "executable: $1"; else fail "executable: $1"; fi
}

expect_grep() {
	# expect_grep <description> <pattern> <file>
	local desc="$1" pat="$2" file="$3"
	if [ ! -e "$file" ]; then
		fail "$desc" "file missing: $file"
		return
	fi
	if grep -qF -- "$pat" "$file"; then
		pass "$desc"
	else
		fail "$desc" "'$pat' not found in $file"
	fi
}

# ---------------------------------------------------------------------------
# 1. Banner / project identity
# ---------------------------------------------------------------------------
echo
echo "-- project identity"

BANNER_FILES=("$REPO_ROOT/Makefile" "$REPO_ROOT/README.md" "$REPO_ROOT/scripts/build-iso.sh")
banner_bad=()
for f in "${BANNER_FILES[@]}"; do
	[ -f "$f" ] || continue
	if ! grep -qi "Alpha OS" "$f"; then
		banner_bad+=("$f does not say 'Alpha OS'")
	fi
done
if [ ${#banner_bad[@]} -eq 0 ]; then
	pass "banner says 'Alpha OS' in Makefile/README.md/build-iso.sh"
else
	fail "banner says 'Alpha OS'" "${banner_bad[@]}"
fi

# ---------------------------------------------------------------------------
# 2. Required files
# ---------------------------------------------------------------------------
echo
echo "-- required files"

for f in config/all config/common config/bootstrap config/chroot config/binary \
	auto/config auto/build auto/clean Makefile README.md; do
	expect_file "$f"
done

# ---------------------------------------------------------------------------
# 3. config/package-lists - live-build ONLY reads config/package-lists/
#    (the old top-level packages/ dir was dead and has been removed)
# ---------------------------------------------------------------------------
echo
echo "-- config/package-lists (the only list location live-build reads)"

if [ ! -d config/package-lists ]; then
	fail "config/package-lists/ exists" "directory missing"
else
	lists=(config/package-lists/*.list.chroot)
	if [ ${#lists[@]} -eq 0 ] || [ ! -e "${lists[0]}" ]; then
		fail "config/package-lists/*.list.chroot" "no list files found"
	else
		if [ ${#lists[@]} -ge 10 ]; then
			pass "10 package lists present (${#lists[@]} found)"
		else
			fail "10 package lists present" "only ${#lists[@]} found, expected at least 10"
		fi
		for l in "${lists[@]}"; do
			expect_file "$l"
		done
	fi
fi

# ---------------------------------------------------------------------------
# 4. hooks executable
# ---------------------------------------------------------------------------
echo
echo "-- config/hooks must be executable"

if [ ! -d config/hooks ]; then
	fail "config/hooks/ exists" "directory missing"
else
	shopt -s nullglob
	hooks=(config/hooks/*.chroot*)
	shopt -u nullglob
	if [ ${#hooks[@]} -eq 0 ]; then
		fail "config/hooks/*.chroot* present" "no hooks found"
	else
		nonexec=()
		for h in "${hooks[@]}"; do
			[ -x "$h" ] || nonexec+=("$h")
		done
		if [ ${#nonexec[@]} -eq 0 ]; then
			pass "all ${#hooks[@]} hooks are executable"
		else
			fail "all config/hooks/*.chroot* are executable" "not executable: ${nonexec[*]}"
		fi
	fi
fi

# ---------------------------------------------------------------------------
# 5. config/includes.chroot non-empty
# ---------------------------------------------------------------------------
echo
echo "-- config/includes.chroot"

if [ -d config/includes.chroot ] && [ -n "$(ls -A config/includes.chroot 2>/dev/null)" ]; then
	pass "config/includes.chroot/ is non-empty"
else
	fail "config/includes.chroot/ is non-empty" "missing or empty"
fi

# ---------------------------------------------------------------------------
# 6. live-build 3.0~a57 configuration contract
# ---------------------------------------------------------------------------
echo
echo "-- live-build configuration contract"

expect_grep "config/common sets LB_DISTRIBUTION=\"resolute\"" \
	'LB_DISTRIBUTION="resolute"' config/common
expect_grep "config/binary sets LB_SYSINUX_THEME=\"live-build\"" \
	'LB_SYSINUX_THEME="live-build"' config/binary
expect_grep "config/common defines ISOHYBRID_OPTIONS" \
	'ISOHYBRID_OPTIONS' config/common
expect_grep "config/common defines GENISOIMAGE_OPTIONS_EXTRA" \
	'GENISOIMAGE_OPTIONS_EXTRA' config/common
expect_grep "auto/config passes --distribution resolute" \
	'--distribution resolute' auto/config
expect_grep "auto/config passes --syslinux-theme live-build" \
	'--syslinux-theme live-build' auto/config

# ---------------------------------------------------------------------------
# 7. THE HIGH-VALUE TEST: no known-absent resolute package names.
#    These are packages that existed in Ubuntu 14.04-16.04 or were never in
#    Ubuntu at all. Any bare package line naming one of them will make
#    debootstrap/chroot apt fail minutes into an otherwise healthy build.
# ---------------------------------------------------------------------------
echo
echo "-- package lists: no known-absent resolute package names"

ABSENT_PACKAGES="plasma-netbook
plasma-utils
plasma-widgets-default
plasma-workspace-common
plasma-vulkan
ksysguard
kde-gtk-config
kimageformats
kwebkitpart
breeze-gtk
breeze-wallpapers
yaru-theme
yaru-gtk-theme
pulseaudio-utils-alsa
pulseaudio-alsa
pulseaudio-jack
qt5-wayland
weston-launch
wayfire-session
cinnamon-spices
cinnamon-xapp
cinnamon-screen-saver
libxapp-common
xreader
xviewer
nemo-media-columns
nemo-filename-repairer
nautilus-extensions
gnome-devel-tools
gnome-accessibility
gnome-x11
gnome-wayland
mesa-va-drivers
libgl1-mesa-glx
subiquity
curtin
standard
lubuntu-core
kubuntu-desktop-minimal
ubuntu-cinnamon-desktop
network-manager-vpn
libav-tools
libreoffice-l10n-en
system-config-printer-gtk
xdg-desktop-portals
pipewire-audio-client-modules
nemo-3"

if [ ! -d config/package-lists ]; then
	fail "no absent-package names in config/package-lists" "directory missing"
else
	offenders=()
	for pkg in $ABSENT_PACKAGES; do
		# match a bare package line: optional comment marker/whitespace, the
		# package name as a whole word, optionally with a version pin.
		# Deliberately does NOT match a word merely containing the name.
		while IFS= read -r hit; do
			offenders+=("$hit  [$pkg]")
		done < <(grep -rnE "^[[:space:]]*${pkg}([[:space:]]*=|[[:space:]]|$)" config/package-lists 2>/dev/null || true)
	done
	if [ ${#offenders[@]} -eq 0 ]; then
		pass "no known-absent resolute packages referenced"
	else
		fail "no known-absent resolute packages referenced (${#offenders[@]} hit(s))" "${offenders[@]}"
	fi
fi

# ---------------------------------------------------------------------------
# 8. No dead Vib-OS / UnixOS / custom-bootloader references anywhere
# ---------------------------------------------------------------------------
echo
echo "-- no dead Vib-OS / UnixOS / Multiboot2 / Limine references"

DEAD_REFS="vib-os vibos unornos unixos unixos.elf unixOS multiboot2 limine"
dead_hits=()
# Scope: the live-build build entrypoints only. README.md and docs/ narrate the
# Vib-OS -> Alpha OS migration and legitimately name the old project, and the
# legacy vib-os-x86_64/ and limine* trees are outside this build system.
scan_paths=()
for p in Makefile scripts/build-iso.sh scripts/create-alphaos-iso.sh auto config; do
	[ -e "$p" ] && scan_paths+=("$p")
done
for ref in $DEAD_REFS; do
	while IFS= read -r hit; do
		dead_hits+=("$hit  [$ref]")
	done < <(grep -rniI --exclude-dir=.git --exclude-dir=output -e "$ref" "${scan_paths[@]}" 2>/dev/null || true)
done
if [ ${#dead_hits[@]} -eq 0 ]; then
	pass "no dead OS / bootloader references in the build entrypoints"
else
	fail "no dead OS / bootloader references in the build entrypoints (${#dead_hits[@]} hit(s))" "${dead_hits[@]}"
fi

# ---------------------------------------------------------------------------
# 9. bash -n on every shell file we own or ship
# ---------------------------------------------------------------------------
echo
echo "-- shell syntax (bash -n)"

syntax_bad=()
syntax_n=0
syntax_files=()
for f in "$REPO_ROOT"/auto/* "$REPO_ROOT"/scripts/*.sh "$REPO_ROOT"/config/hooks/*.chroot*; do
	[ -f "$f" ] || continue
	case "$(basename "$f")" in
	*.py | *.md) continue ;;
	esac
	syntax_files+=("${f#"$REPO_ROOT"/}")
	syntax_n=$((syntax_n + 1))
	if ! bash -n "$f" 2>/dev/null; then
		syntax_bad+=("${f#"$REPO_ROOT"/}")
	fi
done
if [ ${#syntax_files[@]} -eq 0 ]; then
	fail "bash -n on shell files" "no shell files found"
elif [ ${#syntax_bad[@]} -eq 0 ]; then
	pass "bash -n on all ${syntax_n} shell files"
else
	fail "bash -n on all ${syntax_n} shell files" "syntax errors in: ${syntax_bad[*]}"
fi

# ---------------------------------------------------------------------------
# 10. Tool versions - INFO ONLY. A missing tool is never a failure here.
# ---------------------------------------------------------------------------
echo
echo "-- tool versions (informational only, never fails)"

if command -v lb >/dev/null 2>&1; then
	echo "  ${YELLOW}INFO${NC}  $(lb --version 2>&1 | head -1)"
else
	echo "  ${YELLOW}INFO${NC}  lb not installed (expected; static suite needs none)"
fi
for t in xorriso mksquashfs debootstrap qemu-system-x86_64; do
	if command -v "$t" >/dev/null 2>&1; then
		printf '  %s  %s\n' "${YELLOW}INFO${NC}" "$t: $(command -v "$t")"
	else
		printf '  %s  %s\n' "${YELLOW}INFO${NC}" "$t: not installed"
	fi
done

# ---------------------------------------------------------------------------
echo
echo "============================================================"
echo " passed: $PASSED   failed: $FAILED"
echo "============================================================"

[ "$FAILED" -eq 0 ] || exit 1
echo "Alpha OS static validation: OK"
exit 0
