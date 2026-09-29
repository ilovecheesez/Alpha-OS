# Audio and Display

Two subsystems with one thing in common: both are built around the idea that the
old default is no longer the right default, and compatibility is provided by a
translation layer rather than by keeping the old thing around.

# Audio

## The architecture

```
apps -> libpulse -> pipewire-pulse -> PipeWire -> ALSA/JACK
```

Read that left to right as "an application that only knows PulseAudio talks to
`libpulse`, which is a client of the `pipewire-pulse` protocol server, which is
a PipeWire client graph that terminates on the real ALSA and JACK backends."

**PipeWire is the engine.** Everything is a PipeWire graph node, which is what
gives you low-latency, graph-based routing and sample-accurate timing.

**PulseAudio is a compatibility shim, not a competing server.**
`pipewire-pulse` implements the PulseAudio protocol on top of PipeWire. Every
existing PulseAudio application keeps working unchanged. Nothing is ported.

**WirePlumber is the session manager.** PipeWire deliberately has no policy
logic of its own — deciding which device is the default sink, how to switch
profiles, where to route a stream is WirePlumber's job.

## Packages and what each one is for

| Package | Role |
|---|---|
| `pipewire` 1.6.2 | The real-time engine. Required; nothing works without it. |
| `pipewire-pulse` | Implements the PulseAudio protocol over PipeWire. This is the compatibility layer. |
| `wireplumber` 0.5.13 | Session manager. Policy: default devices, routing, profile switching. |
| `pulseaudio` 17.0 | **Installed, but the daemon is masked.** See below. |
| `pulseaudio-utils` | Installed. Provides `pactl` and friends. |
| `pulseaudio-module-jack` | The JACK sink/source module. Note the name: `pulseaudio-module-jack`, **not** `pulseaudio-jack`. |
| `pipewire-alsa`, `pipewire-jack` | ALSA and JACK backends for PipeWire. |
| `bluez`, `blueman` | Bluetooth audio. |

### Package names that no longer exist

Getting these wrong is common when copying from older guides:

* `pulseaudio-jack` — wrong. It is `pulseaudio-module-jack`.
* `pulseaudio-alsa` / `pulseaudio-utils-alsa` — these packages no longer exist.
  ALSA handling goes through PipeWire.
* `xfce4-mixer` — removed from XFCE. The replacement is
  `xfce4-pulseaudio-plugin`.

## Why the standalone `pulseaudio` daemon is masked

`pulseaudio` and `pulseaudio-utils` are both shipped and installed. The
`pulseaudio` package's daemon unit is **masked** anyway.

The reason is a race, not a policy decision. Both `pulseaudio.service` and
`pipewire-pulse.service` try to own the same Unix socket. If the real PulseAudio
daemon starts, it grabs the socket and you end up with:

* a PulseAudio server that PipeWire clients cannot reach, and
* PipeWire clients that silently fail, or
* whichever daemon started second failing to bind.

Masking the unit makes it impossible for the standalone daemon to start. You
still get the `pulseaudio` **command-line tools** and the library, because those
come from `pulseaudio-utils` and `libpulse`, not from the daemon. The result is
that `pactl` and PulseAudio applications work perfectly, talking to PipeWire.

The mental model to keep: `pipewire-pulse` is the server, `pulseaudio` the
client library. The upstream daemon is dead weight that is present only for
compatibility, and it is masked so it stays out of the way.

## Controls

| Tool | Use it for |
|---|---|
| `pavucontrol` | The GTK mixer. Output device, input device, per-application volume, configuration. The default answer. |
| `pavucontrol-qt` | The Qt mixer, integrates better with Plasma. |
| `wpctl` | PipeWire/WirePlumber control. `wpctl status` is the best first diagnostic. |
| `pactl` | PulseAudio CLI. Works because of `pipewire-pulse`. |
| `pw-cli` | Low-level PipeWire object inspection. |
| `paprefs` | Policy/preference editor for the PulseAudio-compat layer. |

## Verifying the stack

```bash
# Overall state: which daemon, which devices, which streams
wpctl status

# Confirm you are talking to the PipeWire-backed PulseAudio server
pactl info

# Low-level: enumerate PipeWire objects and their state
pw-cli list-Objects
```

