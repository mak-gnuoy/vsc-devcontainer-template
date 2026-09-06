#!/usr/bin/env bash
# Installs the gstack skills for the CLIs in this image that support it.
#
# gstack is not a plugin: the repository is cloned once and its `setup` script
# links the skills into each host's config directory. The clone therefore lives
# where upstream puts it, ~/.claude/skills/gstack, which is a named volume here
# — the 42MB download survives a rebuild, and `git pull` still updates it. The
# Codex install is a set of links in ~/.codex/skills pointing back at that
# clone, and both volumes persist, so the links do not dangle.
#
# Like install-superpowers.sh, this runs from postCreateCommand rather than at
# image build time, because a volume only inherits image content when Docker
# creates it empty. And like that script, no skill is worth failing container
# creation over: every step warns and carries on, and the script always exits 0.
#
# Only Claude Code and Codex are installed. gstack supports Cursor, Factory,
# Kiro and OpenCode too, none of which are in this image, and it has no install
# for Gemini or Copilot — those get only the instruction-only digest in
# agents-digest/gstack-AGENTS.md, which is a per-project copy-paste and not
# something an image can do for you.
set -uo pipefail

REPO="${GSTACK_REPO:-https://github.com/garrytan/gstack.git}"
REF="${GSTACK_REF:-main}"
SRC="${GSTACK_DIR:-$HOME/.claude/skills/gstack}"

# Chromium is not installed. Playwright would put it in ~/.cache/ms-playwright,
# which is not one of the named volumes, so every rebuild would download 200MB
# again, and debian-slim has none of the shared libraries a headless Chromium
# needs anyway. The browser skills error out when invoked; everything else works.
export GSTACK_SKIP_PLAYWRIGHT=1

# setup also apt-installs fonts-noto-color-emoji so that make-pdf renders emoji.
# make-pdf prints through Chromium, which is not here, so the font would be an
# apt call on every container create for a skill that cannot run.
export GSTACK_SKIP_FONTS=1

failed=''

log() { echo "install-gstack: $*"; }
warn() {
    echo "install-gstack: $*" >&2
    failed="${failed} ${1%%:*}"
}

if ! command -v bun > /dev/null 2>&1; then
    echo 'install-gstack: bun is not on PATH and gstack setup requires it, skipping' >&2
    echo 'install-gstack: the image installs bun from the Dockerfile via scripts/install-bun.sh' >&2
    exit 0
fi

# Fetching REF explicitly rather than cloning it lets it be a commit SHA as well
# as a branch — upstream publishes no tags, so a SHA is the only way to pin a
# version. The default leaves HEAD on main, where `git pull` keeps working.
# The clone belongs to this script: local edits under it do not survive a reset.
if [ ! -d "$SRC/.git" ]; then
    log "cloning ${REPO} into ${SRC}"
    mkdir -p "$(dirname "$SRC")"
    if ! git clone --single-branch --depth 1 "$REPO" "$SRC"; then
        echo "install-gstack: could not clone ${REPO}, skipping" >&2
        exit 0
    fi
fi

log "updating ${SRC} to ${REF}"
if git -C "$SRC" fetch --depth 1 origin "$REF"; then
    git -C "$SRC" reset --hard FETCH_HEAD || warn "git: could not check out ${REF}"
else
    warn "git: could not fetch ${REF}, using the checkout as it is"
fi

# --no-prefix installs the skills under their short names (/review, /ship,
# /qa) instead of namespacing them as gstack-*. Superpowers shares these
# config directories but its skills are plugin-namespaced (superpowers:*), so
# the short names do not collide with it. They can still shadow, or be
# shadowed by, a host's built-in commands and any project skill of the same
# name — setup warns about the collisions it finds. Switching back is
# --prefix, and setup cleans up the links from the mode it is leaving.
#
# The flag only reaches the Claude install. Codex is linked from the
# pre-generated .agents/skills/gstack-* directories in the clone, whose names
# carry the prefix upstream, so Codex keeps /gstack-review either way. Under
# Claude the same is true of the two skills whose own names start with gstack-
# (the gstack router and gstack-upgrade).
#
# Switching modes in a container that already ran the other one can leave a
# stale copy behind: setup's cleanup only removes symlinks, and a few skills
# are installed as generated files instead. They are marked with a
# .gstack-owned file, so `rm -rf ~/.claude/skills/gstack-<name>` is safe. A
# fresh container never hits this — it only installs one mode.
#
# setup reads its prompts from /dev/tty with a timeout, so postCreateCommand
# does not hang on them, but every prompt it does not need to ask is a prompt
# that cannot time out; --no-prefix and -q answer the ones that matter.
for host in claude codex; do
    if ! command -v "$host" > /dev/null 2>&1; then
        log "${host}: not on PATH, skipping"
        continue
    fi
    log "${host}: installing gstack skills"
    (cd "$SRC" && ./setup --host "$host" --no-prefix -q < /dev/null) \
        || warn "${host}: gstack setup failed"
done

# Telemetry ships on and posts skill usage to gstack's Supabase. This is a team
# image, so it is turned off unless someone asks for it back.
if [ "${GSTACK_TELEMETRY:-off}" = 'off' ]; then
    log 'disabling telemetry (GSTACK_TELEMETRY=on keeps the upstream default)'
    "$SRC/bin/gstack-config" set telemetry off > /dev/null \
        || warn 'config: could not disable telemetry'
fi

if [ -n "$failed" ]; then
    echo "install-gstack: failed for:${failed}" >&2
    echo 'install-gstack: re-run .devcontainer/scripts/install-gstack.sh once the cause is fixed' >&2
fi

exit 0
