FROM debian:trixie-slim

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# The slim Debian image ships almost nothing. ca-certificates, curl, gnupg and
# xz-utils are what the node and github-cli features need to fetch and unpack
# their downloads over HTTPS; jq and zstd are what scripts/install-claude.sh needs to
# read the release manifest and unpack the compressed binary. The rest are the
# everyday tools a devcontainer is expected to have, and sudo backs the
# passwordless rule below.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg \
        xz-utils \
        unzip \
        git \
        openssh-client \
        sudo \
        less \
        procps \
        jq \
        zstd \
        ripgrep \
        locales \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/*

# Claude Code draws box characters, so give the container a UTF-8 locale rather
# than the default POSIX one.
RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8

# Claude Code refuses --dangerously-skip-permissions when run as root, and the
# devcontainer connects as remoteUser, so the image needs a non-root account.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID --create-home --shell /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# The CLIs are installed here rather than with npm at container-create time: the
# downloads land in cached image layers instead of repeating on every rebuild,
# and only Gemini, which ships no Linux binary, still needs the node toolchain
# the features add later.

# stable is the release channel Anthropic recommends; latest and an exact version
# (e.g. 2.1.236) also work. Downloads are always checksummed against the release
# manifest, so there is no hash to pin here.
ARG CLAUDE_VERSION=stable
COPY scripts/install-claude.sh /tmp/install-claude.sh
RUN bash /tmp/install-claude.sh "$CLAUDE_VERSION" && rm /tmp/install-claude.sh

# The default is the latest Codex release; set the build arg to a version
# (e.g. 0.153.4) for a reproducible image, and CODEX_SHA256 to verify the
# download.
ARG CODEX_VERSION=latest
ARG CODEX_SHA256=
COPY scripts/install-codex.sh /tmp/install-codex.sh
RUN bash /tmp/install-codex.sh "$CODEX_VERSION" && rm /tmp/install-codex.sh

# Gemini publishes no checksums, so GEMINI_SHA256 is there to verify a pinned
# bundle. Copilot publishes SHA256SUMS.txt with every release and is always
# verified.
ARG GEMINI_VERSION=latest
ARG GEMINI_SHA256=
COPY scripts/install-gemini.sh /tmp/install-gemini.sh
RUN bash /tmp/install-gemini.sh "$GEMINI_VERSION" && rm /tmp/install-gemini.sh

ARG COPILOT_VERSION=latest
COPY scripts/install-copilot.sh /tmp/install-copilot.sh
RUN bash /tmp/install-copilot.sh "$COPILOT_VERSION" && rm /tmp/install-copilot.sh

# gstack's setup refuses to run without bun, and its skills execute through it.
# The default is the latest release; set the build arg to a version (e.g. 1.4.2)
# to pin one. Downloads are always verified against the release SHASUMS256.txt.
# On a build machine whose CPU has AVX2 but a runtime one that does not, pass
# BUN_BASELINE=1 for the portable build.
ARG BUN_VERSION=latest
ARG BUN_BASELINE=
COPY scripts/install-bun.sh /tmp/install-bun.sh
RUN bash /tmp/install-bun.sh "$BUN_VERSION" && rm /tmp/install-bun.sh

# Create the named-volume mount targets here so Docker initializes each volume
# with this ownership. A volume mounted onto a path that does not exist in the
# image is created root-owned, which leaves the CLIs unable to write their config
# as the vscode user.
RUN mkdir -p /home/$USERNAME/.claude /home/$USERNAME/.codex \
        /home/$USERNAME/.gemini /home/$USERNAME/.copilot /home/$USERNAME/.gstack \
        /commandhistory \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.claude /home/$USERNAME/.codex \
        /home/$USERNAME/.gemini /home/$USERNAME/.copilot /home/$USERNAME/.gstack \
        /commandhistory
