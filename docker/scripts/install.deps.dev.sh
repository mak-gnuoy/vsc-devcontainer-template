#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.distro.sh
. "${SCRIPT_DIR}/lib.distro.sh"
detect_distro || exit 1

case "$DISTRO_FAMILY" in
    debian)
        apt-get update && apt-get install -y \
            ca-certificates \
            curl \
            bash \
            git \
            unzip \
            sudo \
            nodejs \
            npm \
            shellcheck \
            libnss3 \
            libatk1.0-0 \
            libatk-bridge2.0-0 \
            libcups2 \
            libdrm2 \
            libxkbcommon0 \
            libgbm1 \
            libx11-xcb1 \
            libxcomposite1 \
            libxdamage1 \
            libxrandr2 \
            libxss1 \
            libasound2 \
            libpangocairo-1.0-0 \
            libpango-1.0-0 \
            libgtk-3-0 \
            libxshmfence1 \
            libdbus-1-3 \
            lsb-release \
            fonts-liberation \
            libxfixes3 \
            libxi6 \
            libsm6 \
            libice6 \
            libxtst6 \
            libxcursor1 \
            libappindicator3-1 \
            && rm -rf /var/lib/apt/lists/*
        ;;
    rhel)
        "$PKG_MGR" install -y \
            ca-certificates \
            curl \
            bash \
            git \
            unzip \
            sudo \
            nodejs \
            npm
        ;;
esac

# Install bun (not available in OS package repos) via the official installer.
# Install into /usr/local so the binary lands on the default PATH for all users.
if ! command -v bun >/dev/null 2>&1; then
    export BUN_INSTALL=/usr/local
    curl -fsSL https://bun.sh/install | bash
fi
bun --version

# Install uv (Astral's Python package manager) via the official installer.
# Install into /usr/local/bin so it lands on the default PATH for all users.
if ! command -v uv >/dev/null 2>&1; then
    export UV_INSTALL_DIR=/usr/local/bin
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
uv --version

# Install shellcheck if the OS package manager did not provide it (e.g. RHEL,
# where it lives only in EPEL). Fall back to the official static binary from
# GitHub releases so the install works on any distro without extra repos.
if ! command -v shellcheck >/dev/null 2>&1; then
    sc_version="v0.10.0"
    case "$(uname -m)" in
        x86_64|amd64)   sc_arch="x86_64" ;;
        aarch64|arm64)  sc_arch="aarch64" ;;
        *) echo "Unsupported architecture for shellcheck: $(uname -m)"; exit 1 ;;
    esac
    sc_tarball="shellcheck-${sc_version}.linux.${sc_arch}.tar.xz"
    curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/${sc_version}/${sc_tarball}" \
        | tar -xJ -C /tmp
    install -m 0755 "/tmp/shellcheck-${sc_version}/shellcheck" /usr/local/bin/shellcheck
    rm -rf "/tmp/shellcheck-${sc_version}"
fi
shellcheck --version

# Verify Node.js and npm installation
node --version
npm --version
