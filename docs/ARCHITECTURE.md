# Architecture

How Alpha OS is put together, what each file controls, and where the pieces
live.

> **Reality check.** The `config/` and `auto/` directories described below are
> the actual layout, and they are what `scripts/build-iso.sh` invokes. Both are
> present and complete. The build root is the repository root; there is no
> `live/` directory and no separate `live/config` argument file.

## The `config/` + `auto/` split

The whole design is one idea: **separate declarative configuration from
imperative actions.**

* **`config/` is state.** Plain files that `lb config` reads and writes. It
  describes *what* the image is. It is declarative data.
* **`auto/` is behaviour.** Executable scripts that run `lb config`, `lb build`
  and `lb clean`. It describes *how* the image gets built. It is imperative.

This split exists because of a specific failure mode. `lb config` **overwrites**
`config/common` with `cat > config/common`. Anything you hand-write in
`config/common` is destroyed the next time anyone runs a configure step. So
`auto/config` re-applies every value that must survive *after* `lb config` has
run — most importantly the UEFI variables. `config/` can be regenerated at any
time; `auto/` is the source of truth.

## Config sourcing order

live-build reads these files in this order, each one able to override the last:

```
config/all
  -> config/common
    -> config/bootstrap
      -> config/chroot
        -> config/binary
          -> config/source
```

| File | Controls |
|---|---|
| `config/all` | Applied to every stage. Global settings: distribution, architectures, mirrors, hostname, locale. |
| `config/common` | Everything not stage-specific. Overrides `all`. |
| `config/bootstrap` | The `debootstrap` stage — the minimal base system. Mirror, suite, components. |
| `config/chroot` | The chroot stage — the actual package set installed into the image. |
| `config/binary` | The binary stage — ISO assembly, bootloader, isohybrid, ISO contents. |
| `config/source` | Extra source trees to copy in, applied last. Not used by Alpha OS — the directory does not exist. |

The Alpha OS values that matter and where they belong:

| Setting | Value | File |
|---|---|---|
| Distribution | `resolute` | `config/all` — **must be explicit**, see trap 1 |
| Architectures | `amd64` | `config/all` |
| Hostname | `alphaos` | `config/chroot` |
| Linux flavour | `generic` | `config/common` |
| Live user | `ubuntu` | `config/chroot` |
| Initramfs | `casper` (auto-selected) | do **not** set `boot=casper` in `--bootappend-live` |
| Installer | `ubiquity` via `--debian-installer live` | `config/common` |
| Syslinux theme | `live-build` | `config/binary` — see trap 2 |
| `ISOHYBRID_OPTIONS` | `--uefi` | `config/common`, re-applied by `auto/config` |
| `GENISOIMAGE_OPTIONS_EXTRA` | EL Torito alt boot for `boot/grub/efi.img` | `config/common`, re-applied by `auto/config` |

### The `config/source` tree

`config/source/` mirrors the target filesystem and is copied in late, after the
chroot stage. It is the older alternative to `config/includes.chroot/`. Prefer
`includes.chroot` for new work. Alpha OS does not use it; the directory does not
exist.

## Package lists

live-build glob-selects package lists by filename suffix. The suffix decides
*when* the list is installed.

| Suffix | When |
|---|---|
| `.list.chroot` | During the chroot stage, with the rest of the package set. This is the normal case. |
| `.list.chroot_install` | Installed in the chroot, then the list is removed from the build. |
| `.list.chroot_live` | Installed into the live layer only — present when running live, absent from a persistent install. |
| `.list.binary` | Packages installed on the **build host** for the binary stage, e.g. ISO tooling. Not part of the image. |

**live-build globs `config/package-lists/*.list*`.** The positional order does
not matter and the file is matched by suffix, not by name.

**There is no `LB_PACKAGES_LIST` variable in this version of live-build.** That
is worth internalising, because it is the reason nothing in the tree names the
list files. In modern live-build you must point a config file at your lists
explicitly; here you do not, and any such reference in a config file would be
simply ignored. Files in the directory are picked up because of where they are,
not because something asks for them.

### Where they are

