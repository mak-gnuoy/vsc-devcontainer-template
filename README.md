# VS Code Dev Container Template 2

A starter template for developing inside a VS Code Dev Container with multiple AI tools pre-installed, including Claude Code, OpenAI Codex, Google Gemini CLI, and MCP servers.

## Quick Start

1. Open this folder in VS Code.
2. Run **"Dev Containers: Reopen in Container"** from the Command Palette.
3. Wait for the container to build. AI tools and MCP servers are ready to use once the container starts.

## Devcontainer Configuration

The dev container is built from `docker/Dockerfile` and configured by `.devcontainer/devcontainer.json`.

### Choosing a Base Image

The Dockerfile accepts a `BASE_IMAGE` build argument so you can pick the Linux distribution your container is built on. Edit the `args.BASE_IMAGE` field in `.devcontainer/devcontainer.json`:

```jsonc
"build": {
    ...
    "args": {
        "BASE_IMAGE": "debian:stable-slim"   // ← change this
    },
    "target": "dev"
    ...
}
```

Tested base images:

| Image                 | Notes                |
| --------------------- | -------------------- |
| `debian:stable-slim`  | Default              |
| `redhat/ubi10`        | Verified to work     |
| `python:slim`         | Verified to work     |

After changing the base image, rebuild the container with **"Dev Containers: Rebuild Container"**.

### Build Targets

`target` selects a stage in the multi-stage Dockerfile:

- `dev` — development environment with AI tools and MCP servers installed (default).
- `base` — use the `BASE_IMAGE` as-is, without any additional setup.

## Pre-installed Tools

This template includes the following AI tools and MCP servers:

- **Claude Code**: Anthropic's AI coding assistant
- **OpenAI Codex**: OpenAI's code generation tool
- **Google Gemini CLI**: Google's AI assistant
- **MCP Servers**: Including Serena CLI for enhanced AI capabilities

## Environment Variables

The container loads variables from a `docker/.env` file on startup (see `runArgs` in `devcontainer.json`). Copy `docker/.env.example` to `docker/.env` before opening the container for the first time.
