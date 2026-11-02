#!/usr/bin/env bash
# Installs the graphify CLI and its skill for every CLI in this image.
#
# graphify is not a plugin: it is a Python CLI (published on PyPI as graphifyy,
# with two y's) whose `graphify install --platform <host>` copies a SKILL.md
# into each host's user skill directory. The skill drives the CLI, so both are
# needed.
#
# The CLI goes in with pipx, which the python feature configures to install
# into /usr/local/py-utils, already on PATH. That is image filesystem, not a
# volume, so it is gone after a rebuild; this script runs from
# postCreateCommand and puts it back. The skills land in ~/.claude, ~/.codex,
# ~/.copilot and ~/.gemini, which are volumes, and are refreshed on every run so
# they match the CLI version.
#
# Like the other skill installers, nothing here is worth failing container
# creation over: every step warns and carries on, and the script always exits 0.
#
# Only the user-level skill is installed. graphify's always-on mode (the
# CLAUDE.md/AGENTS.md/GEMINI.md section and the PreToolUse hooks that steer the
# agent to the graph) is written into a project, by `graphify claude install`
# and friends run from that project, so it is a per-repository choice and not
# something an image can make for you.
set -uo pipefail

VERSION="${1:-${GRAPHIFY_VERSION:-latest}}"
PACKAGE="${GRAPHIFY_PACKAGE:-graphifyy}"

failed=''

log() { echo "install-graphify: $*"; }
warn() {
    echo "install-graphify: $*" >&2
    failed="${failed} ${1%%:*}"
}

if ! command -v pipx > /dev/null 2>&1; then
    echo 'install-graphify: pipx is not on PATH, skipping' >&2
    echo 'install-graphify: pipx comes from the python feature in devcontainer.json' >&2
    exit 0
fi

spec="$PACKAGE"
[ "$VERSION" = 'latest' ] || spec="${PACKAGE}==${VERSION}"

# --force makes a re-run move an existing install to VERSION instead of
# stopping at "already installed".
log "installing ${spec} with pipx"
if ! pipx install --force "$spec"; then
    echo "install-graphify: could not install ${spec}, skipping the skills" >&2
    exit 0
fi

# The hooks graphify writes call the CLI by the absolute path it resolves at
# install time, so make sure that is the pipx copy and not something earlier on
# PATH.
GRAPHIFY="${PIPX_BIN_DIR:-$HOME/.local/bin}/graphify"
"$GRAPHIFY" --version || warn "graphify: ${GRAPHIFY} does not run"

# A global Gemini install still writes GEMINI.md and .gemini/settings.json into
# the current directory, as if it were a project install. Running from a
# scratch directory keeps those out of the workspace and $HOME; the skill itself
# goes to ~/.gemini/skills regardless. The other hosts write nothing relative.
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

for cli in claude codex copilot gemini; do
    if ! command -v "$cli" > /dev/null 2>&1; then
        log "${cli}: not on PATH, skipping"
        continue
    fi
    log "${cli}: installing the graphify skill"
    (cd "$scratch" && "$GRAPHIFY" install --platform "$cli" < /dev/null) \
        || warn "${cli}: could not install the graphify skill"
done

if [ -n "$failed" ]; then
    echo "install-graphify: failed for:${failed}" >&2
    echo 'install-graphify: re-run .devcontainer/scripts/install-graphify.sh once the cause is fixed' >&2
fi

exit 0
