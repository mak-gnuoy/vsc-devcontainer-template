#!/bin/bash
set -e

# Wrapper that installs every MCP server at USER scope by running each
# per-server install.mcp.<name>.sh script in turn.
#
# Each server is installed independently: if one fails (e.g. a missing runtime
# or a network hiccup), the remaining servers still install and the failure is
# reported in a summary. The script exits non-zero if any server failed.
#
# Usage:
#   ./install.mcps.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SERVERS=(
    context7
    sequential-thinking
    serena
    # github
    # playwright
)

failed=()
for name in "${SERVERS[@]}"; do
    echo "=== Installing MCP server: ${name} ==="
    if "${SCRIPT_DIR}/install.mcp.${name}.sh"; then
        echo
    else
        echo "WARNING: failed to install MCP server '${name}'." >&2
        failed+=("${name}")
        echo
    fi
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "Done with errors. Failed servers: ${failed[*]}" >&2
    exit 1
fi

echo "All MCP servers installed at user scope: ${SERVERS[*]}"
