#!/bin/bash

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# ublue staging and packages repos needed for misc packages provided by ublue
dnf -y copr enable ublue-os/packages
dnf -y copr enable ublue-os/staging

### REPO

# VSCode because it's still better for a lot of things
tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# ghostty
dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

### Uninstall

dnf -y remove \
    gnome-tweaks

### Install

# Install additional fedora packages
ADDITIONAL_FEDORA_PACKAGES=(
    niri
    code
    ghostty
    ghostty-bash-completion
    ghostty-shell-integration
    ghostty-terminfo
    ghostty-vim
    # ghostty-nautilus
)

dnf -y install --skip-unavailable \
    "${ADDITIONAL_FEDORA_PACKAGES[@]}"


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging
