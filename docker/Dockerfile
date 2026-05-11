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
RUN ./docker/install.deps.dev.sh 

ARG USERNAME=appuser
ENV HOME=/home/${USERNAME}

RUN ./docker/create.user.sh ${USERNAME} /app
USER ${USERNAME}
ENV PATH="${HOME}/.local/bin:${PATH}"

RUN ./docker/install.mcps.sh

# -------------------------------
# Production Image
FROM base AS prod

# COPY . /app
# WORKDIR /app

# ARG USERNAME=appuser
# ENV HOME=/home/${USERNAME}

# RUN ./docker/create.user.sh ${USERNAME} /app
# USER ${USERNAME}
# ENV PATH="${HOME}/.local/bin:${PATH}"