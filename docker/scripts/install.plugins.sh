#!/bin/bash
set -e

# Dispatch to a per-plugin install script.
# Usage: install.plugins.sh <plugin> [<plugin> ...]
# Example: install.plugins.sh gstack  ->  runs install.plugins.gstack.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -eq 0 ]; then
    echo "Usage: $(basename "$0") <plugin> [<plugin> ...]" >&2
    echo "Available plugins:" >&2
    for f in "${SCRIPT_DIR}"/install.plugins.*.sh; do
        name="$(basename "$f")"
        name="${name#install.plugins.}"
        name="${name%.sh}"
        echo "  - ${name}" >&2
    done
    exit 1
fi

for plugin in "$@"; do
    target="${SCRIPT_DIR}/install.plugins.${plugin}.sh"
    if [ ! -f "${target}" ]; then
        echo "Error: no install script for plugin '${plugin}' (expected ${target})." >&2
        exit 1
    fi
    echo "==> Installing plugin '${plugin}' via ${target}"
    bash "${target}"
done
