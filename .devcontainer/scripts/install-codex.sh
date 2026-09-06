#!/usr/bin/env bash
# Installs the Codex CLI from a GitHub release.
#
# Codex ships prebuilt binaries, so it can be installed while the image is built
# instead of on every container create. The `codex-package-*` asset is used
# rather than the bare `codex-*` one because it carries the runtime files the CLI
# expects next to its executable — most importantly `codex-resources/bwrap`,
# without which `codex sandbox` refuses to start. Do not install Debian's
# `bubblewrap` package as a substitute: a system `bwrap` on PATH takes priority
# over the bundled one and cannot mount /proc inside an unprivileged container.
#
# Usage: install-codex.sh [VERSION]
set -euo pipefail

VERSION="${1:-${CODEX_VERSION:-latest}}"
PREFIX="${CODEX_PREFIX:-/opt/codex}"
BINDIR="${CODEX_BINDIR:-/usr/local/bin}"

case "$(uname -m)" in
    x86_64 | amd64) target='x86_64-unknown-linux-musl' ;;
    aarch64 | arm64) target='aarch64-unknown-linux-musl' ;;
    *)
        echo "install-codex: unsupported architecture $(uname -m)" >&2
        exit 1
        ;;
esac

# Releases are tagged rust-vX.Y.Z; "latest" resolves through GitHub's redirect so
# the script does not need an API token.
if [ "$VERSION" = 'latest' ]; then
    base='https://github.com/openai/codex/releases/latest/download'
else
    base="https://github.com/openai/codex/releases/download/rust-v${VERSION#v}"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "install-codex: fetching codex-package-${target}.tar.gz from ${base}"
curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/codex.tar.gz" "${base}/codex-package-${target}.tar.gz"

# The release has no published checksums, only sigstore bundles. Pass the digest
# of the asset you pinned to verify it:
#   CODEX_SHA256="$(sha256sum codex-package-${target}.tar.gz | cut -d' ' -f1)"
if [ -n "${CODEX_SHA256:-}" ]; then
    echo "${CODEX_SHA256}  ${tmp}/codex.tar.gz" | sha256sum -c -
fi

rm -rf "$PREFIX"
mkdir -p "$PREFIX" "$BINDIR"
tar -xzf "$tmp/codex.tar.gz" -C "$PREFIX"

# A symlink is enough: the CLI locates its bundled resources through
# /proc/self/exe, which resolves to the real path under $PREFIX.
ln -sfn "$PREFIX/bin/codex" "$BINDIR/codex"

"$BINDIR/codex" --version
