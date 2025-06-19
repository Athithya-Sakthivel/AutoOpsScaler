#!/bin/bash
# infra/dev/install-k3d.sh
# Idempotent script to install stable k3d (v5.4.8) on Ubuntu 22.04

set -euo pipefail

K3D_VERSION="v5.4.8"
INSTALL_PATH="/usr/local/bin/k3d"

echo "Checking if k3d is installed..."

if command -v k3d &>/dev/null; then
    INSTALLED_VERSION=$(k3d version --short | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
    if [[ "$INSTALLED_VERSION" == "$K3D_VERSION" ]]; then
        echo "k3d $K3D_VERSION is already installed. Skipping installation."
        exit 0
    else
        echo "Different k3d version detected: $INSTALLED_VERSION. Reinstalling $K3D_VERSION..."
    fi
else
    echo "k3d not found. Installing version $K3D_VERSION..."
fi

# Download k3d binary
curl -Lo /tmp/k3d https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64

# Validate download
if [[ ! -s /tmp/k3d ]]; then
    echo "Failed to download k3d binary." >&2
    exit 1
fi

# Install binary
chmod +x /tmp/k3d
sudo mv /tmp/k3d $INSTALL_PATH

# Verify installation
if ! command -v k3d &>/dev/null; then
    echo "k3d installation failed." >&2
    exit 1
fi

INSTALLED_VERSION=$(k3d version --short | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
if [[ "$INSTALLED_VERSION" != "$K3D_VERSION" ]]; then
    echo "Installed k3d version ($INSTALLED_VERSION) does not match expected ($K3D_VERSION)." >&2
    exit 1
fi

echo "k3d $K3D_VERSION installed successfully."
