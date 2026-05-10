#!/bin/bash
set -e

# Install Claude CLI
curl -fsSL https://claude.ai/install.sh | bash

# Add ${HOME}/.local/bin to PATH
echo 'export PATH=""${HOME}/.local/bin:$PATH"' >> ~/.bashrc
