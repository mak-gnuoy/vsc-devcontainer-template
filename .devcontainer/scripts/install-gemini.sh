#!/usr/bin/env bash
# Installs the Gemini CLI from a GitHub release.
#
# Unlike the other three CLIs, Gemini publishes no Linux binary: the release is a
# JavaScript bundle that runs on Node.js 20+. The bundle is unpacked into $PREFIX
# at build time and a small launcher goes on PATH, so the only thing left for
# runtime is node itself, which the node devcontainer feature provides.
#
# Usage: install-gemini.sh [VERSION]
set -euo pipefail

VERSION="${1:-${GEMINI_VERSION:-latest}}"
PREFIX="${GEMINI_PREFIX:-/opt/gemini}"
BINDIR="${GEMINI_BINDIR:-/usr/local/bin}"

if [ "$VERSION" = 'latest' ]; then
    base='https://github.com/google-gemini/gemini-cli/releases/latest/download'
else
    base="https://github.com/google-gemini/gemini-cli/releases/download/v${VERSION#v}"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "install-gemini: fetching gemini-cli-bundle.zip from ${base}"
curl -fsSL --retry 3 --retry-delay 2 -o "$tmp/bundle.zip" "${base}/gemini-cli-bundle.zip"

# The release publishes no checksums. Pass the digest of the bundle you pinned
# to verify it:
#   GEMINI_SHA256="$(sha256sum gemini-cli-bundle.zip | cut -d' ' -f1)"
if [ -n "${GEMINI_SHA256:-}" ]; then
    echo "${GEMINI_SHA256}  ${tmp}/bundle.zip" | sha256sum -c -
fi

rm -rf "$PREFIX"
mkdir -p "$PREFIX" "$BINDIR"
unzip -q "$tmp/bundle.zip" -d "$PREFIX"

# gemini.js starts with `#!/usr/bin/env node`, but the node feature puts node on
# PATH through a profile script, which not every shell reads. The launcher falls
# back to nvm's own symlink so `gemini` works from anywhere.
cat > "$BINDIR/gemini" << LAUNCHER
#!/bin/sh
if command -v node > /dev/null 2>&1; then
    exec node "${PREFIX}/gemini.js" "\$@"
fi
if [ -x /usr/local/share/nvm/current/bin/node ]; then
    exec /usr/local/share/nvm/current/bin/node "${PREFIX}/gemini.js" "\$@"
fi
echo 'gemini: node was not found on PATH. The Gemini CLI needs Node.js 20 or newer.' >&2
exit 1
LAUNCHER
chmod 0755 "$BINDIR/gemini"

# node is installed by a feature, which runs after this image is built, so the
# version check only works outside the build.
if command -v node > /dev/null 2>&1; then
    "$BINDIR/gemini" --version
else
    echo "install-gemini: installed to ${PREFIX} (node comes from the node feature)"
fi
