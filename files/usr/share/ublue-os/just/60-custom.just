# Personal ujust recipes for szos.

szos-info:
    #!/usr/bin/env bash
    set -euo pipefail
    bootc status || rpm-ostree status

szos-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail

    manifest="/usr/share/szos/flatpaks.txt"

    if [[ ! -r "${manifest}" ]]; then
        printf 'Flatpak manifest not found: %s\n' "${manifest}" >&2
        exit 1
    fi

    flatpak remote-add --if-not-exists --system flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

    mapfile -t apps < <(grep -Ev '^[[:space:]]*(#|$)' "${manifest}")

    if ((${#apps[@]} == 0)); then
        printf 'No Flatpak apps listed in %s\n' "${manifest}"
        exit 0
    fi

    printf 'Installing or updating %d system Flatpak apps from %s\n' "${#apps[@]}" "${manifest}"
    flatpak install --system --or-update -y flathub "${apps[@]}"
    printf 'Flatpak app set is installed or up to date.\n'

szos-devtools:
    #!/usr/bin/env bash
    set -euo pipefail

    export VOLTA_HOME="${VOLTA_HOME:-${HOME}/.volta}"
    export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${VOLTA_HOME}/bin:${PATH}"

    have() {
        command -v "$1" >/dev/null 2>&1
    }

    step() {
        printf '\n==> %s\n' "$*"
    }

    require_curl() {
        if ! have curl; then
            printf 'curl is required. Add it to the image or install it before running this recipe.\n' >&2
            exit 1
        fi
    }

    check_image_devtools() {
        step "Image dev tools"
        local missing=0

        if have java; then
            java -version 2>&1 | head -n 1
        else
            printf 'missing: java\n' >&2
            missing=1
        fi

        if have javac; then
            javac -version
        else
            printf 'missing: javac\n' >&2
            missing=1
        fi

        if have adb; then
            adb version | head -n 1
        else
            printf 'missing: adb\n' >&2
            missing=1
        fi

        if have fastboot; then
            fastboot --version | head -n 1
        else
            printf 'missing: fastboot\n' >&2
            missing=1
        fi

        if have gh; then
            gh --version | head -n 1
        else
            printf 'missing: gh\n' >&2
            missing=1
        fi

        if have asciinema; then
            asciinema --version
        else
            printf 'missing: asciinema\n' >&2
            missing=1
        fi

        if have hx; then
            hx --version
        else
            printf 'missing: hx\n' >&2
            missing=1
        fi

        tools=(
            gcc
            g++
            clang
            clang++
            llvm-config
            ld.lld
            lldb
            make
            cmake
            ninja
            pkg-config
            just
        )

        for tool in "${tools[@]}"; do
            if have "${tool}"; then
                "${tool}" --version | head -n 1
            else
                printf 'missing: %s\n' "${tool}" >&2
                missing=1
            fi
        done

        if ((missing)); then
            printf 'Missing tools above are provided by image RPMs. Rebuild and switch to the updated image.\n' >&2
        fi
    }

    install_rust() {
        step "Rust and Cargo"

        if have rustup; then
            rustup update stable
            rustup default stable
        else
            require_curl
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
                sh -s -- -y --profile default
        fi

        rustc --version
        cargo --version
    }

    install_uv() {
        step "uv"

        if have uv; then
            uv self update || printf 'uv self update skipped; keeping existing uv install.\n'
        else
            require_curl
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi

        uv --version
    }

    ensure_node() {
        step "Node.js and npm"

        if have npm; then
            node --version
            npm --version
            return
        fi

        if ! have volta; then
            require_curl
            curl https://get.volta.sh | bash
        fi

        export PATH="${VOLTA_HOME}/bin:${PATH}"
        volta install node
        node --version
        npm --version
    }

    install_node_clis() {
        step "Codex and OpenCode"
        ensure_node

        if have volta; then
            volta install @openai/codex opencode-ai
        else
            npm_prefix="$(npm prefix -g 2>/dev/null || true)"
            if [[ -z "${npm_prefix}" || ! -w "${npm_prefix}" ]]; then
                mkdir -p "${HOME}/.local"
                npm config set prefix "${HOME}/.local"
            fi

            # Overwrite stale shims from previous user-local installs.
            npm install -g --force @openai/codex opencode-ai
        fi

        codex --version || true
        opencode --version || true
    }

    check_image_devtools
    install_rust
    install_uv
    install_node_clis

    step "Done"
    printf 'Open a new shell if any installed command is not on PATH yet.\n'
