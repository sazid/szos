# szos

Sazid's personal bootc Open Image.

Base image:

```text
ghcr.io/ublue-os/bazzite-gnome-nvidia-open:stable
```

## Getting Started

Start from an existing bootc-based Bazzite/Universal Blue system, then switch to
this image:

```sh
sudo bootc switch ghcr.io/sazid/szos:latest
sudo systemctl reboot
```

After reboot, confirm the active image:

```sh
bootc status
```

Run the personal setup recipes after login:

```sh
ujust szos-devtools
ujust szos-flatpaks
```

To maintain the OS, wait for GitHub Actions to publish a new `latest` image,
then upgrade and reboot:

```sh
sudo bootc upgrade
sudo systemctl reboot
```

To stage and apply the upgrade immediately:

```sh
sudo bootc upgrade --apply
```

If the new deployment has a problem, roll back to the previous one:

```sh
sudo bootc rollback
sudo systemctl reboot
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

Commits pushed to `main` that change `Containerfile`, `files/`, or the build
workflow are built by GitHub Actions and published to GHCR. Documentation-only
changes skip the build. To rebuild the current commit (including a newer Bazzite
`stable` base), use **Actions → Build and publish image → Run workflow** on GitHub.
Build jobs have a 30-minute limit to bound runner usage.

```text
ghcr.io/<github-user>/szos:latest
ghcr.io/<github-user>/szos:sha-<commit>
```

If the GHCR package is private, make it public or configure registry auth on the
target machine before switching to it.

You can also publish manually from your workstation:

```sh
just push ghcr.io/<github-user> szos latest
```

## Customizing

Use image-level RPM installs only for things that must be in the host OS:
drivers, VPN clients, shells, system services, and low-level tools. Prefer
Flatpak, Homebrew, or Distrobox for regular apps.

User-space developer tools are bootstrapped after login:

```sh
ujust szos-devtools
```

The image includes OpenJDK 25 LTS, Android platform tools (`adb`/`fastboot`),
Node.js 22/npm, GitHub CLI, Asciinema, Helix, `just`, and a C/C++ build stack
with GCC, Clang/LLVM, CMake, Ninja, Make, LLD, LLDB, and `pkg-config`. The
recipe verifies those host tools, then installs or updates Rust/Cargo, `uv`,
Codex, and OpenCode under the current user's home directory.

The current system Flatpak app set is tracked in
`files/usr/share/szos/flatpaks.txt` and can be restored after login:

```sh
ujust szos-flatpaks
```

To add RPMs, uncomment and edit the package block in `Containerfile`.

To add files, place them under `files/` with their final paths. For example:

```text
files/etc/containers/registries.conf.d/example.conf
files/usr/local/bin/example-script
files/usr/share/ublue-os/just/60-custom.just
```

Keep secrets out of this repo. Do not commit `cosign.key`, tokens, SSH keys, or
machine-specific private config.
