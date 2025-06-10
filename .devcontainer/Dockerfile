# filepath: [Dockerfile](http://_vscodecontentref_/0)
# syntax=docker/dockerfile:1

ARG VARIANT=ubuntu-22.04
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    lsb-release \
    sudo \
    software-properties-common \
    build-essential \
    python3 \
    python3-pip \
    tree \
    gh \
    make \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure the vscode user exists and owns the home directory
ARG USERNAME=vscode
RUN if ! id -u $USERNAME >/dev/null 2>&1; then useradd -m $USERNAME; fi \
    && chown -R $USERNAME /home/$USERNAME

# Set root as the default user
USER root
SHELL ["/bin/bash", "-c"]