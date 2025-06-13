# syntax=docker/dockerfile:1.4

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Core setup
RUN apt-get update && apt-get install -y \
    sudo \
    make \
    curl \
    git \
    iproute2 \
    iputils-ping \
    gnupg2 \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    bash-completion \
    procps \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user if needed (optional)
# RUN useradd -m dev && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev && chmod 0440 /etc/sudoers.d/dev

# Optional: Preconfigure docker CLI in DinD scenario
RUN dockerd-rootless-setuptool.sh install || true

CMD [ "sleep", "infinity" ]
