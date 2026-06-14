#!/bin/bash
set -e

# Install the playwright MCP server at USER scope so it is available across all
# projects for this user (not just inside a repo that ships a .mcp.json).
# Ref: https://github.com/microsoft/playwright-mcp
#
# User-scope registration writes to ~/.claude.json (the user's MCP config),
# unlike a project's committed .mcp.json which only applies within that repo
# and requires per-project trust approval.
#
# Equivalent manual command:
#   claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest
#
# Usage:
#   ./install.mcp.playwright.sh

SERVER_NAME="playwright"
PACKAGE="@playwright/mcp@latest"

# --- Check required tooling up front ---------------------------------------
command -v claude >/dev/null 2>&1 || { echo "ERROR: the 'claude' CLI is required but not found." >&2; exit 1; }
command -v npx    >/dev/null 2>&1 || { echo "ERROR: 'npx' (Node.js) is required but not found." >&2; exit 1; }

# --- Register at user scope (idempotent) -----------------------------------
# Remove any existing user-scope entry first so re-running this script updates
# the definition cleanly instead of erroring on a duplicate name.
if claude mcp get "${SERVER_NAME}" >/dev/null 2>&1; then
    echo "Removing existing '${SERVER_NAME}' MCP registration before re-adding."
    claude mcp remove "${SERVER_NAME}" --scope user >/dev/null 2>&1 || true
fi

echo "Adding '${SERVER_NAME}' MCP server at user scope."
claude mcp add "${SERVER_NAME}" --scope user -- npx -y "${PACKAGE}"

echo "'${SERVER_NAME}' installed at user scope."
echo "NOTE: Start a NEW Claude Code session to load the server, then verify with:"
echo "      claude mcp get ${SERVER_NAME}"
