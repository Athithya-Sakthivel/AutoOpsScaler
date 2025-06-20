#!/usr/bin/env bash

set -euo pipefail

K3D_VERSION="v5.4.8"
CLUSTER_NAME="autoopsscaler-dev"
REGISTRY_NAME="k3d-${CLUSTER_NAME}-registry"
REGISTRY_PORT="5000"

log() {
  echo "[lc.sh] $1"
}

prompt_worker_nodes() {
  local default_nodes=2
  read -rp "[lc.sh] Enter number of worker nodes [default: ${default_nodes}]: " WORKER_NODES
  if [[ -z "${WORKER_NODES}" ]]; then
    WORKER_NODES=${default_nodes}
  fi
  if ! [[ "$WORKER_NODES" =~ ^[0-9]+$ ]]; then
    echo "[lc.sh] Invalid input. Please enter a numeric value."
    exit 1
  fi
}

ensure_k3d_installed() {
  if ! command -v k3d >/dev/null 2>&1; then
    log "k3d not found. Installing version ${K3D_VERSION}..."
    TMP_BIN="/tmp/k3d"
    curl -sSfL "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64" -o "${TMP_BIN}"
    chmod +x "${TMP_BIN}"
    sudo mv "${TMP_BIN}" /usr/local/bin/k3d
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
    log "Registry created."
  fi
}

create_cluster() {
  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
    log "Cluster ${CLUSTER_NAME} already exists. Skipping creation."
  else
    log "Creating cluster ${CLUSTER_NAME} with ${WORKER_NODES} worker node(s)..."
    k3d cluster create "${CLUSTER_NAME}" \
      --agents "${WORKER_NODES}" \
      --registry-use "${REGISTRY_NAME}:${REGISTRY_PORT}" \
      --port "80:80@loadbalancer" \
      --port "443:443@loadbalancer"
    log "Cluster ${CLUSTER_NAME} created successfully."
  fi
}

main() {
  log "Starting cluster setup..."
  prompt_worker_nodes
  ensure_k3d_installed
  create_registry
  create_cluster
  log "Cluster setup complete."
}

main
