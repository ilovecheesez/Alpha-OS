#!/bin/bash
# Alpha OS - Build ISO using live-build
# Ubuntu 26.04 LTS (Resolute Raccoon) based

set -e

LIVE_CONFIG_DIR="live/config"
PACKAGES_DIR="packages"
OUTPUT_DIR="output"

echo "============================================"
echo "Alpha OS ISO Builder (live-build)"
echo "============================================"

# Create necessary directories
mkdir -p "$LIVE_CONFIG_DIR"
mkdir -p "$PACKAGES_DIR"
mkdir -p "$OUTPUT_DIR"

# Check if live-build is installed
if ! command -v lb &> /dev/null; then
    echo "[ERROR] live-build not found. Please install it:"
    echo "  sudo apt-get install live-build"
    exit 1
fi

# Configure live-build
echo "[CONFIG] Configuring live-build..."
lb config \
    --mode ubuntu \
    --distribution resolute \
    --archive-areas "main restricted universe multiverse" \
    --debian-installer false \
    --bootappend-live "boot=casper quiet splash" \
    --architectures amd64 \
    --linux-flavours "generic" \
    --mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
    --mirror-chroot "http://archive.ubuntu.com/ubuntu/" \
    --mirror-binary "http://archive.ubuntu.com/ubuntu/" \
    --mirror-binary-security "http://security.ubuntu.com/ubuntu" \
    --updates true \
    --security true \
    --bootstrap-qemu-arch "aarch64" \
    --bootstrap-qemu-static "/usr/bin/qemu-aarch64-static" \
    --firmware-binary true \
    --firmware-chroot true \
    --win32-loader false \
    --memtest none \
    --archive-areas "main restricted universe multiverse" \
    --backports true \
    "${LIVE_CONFIG_DIR}"

# Create package lists
echo "[PACKAGES] Creating package lists..."

# Base system
cat > "${PACKAGES_DIR}/00-base.list.chroot" << 'EOF'
# Base system
tasksel
tasksel-data
ubiquity
ubiquity-frontend-gtk
initramfs-tools
casper
 lupin-casper
 discover
 discover-data
 laptop-detect
 os-prober
 linux-generic
EOF

# Audio (PulseAudio + PipeWire)
cat > "${PACKAGES_DIR}/10-audio.list.chroot" << 'EOF'
# Audio stack - PulseAudio + PipeWire
pulseaudio
pulseaudio-utils
pulseaudio-module-bluetooth
pavucontrol
pipewire
pipewire-pulse
pipewire-alsa
pipewire-jack
wireplumber
libspa-0.2-modules
libspa-0.2-modules-extra
bluez
bluez-tools
blueman
gstreamer1.0-plugins-base
gstreamer1.0-plugins-good
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-ugly
gstreamer1.0-libav
EOF

# Display servers (X11 + Wayland)
cat > "${PACKAGES_DIR}/20-display-x11.list.chroot" << 'EOF'
# X11 Display Server
xorg
xserver-xorg
xserver-xorg-core
xserver-xorg-video-all
xserver-xorg-input-all
x11-xserver-utils
x11-apps
x11-utils
xinit
EOF

cat > "${PACKAGES_DIR}/21-display-wayland.list.chroot" << 'EOF'
# Wayland Display Server
wayland-protocols
libwayland-bin
libwayland-dev
wayland-utils
weston
xdg-desktop-portal
xdg-desktop-portal-gtk
xdg-desktop-portal-kde
xdg-desktop-portal-xapp
EOF

# Desktop Environments
cat > "${PACKAGES_DIR}/30-gnome.list.chroot" << 'EOF'
# GNOME Desktop Environment
ubuntu-desktop
gnome-shell
gnome-shell-extensions
gnome-terminal
gnome-control-center
gnome-settings-daemon
nautilus
evince
firefox
libreoffice
rhythmbox
totem
shotwell
simple-scan
gedit
gnome-software
gnome-initial-setup
network-manager
network-manager-gnome
gdm3
xwayland
yaru-theme
EOF

cat > "${PACKAGES_DIR}/31-cinnamon.list.chroot" << 'EOF'
# Cinnamon Desktop Environment
ubuntucinnamon-desktop
cinnamon
cinnamon-control-center
cinnamon-session
cinnamon-settings-daemon
cinnamon-screensaver
nemo
nemo-fileroller
nemo-python
libxapp1
libxapp-common
cinnamon-xapp
lightdm
lightdm-gtk-greeter
gnome-terminal
rhythmbox
xdg-desktop-portal-xapp
EOF

cat > "${PACKAGES_DIR}/32-plasma.list.chroot" << 'EOF'
# KDE Plasma Desktop Environment
kubuntu-desktop
plasma-desktop
plasma-workspace
sddm
sddm-theme-breeze
konsole
dolphin
kate
kwrite
yakuake
kcalc
kdeconnect
ark
klipper
spectacle
okular
gwenview
elisa
filelight
kalarm
kcachegrind
kmenuedit
ksysguard
ktorrent
breeze
breeze-gtk
breeze-icon-theme
breeze-wallpapers
xdg-desktop-portal-kde
EOF

