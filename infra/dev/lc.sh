#!/usr/bin/env bash

set -euo pipefail

K3D_VERSION="v5.4.8"
CLUSTER_NAME="autoopsscaler-dev"
REGISTRY_NAME="k3d-${CLUSTER_NAME}-registry"
REGISTRY_PORT="5000"

log() {
  echo "[lc.sh] $1"
}

ensure_k3d_installed() {
  if ! command -v k3d >/dev/null 2>&1; then
    log "k3d not found. Installing version ${K3D_VERSION}..."
    curl -sSfL "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64" -o /usr/local/bin/k3d
    chmod +x /usr/local/bin/k3d
    log "Installed k3d: $(k3d version)"
  else
    log "k3d already installed: $(k3d version)"
  fi
}

create_registry() {
  if k3d registry list | grep -q "^${REGISTRY_NAME}\b"; then
    log "Registry ${REGISTRY_NAME} already exists. Skipping creation."
  else
    log "Creating registry ${REGISTRY_NAME} on port ${REGISTRY_PORT}..."
    k3d registry create "${REGISTRY_NAME}" --port "${REGISTRY_PORT}"
  fi
}

create_cluster() {
  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
    log "Cluster ${CLUSTER_NAME} already exists. Skipping creation."
  else
    log "Creating cluster ${CLUSTER_NAME} with registry integration..."
    k3d cluster create "${CLUSTER_NAME}" \
      --registry-use "${REGISTRY_NAME}:${REGISTRY_PORT}" \
      --port "80:80@loadbalancer" \
      --port "443:443@loadbalancer"
    log "Cluster ${CLUSTER_NAME} created successfully."
  fi
}

main() {
  log "Starting cluster setup..."
  ensure_k3d_installed
  create_registry
  create_cluster
  log "Cluster setup complete."
}

main