They are in `config/package-lists/`, and that is the only location live-build
3.0~a57 globs. All ten lists are present:

```
00-base.list.chroot            30-gnome.list.chroot
10-audio.list.chroot           31-cinnamon.list.chroot
20-display-x11.list.chroot     32-plasma.list.chroot
21-display-wayland.list.chroot 33-xfce.list.chroot
40-live.list.chroot            50-ppa.list.chroot
```

A previous revision kept these in a top-level `packages/` directory. That
directory has been removed, and the location has not moved since.

The numeric prefixes document intent and keep `ls` output readable; live-build
does not care about them.

There is no `live/config` argument file and no `live/` directory in this
repository. `auto/config` passes its `lb config` arguments directly, including
`--architectures amd64`; the build is amd64-only and there is no ARM64
configuration.

## Hooks

`config/hooks/` holds executables run at named points in the build. The filename
is `NN-description.TYPE`; the numeric prefix sets ordering, and the suffix sets
timing.

| Suffix | Stage | Working directory |
|---|---|---|
| `.chroot_early` | Chroot, before the bulk package install | `chroot/` |
| `.chroot` | Chroot, after packages are installed | `chroot/` |
| `.binary` | Binary (ISO assembly) | build root |

Because the working directory is the chroot, paths in a `.chroot` hook are
relative to the image root: `etc/os-release` means `/etc/os-release` in the built
system. A hook must be **executable** or it is silently skipped.

`config/hooks/` is **flat**. There is no `live/` subdirectory in this version —
`config/hooks/live/foo.chroot` would not run.

The nine hooks in the tree are `01-apt-preferences.chroot_early`,
`05-hostname.chroot`, `10-branding.chroot`, `20-audio.chroot`,
`30-displaymanager.chroot`, `40-lightdm-greeter.chroot`,
`45-appimage-live.chroot`, `50-ppas.chroot` and `60-cleanup.chroot`.

The branding rewrite that turns `/etc/os-release` into `NAME="Alpha OS"`,
`ID=alphaos`, `ID_LIKE="ubuntu debian"` with `VERSION_CODENAME=resolute`
preserved, and the LightDM autologin of the live `ubuntu` user, are both
`.chroot` hook work. The PPA setup is a `.chroot_early` hook, because adding
sources must happen before package resolution.

### PPAs fail softly

All six PPAs are added through a chroot hook that is written to treat failure as
a warning:

```
ppa:kubuntu-ppa/backports
ppa:kubuntu-ppa/ppa
ppa:ubuntu-desktop/ppa
ppa:cinnamon-team/ppa
ppa:xfce-gooders/ppa
ppa:pipewire-debian/pipewire-upstream
```

None is verified to have a resolute suite; the PipeWire one is a Debian-side
PPA and may not have one at all. The image must therefore build with **zero** of
them succeeding, and no package may be required from any of them.

## Overlays: `config/includes.chroot/`

Everything under `config/includes.chroot/` is copied into the chroot, preserving
the path relative to that directory:

```
config/includes.chroot/etc/skel/.alphaosrc   ->   /etc/skel/.alphaosrc
```

Use overlays for **static files** that need no logic. Use a `.chroot` hook when
the content depends on the build — substitutions, permissions, conditionals,
anything that has to run a command.

## The three build stages

live-build is a three-stage pipeline. Knowing which stage failed tells you which
config file to open.

### 1. bootstrap

`debootstrap` the minimal base system from the bootstrap mirror. Produces
`cache/` and the initial `chroot/`. Controlled by `config/bootstrap`.

This is the slow, network-bound part. It is also the part that silently produces
the wrong distribution if `--distribution resolute` is not passed explicitly —
`--mode ubuntu` hard-codes `precise`.

### 2. chroot

Install the full package set into the chroot, run chroot hooks, apply
`config/includes.chroot/`, squash the result. Controlled by `config/chroot` plus
`config/package-lists/`, `config/hooks/` and `config/includes.chroot/`.

This is where dependency resolution happens and therefore where the metapackage
`Conflicts:` problem bites, and where non-existent package names fail
`Check_package`.

### 3. binary

