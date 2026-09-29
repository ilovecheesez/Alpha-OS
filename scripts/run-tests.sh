#!/bin/bash
# Alpha OS - Test Suite

set -e

echo "========================================"
echo "Alpha OS Test Suite"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

run_test() {
    local name="$1"
    local cmd="$2"

    echo -n "  Testing $name... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))
    fi
}

echo ""
echo "Build Tests"
echo "-----------"

run_test "Makefile exists" "[ -f Makefile ]"
run_test "Live-build config exists" "[ -d live/config ]"
run_test "Packages directory exists" "[ -d packages ]"
run_test "Scripts executable" "[ -x scripts/build-iso.sh ]"

echo ""
echo "Toolchain Tests"
echo "---------------"

run_test "live-build available" "which lb"
run_test "xorriso available" "which xorriso"
run_test "mksquashfs available" "which mksquashfs"
run_test "QEMU x86_64" "which qemu-system-x86_64"
run_test "QEMU ARM64" "which qemu-system-aarch64"

echo ""
echo "ISO Tests"
echo "---------"

if [ -f "output/alpha-os-*.iso" ]; then
    run_test "ISO exists" "[ -f output/alpha-os-*.iso ]"
else
    echo -e "  ${YELLOW}ISO not yet built, skipping...${NC}"
fi

echo ""
echo "========================================"
echo "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo "========================================"

if [ $FAILED -gt 0 ]; then
    exit 1
fi