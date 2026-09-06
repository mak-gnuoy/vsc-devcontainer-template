#!/usr/bin/env bash
# Installs the Superpowers plugin for every CLI in this image.
#
# Superpowers is not Claude-only: the repository carries a plugin manifest for
# each harness, so the same skills are installed four times over, once per CLI.
#
# This is the one installer that does not run at image build time. Plugins land
# in each CLI's config directory (~/.claude, ~/.codex, ~/.copilot, ~/.gemini),
# and every one of those is a named volume here. A volume only inherits image
# content when Docker creates it empty, so a rebuild against an existing volume
# would silently ignore whatever the image had. This runs from postCreateCommand
# instead, with the volumes already mounted.
#
# A plugin is not worth failing container creation over: every step warns and
# carries on, and the script always exits 0. Re-run it by hand after fixing
# whatever the warnings point at.
set -uo pipefail

MARKETPLACE="${SUPERPOWERS_MARKETPLACE:-obra/superpowers-marketplace}"
PLUGIN="${SUPERPOWERS_PLUGIN:-superpowers}"
REPO="${SUPERPOWERS_REPO:-https://github.com/obra/superpowers}"

failed=''

log() { echo "install-superpowers: $*"; }
warn() {
    echo "install-superpowers: $*" >&2
    failed="${failed} ${1%%:*}"
}

# Claude, Codex and Copilot all take the plugin from the same marketplace. Only
# Copilot's marketplace add reports an already-registered marketplace as an
# error, so the add is advisory everywhere and the install is what counts.
install_claude() {
    claude plugin marketplace add "$MARKETPLACE" || true
    claude plugin install "${PLUGIN}@superpowers-marketplace" --yes
}

install_codex() {
    codex plugin marketplace add "https://github.com/${MARKETPLACE}" || true
    codex plugin add "${PLUGIN}@superpowers-marketplace"
}

install_copilot() {
    copilot plugin marketplace add "$MARKETPLACE" || true
    copilot plugin install "${PLUGIN}@superpowers-marketplace"
}

# Gemini has no marketplace: extensions come straight from a git repository.
# Reinstalling one is an error rather than a no-op, so an installed extension is
# left alone — `gemini extensions update superpowers` is the way to move it on.
# --consent answers the third-party extension warning, which would otherwise
# wait forever on a stdin that postCreateCommand does not give it.
install_gemini() {
    # `gemini extensions list` prints to stderr, hence the redirect.
    if gemini extensions list 2>&1 | grep -q "^✓ ${PLUGIN} "; then
        log "gemini: ${PLUGIN} is already installed"
        return 0
    fi
    gemini extensions install "$REPO" --consent --skip-settings < /dev/null
}

for cli in claude codex copilot gemini; do
    if ! command -v "$cli" > /dev/null 2>&1; then
        log "${cli}: not on PATH, skipping"
        continue
    fi
    log "${cli}: installing ${PLUGIN}"
    "install_${cli}" || warn "${cli}: could not install ${PLUGIN}"
done

if [ -n "$failed" ]; then
    echo "install-superpowers: failed for:${failed}" >&2
    echo "install-superpowers: re-run .devcontainer/scripts/install-superpowers.sh once the cause is fixed" >&2
fi

exit 0
