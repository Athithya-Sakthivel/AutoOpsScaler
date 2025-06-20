#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "[lc.sh] === Starting dev cluster setup ==="

# Check Docker
if ! command -v docker &>/dev/null; then
  echo >&2 "[lc.sh] ERROR: Docker is not installed or not in PATH"
  exit 1
fi
echo "[lc.sh] Docker is OK"

# Install k3d if missing
if ! command -v k3d &>/dev/null; then
  echo "[lc.sh] Installing k3d v5.4.8..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.4.8 bash
else
  echo "[lc.sh] k3d already installed: $(k3d version)"
fi

# Cleanup existing cluster
if k3d cluster list | grep -q 'autoopsscaler-dev'; then
  echo "[lc.sh] Removing existing cluster 'autoopsscaler-dev'..."
  k3d cluster delete autoopsscaler-dev || true
fi

# Create local registry if not exists
REGISTRY_NAME="k3d-autoopsscaler-dev-registry"
if ! docker inspect "$REGISTRY_NAME" &>/dev/null; then
  echo "[lc.sh] Creating registry '$REGISTRY_NAME' on port 5000..."
  k3d registry create "$REGISTRY_NAME" --port 5000
else
  echo "[lc.sh] Registry '$REGISTRY_NAME' already exists"
fi
echo "[lc.sh] Registry ready"

# Create cluster with 1 server and 1 agent
echo "[lc.sh] Creating cluster 'autoopsscaler-dev' with 1 server + 1 agent..."
k3d cluster create autoopsscaler-dev \
  --agents 1 \
  --servers 1 \
  --registry-use "$REGISTRY_NAME:5000" \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer"

echo "[lc.sh] Cluster created"

# Final check
if ! kubectl cluster-info &>/dev/null; then
  echo >&2 "[lc.sh] ERROR: kubectl cannot access the cluster context!"
  exit 1
fi

echo "[lc.sh] Dev cluster ready with 1 master + 1 worker"
