#!/bin/bash
set -e

# Add ${HOME}/.local/bin to PATH
export PATH="${HOME}/.local/bin:$PATH"

# Install UV
curl -LsSf https://astral.sh/uv/install.sh | bash

# install Serena CLI
uvx --from git+https://github.com/oraios/serena serena init