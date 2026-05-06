#!/bin/bash
set -e

# Add ${HOME}/.local/bin to PATH
export PATH="${HOME}/.local/bin:$PATH"

# Install Claude CLI
curl -fsSL https://claude.ai/install.sh | bash
