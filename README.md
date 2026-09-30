# myblue

my personal fedora image

Currently targeting MS Surface Book 2 with NVIDIA GTX 1060 Mobile. (Requires NVIDIA proprietary drivers)

# Switch to this Image

From your bootc system, run the following command substituting in your Github username and image name where noted.

```bash
sudo bootc switch ghcr.io/phcreery/myblue
sudo systemctl reboot
```
OR

```bash
sudo bootc switch ghcr.io/phcreery/myblue:latest
sudo systemctl reboot
```
or 

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/phcreery/myblue:latest
sudo systemctl reboot
```

This should queue your image for the next reboot, which you can do immediately after the command finishes. You have officially set up your custom image! See the following section for an explanation of the important parts of the template for customization.


## Update

If you're already running myblue

```bash
sudo bootc upgrade
sudo systemctl reboot
```

# Repository Contents

See: https://github.com/ublue-os/image-template

# Inspiration

- Working base: bluefin-hwe-nvidia:latest (F42)
  - https://github.com/ublue-os/bluefin/pkgs/container/bluefin-hwe-nvidia
  - sha256:862f774618a6d766b10992753b63897d47ef7fd6d134a09315a501871c00fcd7

  > [Note]: After a deprecation cycle the following images are now removed:
  > 
  >> Nvidia Closed Images: Due to Nvidia's software support changes we can no longer support the older closed modules for Nvidia cards. Not many people are using these, either migrate to the nvidia-open images or move to a stock image to use > the built in kernel drivers.
  >>
  >> Bluefin HWE Images: Not many people were using these, they have also been removed.

  - Commit of bluefin-hwe-surface before it was removed
    - https://github.com/ublue-os/bluefin/tree/ed86f18028db2a016033026315a71a933263b69e
    - https://github.com/ublue-os/bluefin/blob/ed86f18028db2a016033026315a71a933263b69e/build_files/base/09-hwe-additions.sh
    - https://github.com/ublue-os/bluefin/blob/ed86f18028db2a016033026315a71a933263b69e/build_files/base/03-install-kernel-akmods.sh
    - https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh

- Surface continued support
  - https://github.com/LorbusChris/bluespin
- Misc
  - https://github.com/bsherman/bos
- Niri
  - https://github.com/wayblueorg/wayblue
- Base Nivida stupports F44 though...
  - https://github.com/ublue-os/hwe/pkgs/container/base-nvidia


# Surface

See
- https://github.com/linux-surface/linux-surface/wiki/Installation-and-Setup#fedora-silverblue
- https://github.com/linux-surface/linux-surface/issues/1666
Linux-surface forked to work with f44 7.1.3
- https://github.com/orthogonaleety/linux-surface

## Additional resources

For additional driver support, ublue maintains a set of scripts and container images available at [ublue-akmod](https://github.com/ublue-os/akmods). These images include the necessary scripts to install multiple kernel drivers within the container (Nvidia, OpenRazer, Framework...). The documentation provides guidance on how to properly integrate these drivers into your container image.

## Community Examples

These are images derived from this template (or similar enough to this template). Reference them when building your image!

- [m2Giles' OS](https://github.com/m2giles/m2os)
- [bOS](https://github.com/bsherman/bos)
- [Homer](https://github.com/bketelsen/homer/)
- [Amy OS](https://github.com/astrovm/amyos)
- [VeneOS](https://github.com/Venefilyn/veneos)