cat > "${PACKAGES_DIR}/33-xfce.list.chroot" << 'EOF'
# XFCE Desktop Environment
xubuntu-desktop
xfce4
xfce4-goodies
xfce4-panel
xfce4-session
xfwm4
xfdesktop4
xfce4-appfinder
xfce4-mixer
xfce4-power-manager
xfce4-screenshooter
xfce4-taskmanager
xfce4-notes
thunar
thunar-archive-plugin
thunar-media-tags-plugin
thunar-volman
thunar-vcs-plugin
xfce4-terminal
mousepad
parole
ristretto
xfce4-settings
xfce4-control-center
xfce4-screensaver
lightdm
lightdm-gtk-greeter
xdg-desktop-portal-gtk
EOF

# Live system extras
cat > "${PACKAGES_DIR}/40-live.list.chroot" << 'EOF'
# Live system utilities
casper
lupin-casper
discover
discover-data
laptop-detect
os-prober
network-manager
resolvconf
usbutils
pciutils
smartmontools
efibootmgr
grub-efi-amd64-bin
grub-efi-arm64-bin
shim-signed
mtools
EOF

# PPAs (added via hooks)
cat > "${PACKAGES_DIR}/50-ppa.list.chroot" << 'EOF'
# PPAs will be added via hooks
# ubuntu-desktop/ppa
# kubuntu-ppa/backports
# cinnamon-team/ppa
# xfce-gooders/ppa
# pipewire-debian/pipewire-upstream
EOF

# Create hooks
echo "[HOOKS] Creating live-build hooks..."
mkdir -p live/hooks
mkdir -p live/chroot_hooks

# 05-build-config: Basic configuration
cat > "live/hooks/05-build-config.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[HOOK] Setting up basic configuration..."
EOF
chmod +x live/hooks/05-build-config.hook.chroot

# 50-locales: Configure locales
cat > "live/hooks/50-locales.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[HOOK] Configuring locales..."
echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections
echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
update-locale LANG=en_US.UTF-8
EOF
chmod +x live/hooks/50-locales.hook.chroot

