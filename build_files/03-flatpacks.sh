#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# to show locally installed packages: `flatpak list --app --columns=application`
# Copy ISO list for `install-system-flatpaks`
install -Dm0644 -t /etc/ublue-os/ /ctx/files/etc/ublue-os/*.list
# install -Dm0644 -t /usr/share/ublue-os/homebrew/ /ctx/files/usr/share/ublue-os/homebrew/*.Brewfile
