# Desktop Environments

Alpha OS ships four desktop environments: **GNOME 50**, **Cinnamon 6.4.13**,
**KDE Plasma 6.6.4** and **XFCE 4.20.4**. All four are selected at the LightDM
greeter.

The important thing to understand before reading further: **the four are not
equivalent**. Three of them have both a native X11 session and a native Wayland
session. GNOME has a Wayland session and an X11 experience that is a completely
different product (Flashback). The table below is derived from the archive's
`Contents-amd64.gz` and is the accurate one — the per-DE "X11 + Wayland" claims
in older versions of this documentation were wrong.

## Session availability at a glance

| Desktop | X11 session | Wayland session |
|---|---|---|
| GNOME 50 | Flashback only | Native |
| Cinnamon 6.4.13 | Native | Native (experimental) |
| Plasma 6.6.4 | Native | Native |
| XFCE 4.20.4 | Native | Native (labwc-backed) |

All four have Wayland. Only Cinnamon, Plasma and XFCE have a true X11 session of
their own shell.

## Choosing a session

LightDM shows one entry per session file, using the desktop file's `Name=`
value. To see what is actually available, from a terminal:

```bash
ls /usr/share/xsessions/          # X11 sessions
ls /usr/share/wayland-sessions/   # Wayland sessions
```

At the greeter, use the session selector (the gear icon or the session name
field, depending on the greeter theme) to pick among them. The list you see is
the union of those two directories, plus standalone compositors.

## GNOME 50

**Wayland-only.** This is the single most surprising fact about Alpha OS, and it
is not a packaging choice — it is how Ubuntu 26.04 ships GNOME.

* `gnome-session` provides **only** `wayland-sessions/gnome.desktop`. There is
  **no** `xsessions/gnome.desktop`.
* The `gnome-x11` and `gnome-wayland` packages **do not exist** in resolute. Do
  not go looking for them and do not try to `apt install` them.

### X11 on GNOME means Flashback

If you want GNOME on X11, you get **GNOME Flashback**, which is a different
desktop shell. `gnome-session-flashback` is included in the image and provides:

| Session file | Compositor |
|---|---|
| `xsessions/gnome-flashback-compiz.desktop` | Compiz |
| `xsessions/gnome-flashback-metacity.desktop` | Metacity |

Flashback deliberately imitates an older, traditional GNOME layout. It is not
GNOME 50 running on Xorg — it is GNOME 50's session plumbing driving a
different shell. Choose it if you want the classic GNOME feel; do not choose it
expecting modern GNOME.

### Caveats

* Modern GTK4/libadwaita applications on GNOME Wayland generally behave best;
  XWayland coverage is complete but rendering is not identical.
* The Wayland session is the default and the well-tested path.

## Cinnamon 6.4.13

| Session file | Notes |
|---|---|
| `xsessions/cinnamon.desktop` | Standard X11 Cinnamon session |
| `xsessions/cinnamon2d.desktop` | 2D rendering, no OpenGL; for very weak GPUs or broken drivers |
| `wayland-sessions/cinnamon-wayland.desktop` | Experimental upstream — treat as **beta** |

The session file is **`cinnamon.desktop`**, not `Xcinnamon.desktop`. If you were
looking for `Xcinnamon.desktop`, it does not exist in this image.

Cinnamon's Wayland session is the least mature of the four. Use `cinnamon2d` if
your GPU struggles, and prefer the X11 session for day-to-day work unless you
specifically want to test the Wayland path.

## KDE Plasma 6.6.4

The cleanest dual stack in the image. Both sessions install side by side without
any packaging conflict.

| Session file | Requires |
|---|---|
| `xsessions/plasmax11.desktop` | `plasma-session-x11`, `kwin-x11` |
| `wayland-sessions/plasma.desktop` | `plasma-session-wayland`, `kwin-wayland` |

