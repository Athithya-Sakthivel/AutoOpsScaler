# Base image pinned to Ubuntu 22.04
FROM ubuntu:22.04

# Set noninteractive mode for APT
ENV DEBIAN_FRONTEND=noninteractive

# Minimal install: Docker daemon, CLI, networking tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    docker.io \
    curl \
    iproute2 \
    iputils-ping \
    make \
    git \
    gh \
    bash \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt update && apt install -y sudo
# Enable Docker systemd-less (DIND v2 compatible)
VOLUME ["/var/lib/docker"]

# Start shell by default (docker daemon to be started by user/script)
CMD [ "bash" ]
