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
RUN ./docker/install.deps.sh

RUN ./docker/create.appuser.sh appuser /app
USER appuser

RUN ./docker/install.claude.sh \
    && ./docker/install.mcps.sh