Note the X11 file is **`plasmax11.desktop`**, not `plasma.desktop` — the
Wayland session owns the unqualified `plasma.desktop` name. If you were told to
look for `xsessions/plasma.desktop`, that file is not there.

If you are choosing one desktop to work in day to day, this is the one with the
least compromise on either display server.

### KDE Plasma: the `kio` oddity

Resolute carries **`kio 5.116.0`** (KF5) alongside the KF6 versions of `dolphin`
and `kate` (25.12.3). Mixed KF5/KF6 file-manager and editor components can
conflict during dependency resolution.

Symptoms: apt refuses to install/remove a Plasma component, or
`dolphin`/`kate` fail to start with plugin errors after a partial upgrade.

This is an upstream packaging state of the resolute archive, not something
Alpha OS configures. If you hit it, avoid upgrading the KDE stack piecemeal and
let apt resolve `dolphin`, `kate` and `kio` together in a single transaction.

## XFCE 4.20.4

| Session file | Notes |
|---|---|
| `xsessions/xfce.desktop` | Classic X11 session, xfwm4 |
| `wayland-sessions/xfce-wayland.desktop` | **Native** Wayland session, backed by `labwc` |

XFCE 4.20's Wayland session is a real native session, not XWayland with a Wayland
window manager. `labwc` and `wayfire` also ship standalone sessions, so they may
appear in the greeter list as their own entries.

XFCE is the lightest of the four and the most usable on modest hardware. Note
that `xfce4-mixer` no longer exists; the volume control is
`xfce4-pulseaudio-plugin`.

## Display manager

**LightDM is the single display manager** for all four desktops. Neither `gdm3`
nor `sddm` is installed, and nothing in the image pulls them in — see below for
why that is a good thing.

LightDM autologins the live `ubuntu` user, so the greeter is normally skipped on
first boot. To get a greeter and pick a session by hand, log out or reboot.

## Why not the `-desktop` metapackages

Alpha OS does not install `ubuntu-desktop`, `ubuntucinnamon-desktop`,
`kubuntu-desktop` or `xubuntu-desktop`, even though **all four exist** in
resolute.

The blocker is `ubuntu-desktop-minimal 1.570`, which declares:

```
Conflicts: kubuntu-desktop-minimal xubuntu-desktop-minimal
```

Because metapackages pull in the corresponding `*-desktop-minimal`, installing
two Ubuntu flavours at once is literally unsatisfiable — apt cannot resolve it,
so the ISO would not build. Listing the component packages explicitly sidesteps
the conflict entirely.

A useful side effect of that choice: nothing drags in `gdm3` (which GNOME would
want) or `sddm` (which Plasma would want). One display manager — LightDM — serves
every desktop, and every session is reachable from one greeter. That is why
there is no per-DE display manager to choose at the greeter.

## Adding a desktop that is not included

The image is amd64-only and ships exactly these four. To add a fifth:

1. Create a new package list, e.g.
   `config/package-lists/34-<de>.list.chroot`. See
   [docs/BUILD.md](BUILD.md#adding-a-package).
2. List the DE's **component** packages, not its metapackage, for the reason
   above. Including a `*-desktop` metapackage will reintroduce the
   `Conflicts:` problem.
3. Make sure the DE has a session in `/usr/share/xsessions/` or
   `/usr/share/wayland-sessions/`, and that LightDM can see it.
4. Install the matching desktop portal backend if the DE ships one, so
   screen sharing and file choosers work on Wayland.
5. Rebuild:

   ```bash
   make clean config build
   ```

6. Verify the session appears:

   ```bash
   ls /usr/share/wayland-sessions/ /usr/share/xsessions/
   ```

Adding an ARM64 desktop is not a package-list change — the image is amd64-only.

## See also

* [docs/AUDIO-AND-DISPLAY.md](AUDIO-AND-DISPLAY.md) — display servers, portals,
  compositor mapping
* [docs/BUILD.md](BUILD.md) — build traps, package lists, hooks
