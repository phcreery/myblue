#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# https://github.com/ublue-os/bluefin/blob/ed86f18028db2a016033026315a71a933263b69e/build_files/base/03-install-kernel-akmods.sh
# Fetch Nvidia RPMs
if [[ "${IMAGE_NAME}" =~ open ]]; then
    skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia-open:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-rpms
else
    skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-rpms
fi
NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods-rpms/

# Exclude the Golang Nvidia Container Toolkit in Fedora Repo
# Exclude for non-beta.... doesn't appear to exist for F42 yet?
if [[ "${UBLUE_IMAGE_TAG}" != "beta" ]]; then
    dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit
else
    # Monkey patch right now...
    if ! grep -q negativo17 <(rpm -qi mesa-dri-drivers); then
        dnf5 -y swap --repo=updates-testing \
            mesa-dri-drivers mesa-dri-drivers
    fi
fi

# Install Nvidia RPMs
ghcurl "https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh" -o /tmp/nvidia-install.sh
chmod +x /tmp/nvidia-install.sh
IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF
