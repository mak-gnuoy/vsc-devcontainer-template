#!/bin/bash
set -e

# Install CLI coding agents globally.
# Note: claude-code and copilot are installed via devcontainer "features"
# (see .devcontainer/devcontainer.json), so they are intentionally omitted here.
# Inline "#" comments must NOT appear inside the "\" continuation block below —
# the line continuation is processed before comments, so a "#" would swallow the
# rest of the command and leave `npm install -g` with no packages.
npm install -g \
    @google/gemini-cli \
    @openai/codex \
    @github/copilot \
    @anthropic-ai/claude-code 
    