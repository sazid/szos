# Personal ujust recipes for szos.

szos-info:
    #!/usr/bin/env bash
    set -euo pipefail
    bootc status || rpm-ostree status