# 99-extras: Final cleanup and setup
cat > "live/hooks/99-extras.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[HOOK] Performing final setup..."
# Remove unnecessary packages to save space
apt-get clean
rm -rf /tmp/* /var/tmp/*
rm -f /etc/ssh/ssh_host_*_key*
EOF
chmod +x live/hooks/99-extras.hook.chroot

# Chroot hooks for desktop configuration
# 10-branding: Set hostname and basic branding
cat > "live/chroot_hooks/10-branding.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Setting hostname to alphaos..."
echo "alphaos" > /etc/hostname
cat > /etc/hosts << 'HOSTSEOF'
127.0.0.1	localhost
127.0.1.1	alphaos
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters
HOSTSEOF
EOF
chmod +x live/chroot_hooks/10-branding.hook.chroot

# 20-audio: Configure audio
cat > "live/chroot_hooks/20-audio.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Configuring audio stack..."
# Ensure PipeWire is the default sound server
if [ -f /etc/pipewire/pipewire.conf ]; then
    sed -i 's/#\s*default.clock.rate = 48000/default.clock.rate = 48000/' /etc/pipewire/pipewire.conf
fi
# Enable PipeWire-Pulse by default
mkdir -p /etc/pipewire/media-session.d
ln -sf /usr/share/pipewire/media-session.d/with-pulseaudio /etc/pipewire/media-session.d/with-pulseaudio
EOF
chmod +x live/chroot_hooks/20-audio.hook.chroot

# 30-display: Configure display managers for multi-desktop
cat > "live/chroot_hooks/30-display.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Setting up display managers for multi-desktop..."
# Install lightdm as standard display manager
# GNOME, Cinnamon, Plasma, XFCE will all work with lightdm
# Users can select desktop at login screen
EOF
chmod +x live/chroot_hooks/30-display.hook.chroot

# 40-sessions: Create desktop session files
cat > "live/chroot_hooks/40-sessions.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Creating desktop session files..."
# GNOME Session (Wayland default with X11 fallback)
cat > /usr/share/xsessions/alphaos-gnome-wayland.desktop << 'DESKTOPEOF'
[Desktop Entry]
Name=Alpha OS (GNOME Wayland)
Comment=Log in to the GNOME desktop with Wayland
Exec=gnome-session
TryExec=gnome-session
Icon=
Type=Application
DesktopNames=GNOME
EOF
DESKTOPEOF

cat > /usr/share/xsessions/alphaos-gnome-x11.desktop << 'DESKTOPEOF'
[Desktop Entry]
Name=Alpha OS (GNOME X11)
Comment=Log in to the GNOME desktop with X11
Exec=env GDM_XSERVER_LOCATION=local gnome-session --session=gnome-x11
TryExec=gnome-session
Icon=
Type=Application
DesktopNames=GNOME
EOF
DESKTOPEOF

# Cinnamon Session
cat > /usr/share/xsessions/alphaos-cinnamon.desktop << 'DESKTOPEOF'
[Desktop Entry]
Name=Alpha OS Cinnamon
Comment=Log in to the Cinnamon desktop
Exec=cinnamon-session
TryExec=cinnamon-session
Icon=
Type=Application
DesktopNames=Cinnamon
EOF
DESKTOPEOF

# KDE Plasma Sessions
cat > /usr/share/xsessions/alphaos-plasma-wayland.desktop << 'DESKTOPEOF'
[Desktop Entry]
Name=Alpha OS Plasma (Wayland)
Comment=Log in to KDE Plasma Wayland
Exec=startplasma-wayland
TryExec=startplasma-wayland
Icon=
Type=Application
DesktopNames=KDE
EOF
DESKTOPEOF

cat > /usr/share/xsessions/alphaos-plasma-x11.desktop << 'DESKTOPEOF'
[Desktop Entry]
Name=Alpha OS Plasma (X11)
Comment=Log in to KDE Plasma X11
Exec=startplasma-x11
TryExec=startplasma-x11
Icon=
Type=Application
DesktopNames=KDE
EOF
DESKTOPEOF

# XFCE Session
cat > /usr/share/xsessions/alphaos-xfce.desktop << 'DESKTOPEOF'
[Desktop Entry]
Name=Alpha OS XFCE
Comment=Log in to the XFCE desktop
Exec=xfce4-session
TryExec=xfce4-session
Icon=
Type=Application
DesktopNames=XFCE
EOF
DESKTOPEOF
EOF
chmod +x live/chroot_hooks/40-sessions.hook.chroot

# 50-displaymanager: Configure LightDM
cat > "live/chroot_hooks/50-displaymanager.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Configuring LightDM display manager..."
# Set LightDM as default display manager
debconf-set-selections <<< "shared/default-display-manager select lightdm"
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure lightdm

# Configure LightDM to show all desktop environments
cat > /etc/lightdm/lightdm.conf << 'LDMSEOF'
[Seat:*]
type=local
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
greeter-show-manual-login=true
allow-guest=false
LDMSEOF
EOF
chmod +x live/chroot_hooks/50-displaymanager.hook.chroot

# 60-firstboot: Create first boot setup
cat > "live/chroot_hooks/60-firstboot.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Setting up first boot scripts..."
# Create first boot script that removes itself after first run
cat > /usr/local/bin/alphaos-firstboot << 'FIRSTBOOTEOF'
#!/bin/bash
# Alpha OS First Boot Setup
echo "Running Alpha OS first boot setup..."
# Remove this script after first run
rm -f /usr/local/bin/alphaos-firstboot
rm -f /etc/init.d/alphaos-firstboot
update-rc.d -f alphaos-firstboot remove
echo "First boot setup complete."
FIRSTBOOTEOF
chmod +x /usr/local/bin/alphaos-firstboot

# Create init script for first boot
cat > /etc/init.d/alphaos-firstboot << 'INITEOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          alphaos-firstboot
# Required-Start:    $local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-description: Alpha OS first boot setup
# Description:       Runs first boot setup tasks
### END INIT INFO

/usr/local/bin/alphaos-firstboot
INITEOF
chmod +x /etc/init.d/alphaos-firstboot
update-rc.d alphaos-firstboot defaults
EOF
chmod +x live/chroot_hooks/60-firstboot.hook.chroot

# 70-ppas: Add Ubuntu PPAs
cat > "live/chroot_hooks/70-ppas.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Adding Ubuntu PPAs..."
# Add PPAs for latest software
add-apt-repository -y ppa:ubuntu-desktop/ppa || true
add-apt-repository -y ppa:kubuntu-ppa/backports || true
add-apt-repository -y ppa:kubuntu-ppa/ppa || true
add-apt-repository -y ppa:cinnamon-team/ppa || true
add-apt-repository -y ppa:xfce-gooders/ppa || true
add-apt-repository -y ppa:pipewire-debian/pipewire-upstream || true
# Update package lists after adding PPAs
apt-get update
EOF
chmod +x live/chroot_hooks/70-ppas.hook.chroot

# 99-cleanup: Final cleanup
cat > "live/chroot_hooks/99-cleanup.hook.chroot" << 'EOF'
#!/bin/bash
set -e
echo "[CHROOT HOOK] Final cleanup..."
# Clean up apt cache
apt-get clean
# Remove temporary files
rm -rf /tmp/* /var/tmp/*
# Remove any leftover live-build artifacts
rm -rf /live
rm -rf /lib/live
# Remove SSH host keys (will be regenerated on first boot)
rm -f /etc/ssh/ssh_host_*_key*
EOF
chmod +x live/chroot_hooks/99-cleanup.hook.chroot

# Create files directory for overlays
mkdir -p live/files

# Copy any custom configuration files here (if needed)
# For now, we'll keep it empty as defaults are good

echo ""
echo "[DONE] live-build configuration created successfully!"
echo ""
echo "To build the ISO:"
echo "  sudo lb build"
echo ""
echo "The ISO will be created in the current directory as:"
echo "  live-image-amd64.hybrid.iso"
echo ""