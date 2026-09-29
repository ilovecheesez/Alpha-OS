Alpha OS 26.04 LTS
==================

Alpha OS is a live USB / live DVD image built from Ubuntu 26.04 LTS. It boots into
a real, writable session (changes live in RAM and vanish on reboot) and can be
installed to disk with the Ubuntu installer.

Four desktops, one image
------------------------
Pick any of the following at the login screen. All four are installed:

  GNOME      50   - flagship Ubuntu GNOME
  Cinnamon   6.4  - classic desktop, GNOME layout without the GNOME extensions
  Plasma     6.6  - KDE desktop
  XFCE       4.20 - light, fast, good on older hardware

Additional compositors / display servers available in the session list:
labwc, wayfire and weston each ship their own Wayland session.

X11 and Wayland: what is actually real
--------------------------------------
The image ships BOTH X11 and Wayland sessions. What each desktop offers differs:

  GNOME
    Wayland only. GNOME 50 on 26.04 no longer provides an X11 session; there is
    no "GNOME on Xorg" entry. If you want the GNOME look on X11, install
    gnome-session-flashback, which then appears as
    "GNOME on Flashback (Compiz)" and "GNOME on Flashback (Metacity)".

  Cinnamon
    Both: "Cinnamon on Xorg", "Cinnamon (2D session) on Xorg" and
    "Cinnamon on Wayland".

  Plasma
    Both: "Plasma (X11)" and "Plasma (Wayland)".

  XFCE
    Both: "Xfce" (X11) and "Xfce Wayland".

So: X11 and Wayland are both available in this image, but they are not equally
available for every desktop. If a session you expect is missing, it is missing
because the upstream package does not ship it, not because of an Alpha OS
setting. Do not add .desktop files by hand into /usr/share/xsessions or
/usr/share/wayland-sessions - that shadows the packaged entries and breaks the
session list.

Audio architecture
------------------
All audio is PipeWire. The old standalone PulseAudio daemon is masked, so there
is no race between pulseaudio and pipewire-pulse.

  applications
      -> libpulse (PulseAudio client API, for compatibility)
          -> pipewire-pulse (PulseAudio server protocol implementation)
              -> PipeWire (the real audio/graph engine)
                  -> ALSA (hardware) and/or JACK (pro audio)

Practically: ordinary apps just work, and pro apps that speak JACK or native
PipeWire are routed to the same graph, so you can record from one and monitor
in another. Use `pw-top`, `wpctl status` or `pavucontrol` to inspect it.

Login details
-------------
  user     : ubuntu
  autologin: enabled, so a live session usually starts by itself
  guests   : disabled
  display manager: LightDM (the single greeter for the whole image)

Networking
----------
NetworkManager is enabled. Network wait-online is disabled, so networking comes
up immediately rather than delaying boot.

Getting help
------------
  In-image : this file, `man` pages, and `journalctl -b` for boot logs
  Live docs: the Alpha OS project pages (see the ISO boot menu or the
             distribution's documentation site)
  Bug reports and patches: the Alpha OS issue tracker

Persistence (optional)
----------------------
Alpha OS live images may support saving sessions to a partition at shutdown.
If a "Save changes" option is offered at shutdown, use it to keep files across
reboots; otherwise the session is temporary by design.
