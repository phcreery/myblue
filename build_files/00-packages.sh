#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# https://github.com/ublue-os/bluefin/blob/main/build_files/base/04-packages.sh

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# ublue staging and packages repos needed for misc packages provided by ublue
dnf -y copr enable ublue-os/packages
dnf -y copr enable ublue-os/staging
source /ctx/build_files/shared/copr-helpers.sh

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

# for ghostty
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

### Uninstall

dnf -y remove \
    gnome-tweaks

### Install

# Install additional fedora packages
FEDORA_PACKAGES=(
    adwaita-fonts-all
    bootc
    borgbackup
    btop
    containerd
    fastfetch
    gcc
    gcc-c++
    input-remapper
    jetbrains-mono-fonts-all
    libratbag-ratbagd
    make
    micro
    rclone
    restic
    samba
    stow
    tmux
    wl-clipboard
    wdisplays
    xdg-terminal-exec

    niri
    noctalia
    code
    ghostty
    ghostty-bash-completion
    ghostty-shell-integration
    ghostty-terminfo
    ghostty-vim
    # ghostty-nautilus
)

echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf -y install --skip-unavailable "${FEDORA_PACKAGES[@]}"

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    # firefox
)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi



# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging
#
# OR use helper script `copr_install_isolated`
copr_install_isolated "che/nerd-fonts" "nerd-fonts"
# copr_install_isolated "lionheartp/Hyprland" "noctalia-shell"


# dnf -y copr enable lorbus/NetworkManager
# dnf -y upgrade 'NetworkManager*'

# dnf -y copr enable lorbus/network-displays
# dnf -y install gnome-network-displays gnome-network-displays-extension

# dnf -y copr disable lorbus/NetworkManager
# dnf -y copr disable lorbus/network-displays

# install nirimod
curl -sSL https://raw.githubusercontent.com/srinivasr/nirimod/main/install.sh | bash

echo "::endgroup::"
