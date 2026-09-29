# Building Alpha OS

This guide is for the specific toolchain Alpha OS targets: **Ubuntu's
`live-build 3.0~a57-1ubuntu54`**, the 2012-era live-build that Ubuntu 26.04
ships. It is *not* Debian's modern live-build, and the two are not
interchangeable. Nearly every modern live-build tutorial on the web will fail
against this tree, because the tutorials assume the modern one.

> **Current tree status:** the build tree is complete — `config/`, `auto/` and
> `scripts/` are all present. No ISO has been built from it: live-build is not
> installed in this environment and a real build needs root plus a multi-GB
> debootstrap download. The tree is validated by source review and by
> `make test` (static only). See
> [Current tree status](../README.md#current-tree-status).

## Host prerequisites

A 64-bit Ubuntu or Debian host. Ubuntu 26.04 is the reference.

```bash
sudo apt update
sudo apt install -y \
    live-build \
    debootstrap \
    xorriso \
    isolinux \
    syslinux-common \
    syslinux \
    mtools \
    dosfstools \
    squashfs-tools \
    parted \
    fdisk \
    mount \
    qemu-utils \
    qemu-system-x86
```

Notes:

* **`live-build` from Ubuntu's archive is the one you want.** Do not install
  Debian's `live-build` from backports or elsewhere; `3.0~a57` and modern
  live-build have incompatible config file handling.
* `isolinux` / `syslinux` provide `isohybrid`, which the binary stage needs to
  write the hybrid boot record. Without them the ISO is produced but is not
  bootable as-is.
* `librsvg2-bin` is needed if you ever render the syslinux theme to PNG. Install
  it before blaming live-build.
* `mtools` and `dosfstools` are needed to assemble `boot/grub/efi.img` by hand
  for the UEFI step below.

Verify:

```bash
dpkg -s live-build | grep '^Version'   # expect 3.0~a57-1ubuntu54 on resolute
lb --version
which xorriso isohybrid mformat
```

## The build flow

`scripts/build-iso.sh` is a thin wrapper. It does not hand-assemble anything:

```
stage "clean"   -> ./auto/clean
stage "config"  -> ./auto/config     (runs lb config)
stage "build"   -> ./auto/build      (runs lb build, requires root)
```

Usage:

```bash
./scripts/build-iso.sh config          # lb config only
./scripts/build-iso.sh build           # lb build only  (needs root)
./scripts/build-iso.sh all             # clean, config, build (default)
./scripts/build-iso.sh all --arch amd64
./scripts/build-iso.sh all --no-clean
./scripts/build-iso.sh --help
```

Flags, exactly as `build-iso.sh` implements them:

| Flag | Meaning |
|---|---|
| `config` / `build` / `all` | Action. `all` (the default) runs `./auto/clean`, then `./auto/config`, then `./auto/build`. These three are the only accepted actions; there is no `config-only`. |
| `--arch <amd64\|arm64>` | Defaults to `$DEB_ARCH`, else `amd64`. **Only `amd64` is actually configured**: `auto/config` hard-codes `--architectures amd64`, so `--arch arm64` does not produce an arm64 image. The image is amd64-only. |
| `--variant <name>` | Alphanumeric/underscore. Exported to `./auto/config` as `LB_VARIANT`, which this live-build version does not consume, so it does not change the output. |
| `--no-clean` | Skip `./auto/clean` before configuring. |
| `-h`, `--help` | Usage. |

**`lb build` must run as root.** It debootstraps a whole system, mounts things
and runs `chroot`. It is also slow — tens of minutes to hours — and needs several
GB of free disk. There is no way to make it meaningfully incremental; if you
change the package list, re-run the full build.

### Make targets

The `Makefile` is a thin front end for the same script — it calls
`scripts/build-iso.sh`, not a separate path:

| Target | What it does |
|---|---|
| `make check-env` | Reports which build tools and directories are present. Diagnostic only; never exits non-zero. Run this first. |
| `make test` | `./scripts/run-tests.sh`: static validation. No live-build, no ISO, no root. |
| `make iso` / `make all` | `./scripts/build-iso.sh all` — `./auto/clean`, `./auto/config`, `./auto/build`. Refuses to run as non-root. |
| `make config` | `./scripts/build-iso.sh config` → `./auto/config` (`lb config`). |
| `make build` | `./scripts/build-iso.sh build` → `./auto/build` (`lb build`). Refuses to run as non-root. |
| `make clean` | `./auto/clean` (`lb clean --purge`) plus removal of `binary.hybrid.iso` / `binary.iso`. Needs root for the `lb clean` part; it is skipped with a notice otherwise. |
| `make distclean` | `clean`, then removes `output/`, `cache/`, `chroot/`, `config.new/` and `.build/`. |
| `make run` | Boots `output/alpha-os-1.0.0-YYYYMMDD.iso` in QEMU (BIOS). Depends on `make iso`. |
| `make run-uefi` | Same ISO under OVMF, if `OVMF_CODE.fd` is present; exits 0 with a message if not. |
| `make help` | Prints the target list and the traps. |

There is no `live-config`, `live-build`, `run-headless`, `clean-all` or
`clean-live` target, and no `live/` directory in this repository. Those names
belong to the older Vib-OS-era `Makefile`, which has been removed.

Note that `make run` / `make run-uefi` expect
`output/alpha-os-1.0.0-YYYYMMDD.iso` — the name written by
`scripts/create-alphaos-iso.sh`, not by `auto/build` (which names the copy for
the distribution). Run `./scripts/create-alphaos-iso.sh` if you want that exact
filename.

### The three live-build stages

live-build runs the build in three stages, in this order:

1. **bootstrap** — `debootstrap` the minimal base system into `cache/` and
   `chroot/`. Controlled by `config/bootstrap`.
2. **chroot** — install the full package set into `chroot/`, run chroot hooks,
   apply overlays, produce the squashfs. Controlled by `config/chroot` plus
   everything under `config/package-lists/`, `config/hooks/` and
   `config/includes.chroot/`.
3. **binary** — assemble the ISO, run binary hooks, apply isohybrid. Controlled
   by `config/binary`.

If a build fails, the stage name is in the last live-build line before the
error. Use it to decide which config file to look at.

## Where the ISO lands

live-build writes `binary.hybrid.iso` (or `binary.iso`) in the build root, which
here is the repository root. `auto/build` then copies it to:

```
output/alpha-os-resolute-YYYYMMDD.iso
```

The name is fixed by live-build itself; there is no `--image-name` option in
this version. `auto/build` reads `<version>` out of `config/common`
(`LB_DISTRIBUTION`, currently `resolute`) and `<date>` is `YYYYMMDD`.

To get the project-version filename instead, use the release wrapper, which runs
the same build and then stages and checksums the result:

```bash
./scripts/create-alphaos-iso.sh          # -> output/alpha-os-1.0.0-YYYYMMDD.iso
                                           #    output/SHA256SUMS
```

`make iso` and `make all` only reach `auto/build`; they do not run the release
wrapper.

## The three build traps

### Trap 1: `--mode ubuntu` silently produces Ubuntu 12.04

`--mode ubuntu` loads Ubuntu's defaults from `functions/defaults.sh`, which
hard-codes:

```sh
LB_DISTRIBUTION=precise
```

It never reads `/etc/lsb-release`. So if you configure with `--mode ubuntu` and
forget `--distribution resolute`, live-build does not error — it quietly builds a
**precise (12.04) image** from the configured mirrors, and every package pin you
wrote silently resolves against a decade-old archive. The failure surfaces much
later as a pile of "unable to locate package" messages, or not at all.

**Always pass `--distribution resolute` explicitly.** `auto/config` does.

### Trap 2: `--syslinux-theme` must be `live-build`

Ubuntu's live-build default syslinux theme is `ubuntu-oneiric`. On resolute the
packages that theme lives in — `syslinux-themes-*` and `gfxboot-theme-ubuntu` —
do not exist. live-build's `Check_package` sees the uninstallable theme and
**aborts the binary stage**.

Pass:

```sh
--syslinux-theme live-build
```

`live-build` is a theme that ships inside live-build itself and is always
available.

### Trap 3: `lb config` overwrites `config/common`

`lb config` does not merge into `config/common`. It **overwrites** it:

```sh
cat > config/common
```

Every hand edit to `config/common` or `config/binary` is destroyed by
`make config` / `./auto/config`. Do not put anything in those files expecting it
to survive a reconfigure. Put the value in `auto/config` instead, where it is
applied on every run.

`auto/config` re-applies the UEFI-related variables (`ISOHYBRID_OPTIONS` and
`GENISOIMAGE_OPTIONS_EXTRA`) *after* `lb config` runs, precisely because
`lb config` would otherwise wipe them.

## Getting a UEFI-bootable ISO

**This is not automated yet.** Say that plainly rather than discovering it on a
UEFI-only laptop.

In this live-build version there is no built-in BIOS+UEFI hybrid path; Ubuntu's
patch set does not provide one. `config/common` sets the variables that would be
*used* if the image existed:

```sh
ISOHYBRID_OPTIONS="--uefi"
GENISOIMAGE_OPTIONS_EXTRA="-eltorito-alt-boot -efi-boot boot/grub/efi.img -no-emul-boot -joliet-long"
```

(LP #1864426). The `*.binary` hook that creates `boot/grub/efi.img` — a FAT
image holding the EFI binaries and `grub.cfg` — is missing, so the ISO is
currently **BIOS-only**.

To add UEFI support:

1. Install the EFI GRUB packages: `grub-efi-amd64-bin` and `grub-efi-amd64-signed`.
2. Write a `config/hooks/NN-uefi.binary` hook that:
   * creates a FAT image of a few megabytes,
   * copies `grub/grub.cfg` (or the live-build-generated one) into it,
   * runs `grub-mkimage` to embed the `memdisk`/`iso9660` modules,
   * places the result at `boot/grub/efi.img` in the build tree.
3. Rebuild. The `GENISOIMAGE_OPTIONS_EXTRA` above will then embed it as the EFI
   system partition.

Manually, to verify a hand-assembled image before automating the hook:

```bash
dd if=/dev/zero of=efi.img bs=1M count=10
mkfs.fat efi.img
mmd -i efi.img ::/EFI ::/EFI/BOOT
mcopy -i efi.img grubx64.efi ::/EFI/BOOT/BOOTX64.EFI
mcopy -i efi.img grub.cfg ::/EFI/BOOT/grub.cfg
```

Until that hook exists, use BIOS boot, or enable CSM/Legacy in firmware.

## Adding a package

Package lists are plain text, one package per line, `#` for comments. Pick the
list that matches when the package needs to be present.

**They live in `config/package-lists/`,** named:

```
config/package-lists/00-base.list.chroot
config/package-lists/10-audio.list.chroot
config/package-lists/20-display-x11.list.chroot
config/package-lists/21-display-wayland.list.chroot
config/package-lists/30-gnome.list.chroot
config/package-lists/31-cinnamon.list.chroot
config/package-lists/32-plasma.list.chroot
config/package-lists/33-xfce.list.chroot
config/package-lists/40-live.list.chroot
config/package-lists/50-ppa.list.chroot
```

`config/package-lists/` is the only location live-build 3.0~a57 globs, and it
holds all ten lists. A previous revision kept them in a top-level `packages/`
directory; that directory has been removed and its location has not moved since.

live-build picks these up by globbing `config/package-lists/*.list*` and matching
the suffix; it does not read a variable naming them, and there is **no
`LB_PACKAGES_LIST` in this version.** The suffix decides when the list is
applied — `.list.chroot` (normal), `.list.chroot_install`, `.list.chroot_live`
(live layer only) or `.list.binary` (build host, not the image). See
[docs/ARCHITECTURE.md](ARCHITECTURE.md#package-lists).

To add a package:

1. Edit the right `*.list.chroot` file (add the package on its own line).
2. Reconfigure and rebuild:

```bash
make clean config build
```

or, through the wrapper:

```bash
./scripts/build-iso.sh all --no-clean
```

Use `--no-clean` only if you are confident the chroot is still consistent;
`make clean` is the safe default.

### Known nonexistent packages to avoid

The removed `packages/*.list.chroot` files referenced packages that do not
exist in resolute and would fail `Check_package`. The current
`config/package-lists/` files do not; do not reintroduce these:

* `libgl1-mesa-glx` — GLX moved into `libglvnd`; the package is gone.
* `libwayland-bin` — not a resolute package name.
* `weston` / `weston-launch` — reference compositor, not needed for a desktop image.
* `nautilus-3` — obsolete; `nautilus` is unversioned now.
* `gnome-devel-tools` — check before relying on it.
* `xfce4-mixer` — removed; use `xfce4-pulseaudio-plugin`.
* `pulseaudio-alsa` / `pulseaudio-utils-alsa` — removed. Use `pulseaudio-module-alsa` conventions
  or PipeWire's ALSA handling.
* `pulseaudio-jack` — the correct name is `pulseaudio-module-jack`.
* `gfxboot-theme-ubuntu`, `syslinux-themes-*` — the `ubuntu-oneiric` theme, gone.

`libgl1-mesa-glx` appeared in the removed `packages/20-display-x11.list.chroot`,
not in the current `config/package-lists/20-display-x11.list.chroot`;
`mesa-va-drivers` is now `va-driver-all`.

## Adding a chroot hook

Hooks are executables in `config/hooks/`, named `NN-description.TYPE` where
`TYPE` controls when they run:

| Suffix | Runs |
|---|---|
| `.chroot_early` | Early in the chroot stage, before the bulk of the package install |
| `.chroot` | In the chroot stage, after packages are installed, with `chroot/` as the working directory |
| `.binary` | In the binary stage, with the build root as the working directory |

Prefer `chroot_early` for anything that must exist *before* packages are
installed — pinning a version, adding a source, pre-seeding a config file. Use
plain `chroot` for post-install configuration, file creation, permissions.

The nine hooks currently in `config/hooks/`, all executable:

```
01-apt-preferences.chroot_early
05-hostname.chroot
10-branding.chroot
20-audio.chroot
30-displaymanager.chroot
40-lightdm-greeter.chroot
45-appimage-live.chroot
50-ppas.chroot
60-cleanup.chroot
```

Example, `config/hooks/10-branding.chroot`:

```sh
#!/bin/sh
set -e
cat > etc/os-release <<EOF
NAME="Alpha OS"
ID=alphaos
ID_LIKE="ubuntu debian"
VERSION_CODENAME=resolute
PRETTY_NAME="Alpha OS (Ubuntu 26.04 LTS resolute)"
EOF
```

The hook runs with `chroot/` as its root, so `etc/os-release` means
`chroot/etc/os-release`. Remember to `chmod +x` the hook; a non-executable hook
is silently skipped.

`config/hooks/` is **flat** — there is no `live/` subdirectory in this
version.

## Adding an overlay file

Anything under `config/includes.chroot/` is copied into the chroot preserving its
path relative to that directory, i.e. a file at
`config/includes.chroot/etc/skel/.alphaosrc` ends up at `/etc/skel/.alphaosrc`
in the image.

Use this for static files. Use a `.chroot` hook instead when the content depends
on the build (substitutions, permissions, conditional logic).

## Troubleshooting

**`lb: command not found`** — live-build is not installed. See
[Host prerequisites](#host-prerequisites).

**`isohybrid: not found` / "cannot create hybrid boot record"** — install
`isolinux` and `syslinux`. `xorriso` alone is not enough for `isohybrid`.

**The syslinux theme fails to build** — you are on `ubuntu-oneiric`. Pass
`--syslinux-theme live-build`. See [Trap 2](#trap-2---syslinux-theme-must-be-live-build).

**`Check_package` aborts** — a package in a list does not exist in the target
suite. Check the name against the resolute package index. The error names the
package. See the list of known-bad names above.

**Dependency conflicts during the chroot stage** — usually a desktop
metapackage. See the `Conflicts:` explanation in
[docs/DESKTOP-ENVIRONMENTS.md](DESKTOP-ENVIRONMENTS.md#why-not-the--desktop-metapackages).
Fix by listing component packages instead of metapackages.

**`kio` conflicts between KF5 and KF6** — see
[docs/DESKTOP-ENVIRONMENTS.md](DESKTOP-ENVIRONMENTS.md#kde-plasma-the-kio-oddity).

**`lb build` refuses to run** — it must run as root. `lb build` debootstraps,
mounts and chroots; there is no unprivileged mode in this version.

**`permission denied` mounting** — you are not root, or you are in a container
without `CAP_SYS_ADMIN` / loop devices. Build in a VM or on bare metal.

**The ISO builds but will not boot on UEFI** — expected. See
[Getting a UEFI-bootable ISO](#getting-a-uefi-bootable-iso).

**You get a 2012-era system** — you forgot `--distribution resolute`. See
[Trap 1](#trap-1---mode-ubuntu-silently-produces-ubuntu-1204).

**A PPA is unreachable** — expected and non-fatal. All six PPAs are fail-soft. See
the README.
