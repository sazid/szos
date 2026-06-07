ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-gnome-nvidia-open
ARG BASE_TAG=stable

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG IMAGE_NAME=szos
ARG IMAGE_DESCRIPTION="Sazid's personal bootc Open Image"

LABEL org.opencontainers.image.title="${IMAGE_NAME}" \
      org.opencontainers.image.description="${IMAGE_DESCRIPTION}" \
      org.opencontainers.image.source="https://github.com/sazid/szos"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Keep the first build boring. Add only host-level RPMs here: drivers, VPNs,
# shells, system daemons, and tools that must exist outside containers.
# Prefer Flatpak, Homebrew, or Distrobox for regular desktop applications.
#
RUN rpm-ostree install -y --idempotent --allow-inactive \
    curl \
    android-tools \
    asciinema \
    clang \
    cmake \
    gcc \
    gcc-c++ \
    gh \
    helix \
    java-25-openjdk-devel \
    just \
    lld \
    lldb \
    llvm \
    make \
    ninja-build \
    nodejs22 \
    nodejs22-npm \
    pkgconf-pkg-config \
    podman-compose \
    vim-enhanced \
    wireguard-tools \
    && ostree container commit

# Put files under files/ using their final rootfs paths.
# Example: files/usr/share/ublue-os/just/60-custom.just lands at
# /usr/share/ublue-os/just/60-custom.just in the image.
COPY files/ /

RUN ostree container commit
