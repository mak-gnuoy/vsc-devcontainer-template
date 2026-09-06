#!/usr/bin/env bash
# Installs Claude Code from Anthropic's release channel.
#
# This does what https://claude.ai/install.sh does, minus the part that does not
# belong in an image: the official installer keeps the binary under $HOME and
# wires up a launcher plus shell integration for one user. Here the binary goes
# into $PREFIX and is linked onto PATH, so every user of the image gets the same
# Claude Code. Every download is checked against the release manifest's SHA-256.
#
# Usage: install-claude.sh [stable|latest|VERSION]
set -euo pipefail

VERSION="${1:-${CLAUDE_VERSION:-stable}}"
PREFIX="${CLAUDE_PREFIX:-/opt/claude}"
BINDIR="${CLAUDE_BINDIR:-/usr/local/bin}"
BASE_URL='https://downloads.claude.ai/claude-code-releases'

case "$(uname -m)" in
    x86_64 | amd64) arch='x64' ;;
    aarch64 | arm64) arch='arm64' ;;
    *)
        echo "install-claude: unsupported architecture $(uname -m)" >&2
        exit 1
        ;;
esac

if ldd /bin/ls 2>&1 | grep -q musl; then
    platform="linux-${arch}-musl"
else
    platform="linux-${arch}"
fi

# stable and latest are pointer files holding a version number; anything else is
# taken as the version itself.
case "$VERSION" in
    stable | latest) version="$(curl -fsSL --retry 3 --retry-delay 2 "${BASE_URL}/${VERSION}")" ;;
    *) version="${VERSION#v}" ;;
esac

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "install-claude: '${VERSION}' did not resolve to a version (got '${version}')" >&2
    exit 1
fi

manifest="$(curl -fsSL --retry 3 --retry-delay 2 "${BASE_URL}/${version}/manifest.json")"
checksum="$(printf '%s' "$manifest" | jq -r --arg p "$platform" '.platforms[$p].checksum // empty')"
size="$(printf '%s' "$manifest" | jq -r --arg p "$platform" '.platforms[$p].size // empty')"

if [[ ! "$checksum" =~ ^[a-f0-9]{64}$ ]]; then
    echo "install-claude: no checksum for ${platform} in the ${version} manifest" >&2
    exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The zstd-compressed binary is roughly a quarter of the download. It is an
# optimization only: if zstd is missing or the compressed copy does not verify,
# fall through to the plain binary.
echo "install-claude: fetching ${version} for ${platform}"
if command -v zstd > /dev/null 2>&1 && [[ "$size" =~ ^[1-9][0-9]*$ ]] \
    && curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/claude.zst" "${BASE_URL}/${version}/${platform}/claude.zst"; then
    zstd -d -q -c "$tmp/claude.zst" | head -c "$size" > "$tmp/claude" || true
    rm -f "$tmp/claude.zst"
fi

if ! echo "${checksum}  ${tmp}/claude" | sha256sum -c --status - 2> /dev/null; then
    curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/claude" "${BASE_URL}/${version}/${platform}/claude"
    echo "${checksum}  ${tmp}/claude" | sha256sum -c -
fi

install -D -m 0755 "$tmp/claude" "$PREFIX/claude"
mkdir -p "$BINDIR"
ln -sfn "$PREFIX/claude" "$BINDIR/claude"

"$BINDIR/claude" --version