Assemble the ISO from the squashfs and the bootloader, run `.binary` hooks, apply
isohybrid. Controlled by `config/binary`.

`isohybrid` runs here, which is why the `isolinux`/`syslinux` packages must be on
the **build host**. This is also the stage where the missing `boot/grub/efi.img`
hook matters: the variables are set, but nothing creates the file, so the result
is BIOS-only. See
[docs/BUILD.md](BUILD.md#getting-a-uefi-bootable-iso).

## `auto/` scripts

| Script | Does |
|---|---|
| `auto/config` | Runs `lb config` with the full argument set, then re-applies the UEFI variables that `lb config` overwrote. |
| `auto/build` | Runs `lb build` as root, then copies `binary.hybrid.iso` (or `binary.iso`) to `output/alpha-os-resolute-<date>.iso`. |
| `auto/clean` | Removes the live-build working state (`lb clean --purge`, plus `cache/`, `.build/`, `chroot/`, `binary`, `*.iso`). It never touches `config/` or `auto/`. |

`auto/build` is what stages and renames the ISO. `live-build` itself only ever
produces `binary.hybrid.iso` in the build root; the friendly
`output/alpha-os-*.iso` name is entirely Alpha OS's doing.

`lb build` requires root. There is no unprivileged mode in this version.

## Vib-OS -> Alpha OS migration

Alpha OS is the renamed and converted former **Vib-OS**.

Vib-OS was a from-scratch hobby operating system: its own kernel, its own C
library, its own bootloader, its own set of device drivers, its own userspace,
and a DOOM port. That tree was removed in the conversion: 601 tracked files
went, covering the old `kernel/`, `libc/`, `boot/`, `drivers/`, `runtimes/`,
`user/`, `vendor/`, `userspace/`, `vib-os-x86_64/`, `examples/`, `grub/` and
`screenshots/` directories, plus `doom1.wad`, `limine.conf`,
`Makefile.multiarch`, `BUILD_LINUX.md` and 8 legacy scripts. **The deletion is
complete.** None of those paths exists in the repository. What replaced it is
not a port of that code into a new shape — it is a complete replacement by
upstream:

| Vib-OS | Alpha OS |
|---|---|
| Custom kernel | Ubuntu `linux-generic` 7.0.0-14.14 |
| Custom libc | Ubuntu 26.04 userland (glibc) |
| Custom bootloader (multiboot2) | live-build + syslinux/ISOHYBRID; GRUB for UEFI once the `efi.img` hook exists |
| Custom drivers (`drivers/`) | Upstream DRM, network, storage and input drivers in `linux-generic` |
| DOOM port | Removed. Not present in the image. |
| Hand-assembled ISO | live-build three-stage pipeline |

There is no Vib-OS residue left. The earlier `Makefile.multiarch` and
`BUILD_LINUX.md` that described a Vib-OS kernel build (`make kernel`, clang/LLVM,
ARM64 bare metal) were removed with it; `make kernel` no longer exists. To build
Alpha OS, use [docs/BUILD.md](BUILD.md) and `scripts/build-iso.sh`.

### Branding, and why the codename survives

`/etc/os-release` is rewritten to:

```
NAME="Alpha OS"
ID=alphaos
ID_LIKE="ubuntu debian"
VERSION_CODENAME=resolute
```

`VERSION_CODENAME=resolute` and `ID_LIKE="ubuntu debian"` are preserved
deliberately. Ubuntu's apt, dpkg, and a great deal of installed software branch
on the codename and on `ID_LIKE` to decide where to look for repositories and
what to assume about paths. Overwriting them would break `apt update` and
`apt install` in ways that are tedious to diagnose. Changing the *name* while
keeping the *codename* gives Alpha OS its identity without forking apt.

LightDM autologins the live `ubuntu` user, so a booted image lands on a desktop
without prompting.

## See also

* [docs/BUILD.md](BUILD.md) — the practical build guide
* [docs/DESKTOP-ENVIRONMENTS.md](DESKTOP-ENVIRONMENTS.md) — the four desktops
* [docs/AUDIO-AND-DISPLAY.md](AUDIO-AND-DISPLAY.md) — PipeWire and display stack
