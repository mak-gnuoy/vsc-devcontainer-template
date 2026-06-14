#!/bin/bash
set -e

# Install the github MCP server at USER scope so it is available across all
# projects for this user (not just inside a repo that ships a .mcp.json).
# Ref: https://github.com/github/github-mcp-server
#
# This is an HTTP (remote) MCP server, not a local stdio subprocess, so it is
# registered with --transport http and a URL rather than a command. User-scope
# registration writes to ~/.claude.json (the user's MCP config), unlike a
# project's committed .mcp.json which only applies within that repo.
#
# Equivalent manual command:
#   claude mcp add github --scope user --transport http https://api.githubcopilot.com/mcp
#
# Usage:
#   ./install.mcp.github.sh

SERVER_NAME="github"
SERVER_URL="https://api.githubcopilot.com/mcp"

# --- Check required tooling up front ---------------------------------------
command -v claude >/dev/null 2>&1 || { echo "ERROR: the 'claude' CLI is required but not found." >&2; exit 1; }

# --- Register at user scope (idempotent) -----------------------------------
# Remove any existing user-scope entry first so re-running this script updates
# the definition cleanly instead of erroring on a duplicate name.
if claude mcp get "${SERVER_NAME}" >/dev/null 2>&1; then
    echo "Removing existing '${SERVER_NAME}' MCP registration before re-adding."
    claude mcp remove "${SERVER_NAME}" --scope user >/dev/null 2>&1 || true
fi

echo "Adding '${SERVER_NAME}' MCP server at user scope."
claude mcp add "${SERVER_NAME}" --scope user --transport http "${SERVER_URL}"

echo "'${SERVER_NAME}' installed at user scope."
echo "NOTE: This server requires authentication. Start a NEW Claude Code session,"
echo "      then run '/mcp' (or 'claude mcp get ${SERVER_NAME}') to authenticate."