`pactl info` should report a PipeWire-backed server. If it reports a
PulseAudio-style server with independent scheduling, something has overridden the
mask and you are running the wrong daemon.

Graphically: run `pavucontrol` (or `pavucontrol-qt` under Plasma).

## Troubleshooting

**No sound at all**

1. `wpctl status` — is PipeWire running? Is the sink there but `SUSPENDED`?
2. `pactl info` — is `pipewire-pulse` up?
3. Check the user is in the audio groups. A live user typically needs `audio`,
   `video`, `plugdev`, `render` and `pipewire`:

   ```bash
   groups
   sudo usermod -aG audio,video,plugdev,render,pipewire ubuntu
   ```

   Log out and back in — group changes do not apply to a running session.
4. Confirm ALSA sees the hardware independently: `aplay -l`. If ALSA does not
   see it, the problem is the driver, not PipeWire.

**Fallback when the PipeWire stack is broken**

Force a client straight to ALSA and bypass the daemon graph entirely:

```bash
apulse some-application
```

`apulse` sets `PULSE_SERVER` to the ALSA plugin. It is a diagnostic, not a
configuration — it works for clients but gives up WirePlumber's routing.

**Bluetooth audio**

Bluetooth is handled by `blueman`, and the audio path is BlueZ -> PipeWire.

```bash
blueman-manager
```

If a Bluetooth headset appears but sound does not come out of it, the headset is
probably not set as the PipeWire default sink — check in `pavucontrol` or
`wpctl status`.

**An application has no sound in a specific desktop**

Almost always a PulseAudio module missing, or a per-application stream routed to
the wrong sink. `pavucontrol` shows per-application volume and output routing;
that is usually enough.

# Display

## Xorg, XWayland and Wayland

| Component | Version | Role |
|---|---|---|
| Xorg | 21.1 | The X11 display server. X11 session for every desktop. |
| XWayland | 24.1.10 | An X server embedded in a Wayland session. Hosts X11 applications. |
| `wayland-protocols` | 1.47 | The protocol extensions. |
| `libwayland` | 1.24.0 | The client library. |
| `wayland-utils` | 1.3.0 | `wayland-info`, `weston-info`-style tooling. |
| `seatd` / `libseat1` | — | Logind seat management, gives compositors device access. |

The distinction that matters: **XWayland is not a fallback display server.** In a
Wayland session the Wayland compositor is the display server; XWayland is a
compatibility shim inside it, exactly like `pipewire-pulse` is for audio. An X11
application in a Wayland session is a guest.

That is why all four desktops can offer a Wayland session: X11 applications keep
working through XWayland regardless of the shell.

## Package names that changed

* `libgl1-mesa-glx` **no longer exists.** GLX moved into the `libglvnd`
  dispatch library; you get GLX from the libglvnd packages instead. The old
  `packages/20-display-x11.list.chroot` listed it; the current
  `config/package-lists/20-display-x11.list.chroot` does not.
* `mesa-va-drivers` is now `va-driver-all`.
* `libwayland-bin` is not a resolute package name; the old
  `packages/21-display-wayland.list.chroot` listed it, the current
  `config/package-lists/21-display-wayland.list.chroot` does not.

## The portal stack

```
xdg-desktop-portal 1.21.1
  + xdg-desktop-portal-gtk
  + xdg-desktop-portal-kde
  + xdg-desktop-portal-xapp
  + xdg-desktop-portal-gnome
```

Portals are the sanctioned way for a sandboxed application to ask the desktop
for something privileged: screen sharing, screen capture, a file chooser, a
secret, a notification, opening a URI.

**Screen sharing requires portals.** There is no other mechanism on Wayland. A
compositor will not let an application read another application's windows, and
neither will XWayland. The application asks the portal, the portal asks the user,
and the compositor provides the pipe. If screen sharing or the file chooser is
broken under a given desktop, the first thing to check is that the matching
portal backend is installed and running.

Each desktop's backend:

