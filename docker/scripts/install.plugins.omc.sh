#!/bin/bash
set -e

# Install the oh-my-claudecode (OMC) Claude Code plugin.
# Marketplace name: "omc" (from Yeachan-Heo/oh-my-claudecode)
# Plugin name:      "oh-my-claudecode"

MARKETPLACE_REPO="Yeachan-Heo/oh-my-claudecode"
MARKETPLACE_NAME="omc"
PLUGIN="oh-my-claudecode@${MARKETPLACE_NAME}"

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

echo "oh-my-claudecode installed."
