# -------------------------------
# Base Image
ARG BASE_IMAGE=debian:stable-slim
FROM ${BASE_IMAGE} AS base

# -------------------------------
# Development Image
FROM base AS dev

COPY . /app
WORKDIR /app

# Install dependencies
RUN ./docker/scripts/install.deps.dev.sh 

ARG USERNAME=appuser
ENV HOME=/home/${USERNAME}

RUN ./docker/scripts/create.user.sh ${USERNAME} /app

# Grant passwordless sudo (user is created with --disabled-password)
RUN usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
ENV PATH="${HOME}/.local/bin:${PATH}"

RUN sudo ./docker/scripts/install.coding.agents.sh && \
    # ./docker/scripts/install.mcps.sh && \
    # ./docker/scripts/create.project.structure.sh && \
    ./docker/scripts/install.plugins.sh gstack && \
    ./docker/scripts/install.plugins.superpowers.sh 

# -------------------------------
# Production Image
FROM base AS prod

# COPY . /app
# WORKDIR /app

# ARG USERNAME=appuser
# ENV HOME=/home/${USERNAME}

# RUN ./docker/scripts/create.user.sh ${USERNAME} /app
# USER ${USERNAME}
# ENV PATH="${HOME}/.local/bin:${PATH}"