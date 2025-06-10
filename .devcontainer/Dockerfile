# .devcontainer/Dockerfile

# Pin to Ubuntu 22.04 base
FROM ubuntu:22.04

# Noninteractive APT
ENV DEBIAN_FRONTEND=noninteractive

# Create user vscode with UID/GID=1000
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    curl \
    git \
    tree \
    make \
    bash \
    docker.io \
    iproute2 \
    iputils-ping \
    ca-certificates \
    gnupg2 \
    gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create vscode user and give sudo rights
RUN useradd -m vscode && echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Volume for Docker-in-Docker
VOLUME ["/var/lib/docker"]

# Default user
USER vscode

# Default shell
CMD ["bash"]
