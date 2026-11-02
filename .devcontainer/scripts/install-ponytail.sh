#!/usr/bin/env bash
# Installs the Ponytail plugin for every CLI in this image.
#
# Ponytail is laid out like Superpowers: the repository carries a plugin
# manifest for each harness, and Claude, Codex and Copilot take it from the same
# marketplace while Gemini installs it straight from git. The functions below
# follow install-superpowers.sh one for one; the comments there explain why
# each CLI is driven the way it is.
#
# For the same reason as Superpowers, this runs from postCreateCommand rather
# than at image build time: plugins land in the CLI config directories, which
# are named volumes. And like that script, no plugin is worth failing container
# creation over: every step warns and carries on, and the script always exits 0.
#
# The Claude and Codex plugins run Node.js lifecycle hooks, which the node
# feature puts on PATH. Codex will not run them until they are trusted, and
# that is an interactive step: open `/hooks` in codex once after this runs.
set -uo pipefail

MARKETPLACE="${PONYTAIL_MARKETPLACE:-DietrichGebert/ponytail}"
PLUGIN="${PONYTAIL_PLUGIN:-ponytail}"
REPO="${PONYTAIL_REPO:-https://github.com/DietrichGebert/ponytail}"

failed=''

log() { echo "install-ponytail: $*"; }
warn() {
    echo "install-ponytail: $*" >&2
    failed="${failed} ${1%%:*}"
}

install_claude() {
    claude plugin marketplace add "$MARKETPLACE" || true
    claude plugin install "${PLUGIN}@ponytail" --yes
}

install_codex() {
    codex plugin marketplace add "https://github.com/${MARKETPLACE}" || true
    codex plugin add "${PLUGIN}@ponytail"
}

install_copilot() {
    copilot plugin marketplace add "$MARKETPLACE" || true
    copilot plugin install "${PLUGIN}@ponytail"
}

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
    echo "install-ponytail: failed for:${failed}" >&2
    echo "install-ponytail: re-run .devcontainer/scripts/install-ponytail.sh once the cause is fixed" >&2
fi

exit 0
