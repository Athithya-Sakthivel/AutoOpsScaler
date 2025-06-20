#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="autoopsscaler-dev"
REGISTRY_NAME="k3d-${CLUSTER_NAME}-registry"

log() {
  echo "[status.sh] $1"
}

show_k3d_version() {
  if command -v k3d >/dev/null 2>&1; then
    log "k3d version: $(k3d version)"
  else
    log "k3d is not installed."
  fi
}

show_cluster_status() {
  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
    log "Cluster '${CLUSTER_NAME}' exists."
    k3d cluster list "${CLUSTER_NAME}"
    log "kubectl cluster-info:"
    kubectl cluster-info || log "kubectl cannot connect to the cluster."
  else
    log "Cluster '${CLUSTER_NAME}' does not exist."
  fi
}

show_registry_status() {
  if k3d registry list | grep -q "^${REGISTRY_NAME}\b"; then
    log "Registry '${REGISTRY_NAME}' exists."
    k3d registry list "${REGISTRY_NAME}"
  else
    log "Registry '${REGISTRY_NAME}' does not exist."
  fi
}

show_ports_in_use() {
  log "Docker containers using port 5000 (if any):"
  docker ps --filter "publish=5000" --format "table {{.Names}}\t{{.Ports}}" || true
}

main() {
  show_k3d_version
  show_cluster_status
  show_registry_status
  show_ports_in_use
}

main
