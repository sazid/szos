# szos

Sazid's personal bootc Open Image.

Base image:

```text
ghcr.io/ublue-os/bazzite-gnome-nvidia-open:stable
```

## Layout

- `Containerfile`: image entrypoint and host-level RPM customization point.
- `files/`: root filesystem overlay copied into the image.
- `files/usr/share/ublue-os/just/60-custom.just`: custom `ujust` recipes.
- `Justfile`: local build helpers.

## Build Locally

```sh
just build-local
```

Equivalent command:

```sh
podman build --pull=newer -t localhost/szos:latest .
```

## Publish

```sh
just push ghcr.io/<github-user> szos latest
```

For a real machine, publish to a registry first and then switch from the target
Bazzite system:

```sh
sudo bootc switch ghcr.io/<github-user>/szos:latest
sudo systemctl reboot
```

## Customizing

Use image-level RPM installs only for things that must be in the host OS:
drivers, VPN clients, shells, system services, and low-level tools. Prefer
Flatpak, Homebrew, or Distrobox for regular apps.

To add RPMs, uncomment and edit the package block in `Containerfile`.

To add files, place them under `files/` with their final paths. For example:

```text
files/etc/containers/registries.conf.d/example.conf
files/usr/local/bin/example-script
files/usr/share/ublue-os/just/60-custom.just
```

Keep secrets out of this repo. Do not commit `cosign.key`, tokens, SSH keys, or
machine-specific private config.
