# syntax=docker/dockerfile:1

ARG VARIANT=ubuntu-22.04
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools (extend here)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    lsb-release \
    sudo \
    software-properties-common \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# [Optional] Set up Python (already in your devcontainer host)
RUN sudo apt-get update && sudo apt-get install -y python3 python3-pip tree gh make

# Ensure workspace ownership and default shell
USER vscode
SHELL ["/bin/bash", "-c"]