| Desktop | Portal backend |
|---|---|
| GNOME | `xdg-desktop-portal-gnome` |
| Cinnamon | `xdg-desktop-portal-xapp` (Cinnamon uses the XDG App portal) |
| Plasma | `xdg-desktop-portal-kde` |
| XFCE | `xdg-desktop-portal-gtk` |

## Compositor and session mapping

| Desktop | Wayland compositor | X11 session |
|---|---|---|
| GNOME 50 | Mutter (built into `gnome-shell`) | Flashback with Compiz or Metacity |
| Cinnamon 6.4.13 | Muffin | xfwm4 is irrelevant; Cinnamon uses Muffin on X11 too |
| Plasma 6.6.4 | KWin (`kwin-wayland`) | KWin X11 (`kwin-x11`) |
| XFCE 4.20.4 | labwc (native session) | xfwm4 |

The XFCE row is unusual: XFCE's Wayland session is backed by **labwc**, not by
xfwm4. xfwm4 is an X11 window manager and has no Wayland implementation. `labwc`
and `wayfire` also ship as standalone sessions.

## Environment variables

Force an application onto a particular backend:

```bash
QT_QPA_PLATFORM=wayland   # Qt applications -> native Wayland
QT_QPA_PLATFORM=xcb       # ...or force XWayland
GDK_BACKEND=wayland       # GTK3 applications -> native Wayland
GDK_BACKEND=x11          # ...or force X11
MOZ_ENABLE_WAYLAND=1      # Firefox
```

These are per-application overrides, useful for diagnosing a misbehaving app
rather than for global configuration.

## Scaling

Wayland handles fractional scaling natively; X11 does not — X11 scaling is
integer-only or fractional via the XRandR/`Xft.dpi` workaround, and it blurs.

If one application looks wrong next to the rest in a Wayland session, it is
probably not scaling at all but running through XWayland, where it cannot
fractionally scale. `GDK_BACKEND=wayland` or `QT_QPA_PLATFORM=wayland` for that
one application is the fix. Note that the XFCE native Wayland session and the
Flashback sessions have their own scaling quirks; there is no measurement here
and the practical advice is per-desktop trial.

## Troubleshooting

**Black screen after login**

1. Which session did you pick? Try the other one — under Plasma, try X11; under
   GNOME, try Flashback.
2. Switch to a TTY with `Ctrl+Alt+F3` and check the journal:

   ```bash
   journalctl -b -u lightdm   # or the compositor service
   journalctl -b | grep -i -E 'mutter|kwin|drm|glx|nouveau|amdgpu'
   ```

3. A common cause is the graphics driver. Disable modesetting at the kernel
   command line and boot to a session to confirm:

   ```
   nomodeset
   ```

   Press `Esc` at the bootloader to edit the parameters. If that boots, the
   problem is the DRM driver, not the desktop.
4. Software rendering via Mesa (`llvmpipe`) is a fallback for diagnosis, not a
   usable configuration.

**Confirming which display server you actually got**

```bash
echo $XDG_SESSION_TYPE     # x11 or wayland
echo $WAYLAND_DISPLAY      # set in a Wayland session
echo $DISPLAY              # set in an X11 session; also set in Wayland if XWayland is up
```

If `XDG_SESSION_TYPE` is empty, the session was started without a proper login
session and things will behave oddly.

**X11 application looks wrong or will not start in a Wayland session**

It is going through XWayland. Check `DISPLAY` is set, and try the native backend
override for its toolkit (`GDK_BACKEND=wayland`, `QT_QPA_PLATFORM=wayland`).

**Screen sharing or file chooser does nothing**

The portal backend for that desktop is missing or crashed. Check
`journalctl --user | grep -i portal`.

**A GTK dialog looks wrong under Plasma (or vice versa)**

Mixing GTK and Qt toolkits means the Qt dialog is used and the GTK one is
mismatched. Install the theme bridge for the other toolkit, or set
`GTK_THEME`/`QT_STYLE_OVERRIDE` explicitly.

## See also

* [docs/DESKTOP-ENVIRONMENTS.md](DESKTOP-ENVIRONMENTS.md) — session files, per-DE caveats
* [docs/BUILD.md](BUILD.md) — build traps, package lists
