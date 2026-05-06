#!/bin/bash
set -e

# Create project subdirectories at the devcontainer workspace mount path.
# Must be run after the workspace is mounted (e.g. devcontainer postCreateCommand),
# not at Docker build time — the mount would otherwise hide them.
WORKSPACE_DIR="${1:-${CONTAINER_WORKSPACE_FOLDER:-$PWD}}"
mkdir -p "$WORKSPACE_DIR/src"
mkdir -p "$WORKSPACE_DIR/docs"
mkdir -p "$WORKSPACE_DIR/tests"