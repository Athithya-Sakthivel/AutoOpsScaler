#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="autoopsscaler-dev"
REGISTRY_NAME="k3d-${CLUSTER_NAME}-registry"
REGISTRY_PORT="5000"
REGISTRY_CONTAINER_NAME_PREFIX="k3d-${REGISTRY_NAME}"

log() {
  echo "[delete-lc.sh] $1"
}

delete_cluster() {
  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
    log "Deleting cluster ${CLUSTER_NAME}..."
    k3d cluster delete "${CLUSTER_NAME}"
  else
    log "Cluster ${CLUSTER_NAME} does not exist. Skipping."
  fi
}

delete_registry() {
  # Delete k3d-managed registry by k3d CLI
  if k3d registry list | grep -q "^${REGISTRY_NAME}\b"; then
    log "Deleting k3d-managed registry ${REGISTRY_NAME} via k3d..."
    k3d registry delete "${REGISTRY_NAME}" || true
  else
    log "No k3d-managed registry ${REGISTRY_NAME} found."
  fi

  # Remove any dangling docker containers with name prefix "k3d-<registry>"
  # This catches stale containers that k3d CLI may miss
  local containers
  containers=$(docker ps -a --filter "name=${REGISTRY_CONTAINER_NAME_PREFIX}" --format '{{.ID}} {{.Names}}')
  if [[ -n "$containers" ]]; then
    log "Removing dangling docker containers related to registry:"
    echo "$containers"
    docker rm -f $(echo "$containers" | awk '{print $1}') || true
  else
    log "No dangling registry containers found."
  fi

  # Also forcibly kill any container binding host port 5000 (default registry port)
  local port_containers
  port_containers=$(docker ps -q --filter "publish=${REGISTRY_PORT}")
  if [[ -n "$port_containers" ]]; then
    log "Removing containers binding port ${REGISTRY_PORT}:"
    docker rm -f $port_containers || true
  else
    log "No containers binding port ${REGISTRY_PORT} found."
  fi
}

delete_network() {
  # Remove any k3d network related to the cluster to avoid stale network conflicts
  if docker network ls --format '{{.Name}}' | grep -q "^k3d-${CLUSTER_NAME}$"; then
    log "Removing docker network k3d-${CLUSTER_NAME}..."
    docker network rm "k3d-${CLUSTER_NAME}" || true
  else
    log "Docker network k3d-${CLUSTER_NAME} not found. Skipping."
  fi
}

check_no_registry_leftover() {
  # Check if any registry container still exists after deletion, fail if yes
  local leftover
  leftover=$(docker ps -a --filter "name=${REGISTRY_CONTAINER_NAME_PREFIX}" --format '{{.Names}}')
  if [[ -n "$leftover" ]]; then
    log "ERROR: Registry containers still exist after deletion:"
    echo "$leftover"
    exit 1
  fi

  # Check if k3d registry still listed
  if k3d registry list | grep -q "^${REGISTRY_NAME}\b"; then
    log "ERROR: Registry ${REGISTRY_NAME} still present in k3d registry list."
    exit 1
  fi

  log "No registry leftovers found."
}

main() {
  delete_cluster
  delete_registry
  delete_network
  check_no_registry_leftover
  log "Full cleanup complete."
}

main
