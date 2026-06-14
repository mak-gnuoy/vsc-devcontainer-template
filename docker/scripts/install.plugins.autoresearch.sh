#!/bin/bash
set -e

# Install the autoresearch Claude Code plugin (Option B — plugin install).
# Ref: https://github.com/uditgoenka/autoresearch
#
#   /plugin marketplace add uditgoenka/autoresearch
#   /plugin install autoresearch@autoresearch
#
# Marketplace repo: "uditgoenka/autoresearch"
# Marketplace name: "autoresearch"
# Plugin name:      "autoresearch"

MARKETPLACE_REPO="uditgoenka/autoresearch"
MARKETPLACE_NAME="autoresearch"
PLUGIN="autoresearch@${MARKETPLACE_NAME}"

# Register the marketplace (idempotent: skip if already configured).
if claude plugin marketplace list 2>/dev/null | grep -q "${MARKETPLACE_NAME}"; then
    echo "Marketplace '${MARKETPLACE_NAME}' already configured; updating."
    claude plugin marketplace update "${MARKETPLACE_NAME}"
else
    echo "Adding marketplace from ${MARKETPLACE_REPO}."
    claude plugin marketplace add "${MARKETPLACE_REPO}"
fi

# Install (or reinstall) the plugin at user scope.
echo "Installing plugin ${PLUGIN}."
claude plugin install "${PLUGIN}" --scope user

echo "autoresearch installed."
echo "NOTE: Start a NEW Claude Code session — reference files aren't resolvable"
echo "      in the same session where installation happened (platform limitation)."
