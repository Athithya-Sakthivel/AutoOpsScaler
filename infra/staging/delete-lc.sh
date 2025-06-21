#!/usr/bin/env bash

CLUSTER_NAME="autoopsscaler-staging"
REGISTRY_NAME="k3d-${CLUSTER_NAME}-registry"
REGISTRY_PORT="5000"
REGISTRY_CONTAINER_NAME_PREFIX="k3d-${REGISTRY_NAME}"
NETWORK_NAME="k3d-${CLUSTER_NAME}"
K3D_BIN="/usr/local/bin/k3d"

log() {
  echo "[delete-lc.sh] $1"
}

delete_cluster_and_registry() {
  log "Attempting to delete k3d clusters and registries..."
  k3d cluster list --no-headers | awk '{print $1}' | xargs -r -n1 k3d cluster delete || true
  k3d registry list --no-headers | awk '{print $1}' | xargs -r -n1 k3d registry delete || true
}

delete_k3d_containers() {
  log "Removing all Docker containers related to k3d..."
  docker ps -a --filter "name=k3d-" --format '{{.ID}}' | xargs -r docker rm -f || true
}

delete_port_bound_registry() {
  log "Checking for containers bound to port ${REGISTRY_PORT}..."
  docker ps -q --filter "publish=${REGISTRY_PORT}" | xargs -r docker rm -f || true
}

delete_k3d_volumes() {
  log "Removing all Docker volumes related to k3d..."
  docker volume ls --format '{{.Name}}' | grep '^k3d-' | xargs -r docker volume rm -f || true
}

delete_k3d_networks() {
  log "Removing all Docker networks related to k3d..."
  docker network ls --format '{{.Name}}' | grep '^k3d-' | xargs -r docker network rm || true
}

delete_k3d_binary() {
  if [[ -f "${K3D_BIN}" ]]; then
    log "Removing k3d binary at ${K3D_BIN}..."
    sudo rm -f "${K3D_BIN}"
    log "k3d binary deleted."
  else
    log "k3d binary already removed or never installed."
  fi
}

final_check() {
  local fails=0

  if command -v k3d >/dev/null 2>&1; then
    log "ERROR: k3d still present in PATH."
    ((fails++))
  fi

  if docker ps -a | grep -q 'k3d-'; then
    log "ERROR: Residual containers found."
    ((fails++))
  fi

  if docker volume ls | grep -q 'k3d-'; then
    log "ERROR: Residual volumes found."
    ((fails++))
  fi

  if docker network ls | grep -q 'k3d-'; then
    log "ERROR: Residual networks found."
    ((fails++))
  fi

  if [[ "$fails" -gt 0 ]]; then
    log "Destructive cleanup incomplete. ${fails} resource types remain."
    exit 1
  else
    log " All k3d-related binaries and resources have been permanently removed."
  fi
}

main() {
  log "=== Starting FULL DESTRUCTIVE cleanup for k3d environment ==="
  delete_cluster_and_registry
  delete_k3d_containers
  delete_port_bound_registry
  delete_k3d_volumes
  delete_k3d_networks
  delete_k3d_binary
  final_check
  log "=== Full cleanup complete. Local k3d environment wiped ==="
}

main
