#!/usr/bin/env bash
# Installs the GitHub Copilot CLI from a GitHub release.
#
# The npm package (@github/copilot) is only a loader around the same prebuilt
# binary, so the release asset is taken directly: no node needed, and the
# download lands in a cached image layer. Every release publishes SHA256SUMS.txt,
# so the download is always verified.
#
# Usage: install-copilot.sh [VERSION]
set -euo pipefail

VERSION="${1:-${COPILOT_VERSION:-latest}}"
PREFIX="${COPILOT_PREFIX:-/opt/copilot}"
BINDIR="${COPILOT_BINDIR:-/usr/local/bin}"

case "$(uname -m)" in
    x86_64 | amd64) arch='x64' ;;
    aarch64 | arm64) arch='arm64' ;;
    *)
        echo "install-copilot: unsupported architecture $(uname -m)" >&2
        exit 1
        ;;
esac

if ldd /bin/ls 2>&1 | grep -q musl; then
    asset="copilot-linuxmusl-${arch}.tar.gz"
else
    asset="copilot-linux-${arch}.tar.gz"
fi

if [ "$VERSION" = 'latest' ]; then
    base='https://github.com/github/copilot-cli/releases/latest/download'
else
    base="https://github.com/github/copilot-cli/releases/download/v${VERSION#v}"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "install-copilot: fetching ${asset} from ${base}"
curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/$asset" "${base}/${asset}"
curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/SHA256SUMS.txt" "${base}/SHA256SUMS.txt"

cd "$tmp"
grep " ${asset}\$" SHA256SUMS.txt | sha256sum -c -
cd - > /dev/null

# The tarball holds the bare `copilot` binary, with no directory of its own.
mkdir -p "$PREFIX" "$BINDIR"
tar -xzf "$tmp/$asset" -C "$PREFIX"
chmod 0755 "$PREFIX/copilot"
ln -sfn "$PREFIX/copilot" "$BINDIR/copilot"

"$BINDIR/copilot" --version
