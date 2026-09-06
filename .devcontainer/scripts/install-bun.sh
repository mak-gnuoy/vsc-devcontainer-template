#!/usr/bin/env bash
# Installs the bun runtime from a GitHub release.
#
# Nothing in the image wants bun for its own sake: gstack's setup refuses to run
# without it ("Error: bun is required but not installed"), and its skills execute
# through it. The release asset is taken directly rather than through
# https://bun.sh/install, which installs into $HOME for a single user and edits
# shell profiles; this puts the binary in /opt/bun and links it onto PATH so
# every user of the image gets the same bun. Every release publishes
# SHASUMS256.txt, so the download is always verified.
#
# Usage: install-bun.sh [VERSION]
set -euo pipefail

VERSION="${1:-${BUN_VERSION:-latest}}"
PREFIX="${BUN_PREFIX:-/opt/bun}"
BINDIR="${BUN_BINDIR:-/usr/local/bin}"

case "$(uname -m)" in
    x86_64 | amd64) arch='x64' ;;
    aarch64 | arm64) arch='aarch64' ;;
    *)
        echo "install-bun: unsupported architecture $(uname -m)" >&2
        exit 1
        ;;
esac

if ldd /bin/ls 2>&1 | grep -q musl; then
    arch="${arch}-musl"
fi

# The default x64 build needs AVX2 and dies with SIGILL without it. This is read
# from the CPU doing the install, which for an image is the build machine and not
# necessarily the machine that runs it; set BUN_BASELINE=1 to force the portable
# build when those differ.
baseline="${BUN_BASELINE:-}"
if [ -z "$baseline" ] && [ "${arch#x64}" != "$arch" ]; then
    if grep -qm1 ' avx2 ' /proc/cpuinfo 2> /dev/null; then baseline=0; else baseline=1; fi
fi
if [ "$baseline" = '1' ]; then
    arch="${arch}-baseline"
fi

asset="bun-linux-${arch}.zip"

if [ "$VERSION" = 'latest' ]; then
    base='https://github.com/oven-sh/bun/releases/latest/download'
else
    base="https://github.com/oven-sh/bun/releases/download/bun-v${VERSION#v}"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "install-bun: fetching ${asset} from ${base}"
curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/$asset" "${base}/${asset}"
curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/SHASUMS256.txt" "${base}/SHASUMS256.txt"

cd "$tmp"
grep " ${asset}\$" SHASUMS256.txt | sha256sum -c -
cd - > /dev/null

# The zip holds bun-linux-<arch>/bun, so -j drops the wrapping directory and the
# binary lands at $PREFIX/bun whatever the architecture was.
mkdir -p "$PREFIX" "$BINDIR"
unzip -joq "$tmp/$asset" '*/bun' -d "$PREFIX"
chmod 0755 "$PREFIX/bun"
ln -sfn "$PREFIX/bun" "$BINDIR/bun"

"$BINDIR/bun" --version
