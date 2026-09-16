#!/usr/bin/env bash
# Installs ccusage globally in the current npm environment.
# Run after the Node.js devcontainer feature is available.
# Usage: bash .devcontainer/scripts/install-ccusage.sh [VERSION]
set -euo pipefail

VERSION="${1:-${CCUSAGE_VERSION:-latest}}"

if ! command -v npm > /dev/null 2>&1; then
    echo 'install-ccusage: npm is required. Install Node.js and npm first.' >&2
    exit 1
fi

echo "install-ccusage: installing ccusage@${VERSION}"
npm install --global "ccusage@${VERSION}"

# Use the executable from this npm prefix, even if PATH contains an older copy.
# This also initializes native executable permissions while the install location
# is writable. Usage reports require local agent data, so do not run them here.
BINDIR="$(npm prefix --global)/bin"
"$BINDIR/ccusage" --version

if ! command -v ccusage > /dev/null 2>&1 || ! [ "$(command -v ccusage)" -ef "$BINDIR/ccusage" ]; then
    echo "install-ccusage: add ${BINDIR} to the front of PATH to use this installation."
fi
