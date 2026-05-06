# -------------------------------
# Base Image
ARG BASE_IMAGE=debian:stable-slim
FROM ${BASE_IMAGE} AS base

# -------------------------------
# Development Image with Claude
FROM base AS dev-with-claude

COPY . /app
WORKDIR /app

# Install dependencies
RUN ./docker/install.deps.for.dev-with-claude.sh

RUN ./docker/create.appuser.sh appuser
USER appuser

RUN ./docker/install.claude.sh \
    && ./docker/install.mcps.sh
