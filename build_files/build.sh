#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /
# rsync -rvK /ctx/system_files/dx/ /


### Install packages
/ctx/build_files/00-packages.sh

### Install linux-surface kernel and support
/ctx/build_files/01-surface.sh

#### Example for enabling a System Unit File
# systemctl enable podman.socket


# Cleanup
dnf clean all

find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;
