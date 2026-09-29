# Alpha OS

An Ubuntu 26.04 LTS (codename `resolute`) derivative that ships four desktop
environments — GNOME, Cinnamon, KDE Plasma and XFCE — on one live ISO, together
with a PipeWire-based audio stack and both X11 and Wayland support.

Alpha OS was formerly known as **Vib-OS**. See
[Migration history](docs/ARCHITECTURE.md#vib-os---alpha-os-migration).

> **Status: in development.** There is no release, no download page and no
> website. Nothing in this repository has produced a verified bootable ISO on
> hardware. Read [Current tree status](#current-tree-status) before you build.

The build tree is **complete**: `config/`, `auto/` and `scripts/` are all
present and `make test` (static validation) passes. What has *not* happened is
an actual ISO build — see [Current tree status](#current-tree-status).

## What Alpha OS is

* A **live image builder**, not a distribution. Alpha OS produces an ISO; it does
  not maintain its own package archive, its own kernel, or its own root
  filesystem.
* Base: **Ubuntu 26.04 LTS "resolute"**, kernel `linux-generic 7.0.0-14.14`.
* Architecture: **amd64 only.** No arm64 configuration is wired up. The old
  README claimed ARM64 (Raspberry Pi 5, Apple Silicon) — that claim was
  inherited from Vib-OS and is not true of the current build.
* Hostname `alphaos`; live user `ubuntu`; LightDM autologins the live user.
* Branding: `/etc/os-release` is rewritten to `NAME="Alpha OS"`, `ID=alphaos`,
  with `ID_LIKE="ubuntu debian"` and `VERSION_CODENAME=resolute` preserved so
  that `apt` and `dpkg` keep working normally.

## Current tree status

| Component | State |
|---|---|
| `config/` (live-build config dir: `all`, `common`, `bootstrap`, `chroot`, `binary`) | Present |
| `config/package-lists/` (10 `*.list.chroot`) | Present |
| `config/hooks/` (9 hooks) | Present |
| `config/includes.chroot/` | Present |
| `auto/config`, `auto/build`, `auto/clean` | Present, executable |
| `scripts/build-iso.sh`, `scripts/create-alphaos-iso.sh`, `scripts/run-tests.sh` | Present |
| `Makefile` | Present; targets `iso`/`all`, `config`, `build`, `clean`, `distclean`, `check-env`, `test`, `run`, `run-uefi`, `help` |
| `packages/*.list.chroot` (previous location) | Removed; `config/package-lists/` is the only list location |
| `live/` | Does not exist; the build root is the repository root |
| Vib-OS kernel, libc, bootloader, drivers, DOOM port | Removed — the migration is complete |
| `docs/` | This documentation |
| `LICENSE` | MIT |

**No ISO has been built from this tree.** `live-build` is not installed in the
environment this repository was written in, and a real build needs root plus a
multi-GB debootstrap download. The build tree is therefore validated by source
review and by the static suite only:

```bash
make test          # ./scripts/run-tests.sh - static only, no root, no build
make check-env     # reports missing build tools; never fails
```

`scripts/build-iso.sh` drives `./auto/config`, `./auto/build` and `./auto/clean`
from the repository root; the `Makefile` calls the same script, so `make iso`
and `./scripts/build-iso.sh all` are the same flow.

A previous revision of this documentation was written while the tree was
mid-migration and described the Vib-OS remnants, a `live/` directory and a
top-level `packages/` list directory as if they were still present. None of them
are.

The current package lists avoid package names that do not exist in resolute and
would fail `Check_package` — `libgl1-mesa-glx`, `weston-launch`,
`gnome-devel-tools` and similar. Do not reintroduce them as-is. See
[docs/BUILD.md](docs/BUILD.md#known-nonexistent-packages-to-avoid).

## Desktop environments

The four desktops are the same, but they are **not** equivalent. GNOME is
Wayland-only in Ubuntu 26.04; the X11 story there is a different product
entirely. This table is the accurate one.

| Desktop | X11 session | Wayland session | Notes |
|---|---|---|---|
| **GNOME 50** | None of its own. `gnome-session` ships only `wayland-sessions/gnome.desktop`. Use `gnome-session-flashback` (`xsessions/gnome-flashback-compiz.desktop`, `gnome-flashback-metacity.desktop`) for X11. | `wayland-sessions/gnome.desktop` | **Wayland-only.** `gnome-x11` / `gnome-wayland` packages do not exist in resolute. |
| **Cinnamon 6.4.13** | `xsessions/cinnamon.desktop`, `xsessions/cinnamon2d.desktop` | `wayland-sessions/cinnamon-wayland.desktop` | Wayland session is experimental upstream — treat as beta. The file is `cinnamon.desktop`, not `Xcinnamon.desktop`. |
| **KDE Plasma 6.6.4** | `xsessions/plasmax11.desktop` (via `plasma-session-x11` + `kwin-x11`) | `wayland-sessions/plasma.desktop` (via `plasma-session-wayland` + `kwin-wayland`) | **Cleanest dual stack** — both install side by side without conflict. The X11 file is `plasmax11.desktop`, not `plasma.desktop`. |
| **XFCE 4.20.4** | `xsessions/xfce.desktop` | `wayland-sessions/xfce-wayland.desktop` (native, labwc-backed) | A real native Wayland session, not XWayland. `labwc` and `wayfire` also ship standalone sessions. |

All four have Wayland. Only Cinnamon, Plasma and XFCE have a true X11 session of
their own shell. Details and the exact greeter entries are in
[docs/DESKTOP-ENVIRONMENTS.md](docs/DESKTOP-ENVIRONMENTS.md).

### Why not the `-desktop` metapackages

Alpha OS does **not** install `ubuntu-desktop`, `ubuntucinnamon-desktop`,
`kubuntu-desktop` or `xubuntu-desktop`, even though all four exist in resolute.
The reason is `ubuntu-desktop-minimal 1.570`, which declares:

```
Conflicts: kubuntu-desktop-minimal xubuntu-desktop-minimal
```

so co-installing Ubuntu flavours is unsatisfiable. Component packages are listed
explicitly instead. A useful side effect: nothing pulls in `gdm3` or `sddm`, so
**LightDM is the single display manager** for all four desktops.

## Audio

PipeWire is the real-time engine; `pipewire-pulse` speaks the PulseAudio protocol
so existing PulseAudio applications work unchanged; `wireplumber` is the session
manager.

```
apps -> libpulse -> pipewire-pulse -> PipeWire -> ALSA/JACK
```

`pulseaudio 17.0` and `pulseaudio-utils` are shipped and installed, but the
standalone `pulseaudio` daemon is **masked** so it cannot race `pipewire-pulse`.

Controls: `pavucontrol`, `pavucontrol-qt`, `wpctl`, `pactl`, `pw-cli`, `paprefs`.

See [docs/AUDIO-AND-DISPLAY.md](docs/AUDIO-AND-DISPLAY.md#audio).

## Display

* **Xorg 21.1** — the X11 compatibility layer for every desktop.
* **XWayland 24.1.10** — the X11 host for X11 applications inside Wayland sessions.
* **Wayland** — `wayland-protocols 1.47`, `libwayland 1.24.0`,
  `wayland-utils 1.3.0`, `seatd` / `libseat1`.
* **Portals** — `xdg-desktop-portal 1.21.1` with the `-gtk`, `-kde`, `-xapp` and
  `-gnome` backends. Screen sharing needs these; there is no other way on Wayland.

## PPAs

Six PPAs are added by the chroot hook and **all six fail softly**: a dead PPA is a
warning, never a build failure, and the ISO must build with zero of them
succeeding.

```
ppa:kubuntu-ppa/backports
ppa:kubuntu-ppa/ppa
ppa:ubuntu-desktop/ppa
ppa:cinnamon-team/ppa
ppa:xfce-gooders/ppa
ppa:pipewire-debian/pipewire-upstream
```

**None of these is verified to have a `resolute` suite.** The PipeWire one is a
Debian-side PPA and may have no resolute suite at all. Treat them as best-effort
only; the image must not depend on any package from them.

## Building

Full instructions: **[docs/BUILD.md](docs/BUILD.md)**.

`lb build` requires root and debootstraps an entire system, so it is slow —
expect tens of minutes to hours, and plenty of disk space. There is no
incremental fast path.

## Testing an image

Write the ISO to a USB stick and boot it, or test under QEMU:

```bash
qemu-system-x86_64 \
  -m 4G -cpu host -smp "$(nproc)" \
  -drive if=none,id=hd0,format=raw,file=output/alpha-os-1.0.0-YYYYMMDD.iso \
  -device virtio-blk-device,drive=hd0 \
  -device qemu-xhci -device usb-kbd -device usb-tablet \
  -vga virtio -display sdl \
  -audiodev pa,id=audio0 -device intel-hda -device hda-duplex,audiodev=audio0 \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
  -boot d
```

`make run` does the same thing for you. It boots
`output/alpha-os-1.0.0-YYYYMMDD.iso`, which is the name staged by
`scripts/create-alphaos-iso.sh`; `make iso` on its own leaves the ISO in the
build root as `binary.hybrid.iso` (and a copy in `output/` named for the
distribution, see [docs/BUILD.md](docs/BUILD.md#where-the-iso-lands)).

## The three build traps

These are the things most likely to waste your afternoon. Each is explained in
[docs/BUILD.md](docs/BUILD.md#the-three-build-traps).

1. **`--mode ubuntu` silently downgrades you to Ubuntu 12.04.** In
   `functions/defaults.sh` the Ubuntu patch hard-codes `LB_DISTRIBUTION=precise`
   and never reads `/etc/lsb-release`. Without an explicit
   `--distribution resolute` you get a 2012 image and **no error message**.
2. **`--syslinux-theme` must be `live-build`.** Ubuntu's default
   `ubuntu-oneiric` is uninstallable on resolute (`syslinux-themes-*` and
   `gfxboot-theme-ubuntu` are gone) and `Check_package` aborts the build.
3. **`lb config` overwrites `config/common`.** It does `cat > config/common`.
   Hand edits to `config/common` or `config/binary` are destroyed by
   `make config`; re-apply them from `auto/config` instead.

## Boot support: BIOS yes, UEFI not yet

The image is built as `binary.hybrid.iso` and is **BIOS-bootable**.

**UEFI boot is not automatic in this live-build version.** Ubuntu's own patch
set states there is no built-in BIOS+UEFI hybrid path in this tree.
`config/common` already sets:

```sh
ISOHYBRID_OPTIONS="--uefi"
GENISOIMAGE_OPTIONS_EXTRA="-eltorito-alt-boot -efi-boot boot/grub/efi.img -no-emul-boot -joliet-long"
```

(LP #1864426), which tells the ISO builder to embed `boot/grub/efi.img` as the
EFI system partition — but the `*.binary` hook that actually *produces*
`boot/grub/efi.img` does not exist yet. Until it does, a UEFI-only machine will
not boot the ISO. The concrete manual procedure is written out in
[docs/BUILD.md](docs/BUILD.md#getting-a-uefi-bootable-iso).

Also note: do **not** put `boot=casper` in `--bootappend-live`; the Ubuntu patch
rewrites it, and `casper 26.04.2` is auto-selected as the live initramfs anyway.
The installer is `ubiquity 26.04.1`, enabled with `--debian-installer live`.
Plain `--debian-installer` selects classic d-i udebs, which is the wrong flag
here.

## System requirements

Honest, and not per-desktop marketing figures. No benchmarks have been run on
this image, because no image has been built.

| Resource | Requirement |
|---|---|
| Architecture | amd64 (x86-64) |
| RAM | 2 GB minimum to reach the greeter; 4 GB or more to work in GNOME or Plasma |
| Disk | ~4–5 GB for the ISO, plus free space for a live session |
| GPU | Any with a working `linux-generic` DRM driver. Software rendering via Mesa is a fallback, not a target. |
| Network | Optional; the live session is usable offline. |

## Documentation

* [docs/BUILD.md](docs/BUILD.md) — build guide, build traps, UEFI, troubleshooting
* [docs/DESKTOP-ENVIRONMENTS.md](docs/DESKTOP-ENVIRONMENTS.md) — the four desktops, real session names, how to add another
* [docs/AUDIO-AND-DISPLAY.md](docs/AUDIO-AND-DISPLAY.md) — PipeWire architecture, Xorg/XWayland/Wayland, portals
* [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how `config/`, `auto/` and the package lists fit together

## License

MIT — see [LICENSE](LICENSE).
