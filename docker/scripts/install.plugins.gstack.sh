#!/bin/bash
set -e

# Install gstack — Garry Tan's Claude Code engineering-team skill framework.
# Ref: https://github.com/garrytan/gstack
#
# gstack is NOT a Claude Code marketplace plugin. It installs by cloning the
# repo into the agent's skills directory and running its bundled ./setup, which
# auto-detects installed AI coding agents and generates per-host skill docs.
#
# Canonical install (from the gstack README):
#
#   git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git \
#       ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
#
# Team mode (shared repos) — bootstraps the repo so teammates get gstack via a
# silent once-per-hour auto-update check, then commits the config:
#
#   (cd ~/.claude/skills/gstack && ./setup --team) \
#       && ~/.claude/skills/gstack/bin/gstack-team-init required \
#       && git add .claude/ CLAUDE.md \
#       && git commit -m "require gstack for AI-assisted work"
#
# Requirements: Claude Code, Git, Bun v1.0+ (Node.js is only needed on Windows).
#
# Usage:
#   ./install.plugins.gstack.sh                    # personal install (host: claude)
#   ./install.plugins.gstack.sh --host codex       # install for another agent
#   ./install.plugins.gstack.sh --team             # team mode, gstack required
#   ./install.plugins.gstack.sh --team optional    # team mode, gstack optional

REPO_URL="https://github.com/garrytan/gstack.git"
INSTALL_DIR="${HOME}/.claude/skills/gstack"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.distro.sh
. "${SCRIPT_DIR}/lib.distro.sh"

# --- Parse args ------------------------------------------------------------
# --host <name>   pass-through to ./setup (claude|codex|kiro|factory|opencode|
#                 openclaw|hermes|gbrain|auto). Defaults to setup's own default.
# --team [level]  team mode; level is "required" (default) or "optional".
HOST=""
TEAM_MODE=0
TEAM_LEVEL="required"
while [ $# -gt 0 ]; do
    case "$1" in
        --host)
            [ -z "${2:-}" ] && { echo "ERROR: --host requires a value (e.g. claude, codex, opencode)." >&2; exit 1; }
            HOST="$2"; shift ;;
        --host=*)
            HOST="${1#--host=}" ;;
        --team)
            TEAM_MODE=1
            case "${2:-}" in
                required|optional) TEAM_LEVEL="$2"; shift ;;
            esac ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

# --- Check required tooling up front ---------------------------------------
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required but not found." >&2; exit 1; }
command -v bun >/dev/null 2>&1 || { echo "ERROR: bun (v1.0+) is required but not found. See https://bun.sh" >&2; exit 1; }

# --- Chromium OS dependencies for the /browse headless browser -------------
# ./setup installs the Chromium *binary* (bunx playwright install chromium) and
# emoji fonts, but not Chromium's shared-library OS deps. A minimal Docker image
# needs these for the browser to launch; on a full desktop they're usually present.
#
# Package names differ between Debian/Ubuntu (apt) and RHEL/Fedora/CentOS
# (dnf/yum), so detect the distro family and install the matching set. This is
# best-effort: an unrecognized distro warns and skips rather than aborting.
if ! detect_distro; then
    echo "WARNING: could not detect the Linux distribution; skipping Chromium"
    echo "         runtime dependency install. The /browse headless browser may"
    echo "         fail to launch if these shared libraries are not present." >&2
elif [ "${DISTRO_FAMILY}" = "debian" ]; then
    echo "Installing Chromium runtime dependencies (Debian/Ubuntu) for gstack browser automation."
    sudo apt-get update && sudo apt-get install -y \
        libnss3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libdrm2 \
        libxkbcommon0 \
        libgbm1 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        libxss1 \
        libasound2 \
        libpangocairo-1.0-0 \
        libpango-1.0-0 \
        libgtk-3-0 \
        libxshmfence1 \
        libdbus-1-3 \
        lsb-release \
        fonts-liberation \
        fonts-noto-color-emoji \
        libxfixes3 \
        libxi6 \
        libsm6 \
        libice6 \
        libxtst6 \
        libxcursor1 \
        libappindicator3-1 \
        && sudo rm -rf /var/lib/apt/lists/*
else
    echo "Installing Chromium runtime dependencies (RHEL/Fedora) for gstack browser automation."
    sudo "${PKG_MGR}" install -y \
        nss \
        atk \
        at-spi2-atk \
        cups-libs \
        libdrm \
        libxkbcommon \
        mesa-libgbm \
        libX11-xcb \
        libXcomposite \
        libXdamage \
        libXrandr \
        libXScrnSaver \
        alsa-lib \
        pango \
        gtk3 \
        libxshmfence \
        dbus-libs \
        liberation-fonts \
        google-noto-emoji-color-fonts \
        libXfixes \
        libXi \
        libSM \
        libICE \
        libXtst \
        libXcursor \
        libappindicator-gtk3 \
        && sudo "${PKG_MGR}" clean all
fi

# --- Clone (or update if already present — idempotent) ---------------------
if [ -d "${INSTALL_DIR}/.git" ]; then
    echo "gstack already present at ${INSTALL_DIR}; updating."
    git -C "${INSTALL_DIR}" pull --ff-only
else
    echo "Cloning gstack into ${INSTALL_DIR}."
    git clone --single-branch --depth 1 "${REPO_URL}" "${INSTALL_DIR}"
fi

# Build the ./setup argument list.
SETUP_ARGS=()
[ -n "${HOST}" ] && SETUP_ARGS+=(--host "${HOST}")

if [ "${TEAM_MODE}" -eq 1 ]; then
    # Team mode writes .claude/ + CLAUDE.md into the shared project repo, so it
    # must run from inside that repo's git work tree.
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "ERROR: --team must be run from inside the shared project's git repo." >&2
        exit 1
    }
    SETUP_ARGS+=(--team)

    echo "Running gstack setup (team mode)."
    (cd "${INSTALL_DIR}" && ./setup "${SETUP_ARGS[@]}")

    echo "Initializing gstack for the team (level: ${TEAM_LEVEL})."
    "${INSTALL_DIR}/bin/gstack-team-init" "${TEAM_LEVEL}"

    echo "Committing gstack config into the project repo."
    git add .claude/ CLAUDE.md
    git commit -m "require gstack for AI-assisted work"

    echo "gstack installed (team mode, ${TEAM_LEVEL})."
    echo "NOTE: Teammates pull this repo; a silent once-per-hour auto-update check"
    echo "      links gstack into their own ~/.claude. Start a NEW Claude Code"
    echo "      session to load the skills."
else
    echo "Running gstack setup."
    (cd "${INSTALL_DIR}" && ./setup "${SETUP_ARGS[@]}")

    echo "gstack installed."
    echo "NOTE: Add a \"gstack\" section to your CLAUDE.md (use /browse for all web"
    echo "      browsing, never mcp__claude-in-chrome__* tools) listing the available"
    echo "      skills, then start a NEW Claude Code session so they are loaded."
fi
