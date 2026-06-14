#!/bin/bash
set -e

# Install the superpowers Claude Code plugin (Option B — plugin install).
# Ref: https://github.com/obra/superpowers
#
#   /plugin marketplace add obra/superpowers-marketplace
#   /plugin install superpowers@superpowers-marketplace
#
# Marketplace repo: "obra/superpowers-marketplace"
# Marketplace name: "superpowers-marketplace"
# Plugin name:      "superpowers"

MARKETPLACE_REPO="obra/superpowers-marketplace"
MARKETPLACE_NAME="superpowers-marketplace"
PLUGIN="superpowers@${MARKETPLACE_NAME}"

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

echo "superpowers installed."
echo "NOTE: Start a NEW Claude Code session — reference files aren't resolvable"
echo "      in the same session where installation happened (platform limitation)."
