#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# https://github.com/LorbusChris/bluespin/blob/main/build_files/build.sh
# https://github.com/ublue-os/bluefin/blob/ed86f18028db2a016033026315a71a933263b69e/build_files/base/09-hwe-additions.sh

# Install Surface Packages
dnf config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo
dnf config-manager setopt linux-surface.enabled=0

SURFACE_PACKAGES=(
    iptsd
    libcamera
    libcamera-tools
    libcamera-gstreamer
    libcamera-ipa
    pipewire-plugin-libcamera
)

dnf5 -y install --skip-unavailable "${SURFACE_PACKAGES[@]}"

# Workaround: linux-surface has no F44 repo yet, and its repofile hardcodes
# baseurl=.../fedora/f$releasever/, which 404s on F44. Pin to F43 until F44 is published.
# Fail loudly rather than silently skipping the repo (upstream sets skip_if_unavailable=1).
# https://github.com/linux-surface/linux-surface/issues/2102
dnf config-manager setopt linux-surface.baseurl=https://pkg.surfacelinux.com/fedora/f43/
dnf config-manager setopt linux-surface.skip_if_unavailable=0

# NOTE: libwacom-surface{,-data} is deliberately NOT swapped in. It is not merely
# inconvenient on F44, it is uninstallable:
#   - libwacom-surface (2.17) provides symbol versions up to LIBWACOM_2.15, but F44's
#     libinput requires LIBWACOM_2.18 -> dnf "resolves" this by erasing libinput+GNOME.
#   - libwacom-surface-data provides an *unversioned* libwacom-data, which cannot
#     satisfy F44 libwacom's strict `Requires: libwacom-data = 2.19.0-1.fc44`.
# Backporting just the .tablet files doesn't work either: modern Surface entries use
# `virt|` and `mei|` DeviceMatch bus types that only the forked library understands;
# stock libwacom rejects them as invalid.
# Cost of omitting: GNOME loses pen-display metadata for Surface Pro 4+/Book/Laptop
# Studio (stock libwacom only knows Surface Go/Go 2). Pen and touch input themselves
# still work via iptsd + libinput's generic tablet handling.
# Restore the swap once linux-surface publishes F44 builds against libwacom 2.19.

# Remove Existing Kernel
# Tolerate packages the base image no longer ships (e.g. kmod-framework-laptop);
# under `set -e` an unconditional erase of a missing package aborts the build.
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra \
        kmod-framework-laptop kmod-v4l2loopback v4l2loopback; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        rpm --erase "$pkg" --nodeps
    fi
done

# Configure surface kernel modules to load at boot
tee /usr/lib/modules-load.d/ublue-surface.conf << EOF
# Only on AMD models
pinctrl_amd

# Surface Book 2
pinctrl_sunrisepoint

# For Surface Pro 7/Laptop 3/Book 3
pinctrl_icelake

# For Surface Pro 7+/Pro 8/Laptop 4/Laptop Studio
pinctrl_tigerlake

# For Surface Pro 9/Laptop 5
pinctrl_alderlake

# For Surface Pro 10/Laptop 6
pinctrl_meteorlake

# Only on Intel models
intel_lpss
intel_lpss_pci

# Add modules necessary for Disk Encryption via keyboard
surface_aggregator
surface_aggregator_registry
surface_aggregator_hub
surface_hid_core
8250_dw

# Surface Pro 7/Laptop 3/Book 3 and later
surface_hid
surface_kbd

EOF

# Install Kernel + touch daemon.
# Enable the repo alongside Fedora's rather than passing --repo=linux-surface:
# --repo restricts resolution to that repo alone, so iptsd's dependencies
# (cairomm, which Fedora ships) become unresolvable.
dnf config-manager setopt linux-surface.enabled=1
dnf -y install --setopt=disable_excludes=* \
    kernel-surface iptsd
dnf config-manager setopt linux-surface.enabled=0

dnf versionlock add kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# Regenerate initramfs
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-surface-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-surface-(|'"$KERNEL_SUFFIX"'-)//')"
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

echo "::endgroup::"
