#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# The base image (wayblue niri-nvidia) only ships the Nvidia kernel module for
# the Fedora kernel it was built against. 02-surface.sh replaces that kernel
# with kernel-surface, which leaves the dGPU without a kernel module and makes
# nvidia-smi fail ("couldn't communicate with the NVIDIA driver"). This script
# builds the Nvidia kmod for the Surface kernel.
#
# Driver line: the Surface Book 2's GTX 10-series is Pascal, whose last
# supporting branch is 580. The base image already carries the matching
# negative17 nvidia-driver 580 userspace, so we build from negative17's LTS
# (nvidia-580) repo to keep the kmod at the exact same version.

# Kernel build tree/headers required by akmods, from the linux-surface repo.
# (02-surface.sh disabled the repo again, so re-enable it for this install.)
dnf config-manager setopt linux-surface.enabled=1
dnf -y install --setopt=disable_excludes=* kernel-surface-devel
dnf config-manager setopt linux-surface.enabled=0

KERNEL_VERSION="$(rpm -q kernel-surface --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

# 02-surface.sh erased the Fedora kernel, but the base image's kmod-nvidia (and
# the kernel's depmod output) keeps a second /usr/lib/modules tree alive.
# `bootc container lint` requires exactly one subdirectory there, and the module
# is useless without its kernel anyway, so drop the package and any orphaned
# module trees.
dnf -y remove --setopt=clean_requirements_on_remove=False kmod-nvidia || true
for module_dir in /usr/lib/modules/*; do
    [[ "$(basename "$module_dir")" == "$KERNEL_VERSION" ]] || rm -rf "$module_dir"
done

# Guard against drifting away from the Pascal-capable 580 branch. If the base
# image ever moves to a newer driver, the LTS repo below no longer matches and
# the kmod would refuse to link against the installed userspace.
NVIDIA_VERSION="$(rpm -q nvidia-driver --queryformat '%{VERSION}')"
if [[ "${NVIDIA_VERSION}" != 580.* ]]; then
    echo "ERROR: nvidia-driver is ${NVIDIA_VERSION}; this image expects the 580 (Pascal) branch." >&2
    exit 1
fi

# Build tooling used by akmods.
dnf -y install akmods kmodtool gcc make rpm-build

# negativo17's LTS/580 repo, matching the userspace already in the base image.
NEG_REPO=/etc/yum.repos.d/negativo17-fedora-nvidia-lts.repo
NEG_REPO_ID=fedora-nvidia-lts
cat >"$NEG_REPO" <<'EOF'
[fedora-nvidia-lts]
name=negativo17 - Nvidia (LTS/580)
baseurl=https://negativo17.org/repos/nvidia-580/fedora-$releasever/$basearch/
enabled=1
skip_if_unavailable=1
gpgcheck=1
gpgkey=https://negativo17.org/repos/RPM-GPG-KEY-slaanesh
enabled_metadata=1
type=rpm-md
repo_gpgcheck=0
EOF

# akmod-nvidia's %post runs akmods-ostree-post, which calls akmodsbuild directly
# as root. On a bootc image that build fails (akmodsbuild refuses to run as
# root), which aborts the whole dnf transaction. Neutralize the helper during
# install and let the explicit `akmods` run below do the real build as the
# unprivileged akmods user (which is the supported path).
AKMODS_OSTREE_POST=/usr/sbin/akmods-ostree-post
if [[ -x "$AKMODS_OSTREE_POST" ]]; then
    mv "$AKMODS_OSTREE_POST" /tmp/akmods-ostree-post.real
    printf '#!/bin/sh\nexit 0\n' >"$AKMODS_OSTREE_POST"
    chmod 0755 "$AKMODS_OSTREE_POST"
fi
dnf -y install --repo="$NEG_REPO_ID" --setopt=install_weak_deps=False "akmod-nvidia-${NVIDIA_VERSION}"
if [[ -f /tmp/akmods-ostree-post.real ]]; then
    mv -f /tmp/akmods-ostree-post.real "$AKMODS_OSTREE_POST"
fi

# Fail the build early (and loudly) instead of shipping a broken image.
require_nvidia_kmod() {
    if ! compgen -G "/usr/lib/modules/${KERNEL_VERSION}/extra/nvidia/nvidia.ko*" >/dev/null; then
        echo "ERROR: Nvidia kmod was not built for ${KERNEL_VERSION}." >&2
        if [[ -f "/var/cache/akmods/nvidia/nvidia-${NVIDIA_VERSION}-for-${KERNEL_VERSION}.failed.log" ]]; then
            cat "/var/cache/akmods/nvidia/nvidia-${NVIDIA_VERSION}-for-${KERNEL_VERSION}.failed.log" >&2
        fi
        exit 1
    fi
}

# Build and install the kmod for the Surface kernel.
akmods --force --kernels "$KERNEL_VERSION" --kmod nvidia
require_nvidia_kmod

# The akmod bundles ~160 MB of driver source; the built kmod is a separate RPM,
# so drop the source to keep image/update size down.
dnf -y remove --setopt=clean_requirements_on_remove=False akmod-nvidia
require_nvidia_kmod

# Keep the LTS repo from leaking into the final image.
rm -f "$NEG_REPO"

# Rebuild the initramfs so it actually contains the Nvidia modules.
# 02-surface.sh already did this, but the kmod did not exist yet at that point.
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --add ostree -f "/lib/modules/$KERNEL_VERSION/initramfs.img"
chmod 0600 "/lib/modules/$KERNEL_VERSION/initramfs.img"

echo "::endgroup::"
