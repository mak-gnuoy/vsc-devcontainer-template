# Project Template

A starter template for developing inside a VS Code Dev Container with Claude Code pre-installed.

## Quick Start

1. Open this folder in VS Code.
2. Run **"Dev Containers: Reopen in Container"** from the Command Palette.
3. Wait for the container to build. Claude Code is ready to use once the container starts.

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
    "target": "dev-with-claude"
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

- `dev-with-claude` — development environment with Claude Code installed (default).
- `base` — use the `BASE_IMAGE` as-is, without any additional setup.

## Environment Variables

The container loads variables from a `.env` file at the project root on startup (see `runArgs` in `devcontainer.json`). Copy `.env.example` to `.env` before opening the container for the first time.
