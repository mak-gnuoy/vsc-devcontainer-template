#!/bin/bash
set -e

# Install UV
curl -LsSf https://astral.sh/uv/install.sh | bash

# install Serena CLI
uvx --from git+https://github.com/oraios/serena serena init