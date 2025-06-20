#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="autoopsscaler-dev"
REGISTRY_NAME="k3d-${CLUSTER_NAME}-registry"
REGISTRY_PORT="5000"
REGISTRY_CONTAINER_NAME_PREFIX="k3d-${REGISTRY_NAME}"
NETWORK_NAME="k3d-${CLUSTER_NAME}"

log() {
  echo "[delete-lc.sh] $1"
}

delete_cluster() {
  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
    log "Deleting k3d cluster ${CLUSTER_NAME}..."
    k3d cluster delete "${CLUSTER_NAME}" || true
  else
    log "No k3d cluster named ${CLUSTER_NAME} found."
  fi
}

delete_registry() {
  if k3d registry list | grep -q "^${REGISTRY_NAME}\b"; then
    log "Deleting k3d-managed registry ${REGISTRY_NAME}..."
    k3d registry delete "${REGISTRY_NAME}" || true
  else
    log "No k3d-managed registry ${REGISTRY_NAME} found."
  fi

  # Remove any remaining Docker containers with registry name prefix
  local containers
  containers=$(docker ps -a --filter "name=${REGISTRY_CONTAINER_NAME_PREFIX}" --format '{{.ID}} {{.Names}}')
  if [[ -n "$containers" ]]; then
    log "Removing lingering Docker containers related to registry:"
    echo "$containers"
    docker rm -f $(echo "$containers" | awk '{print $1}') || true
  else
    log "No lingering registry containers found."
  fi

  # Kill any containers binding host port 5000
  local port_containers
  port_containers=$(docker ps -q --filter "publish=${REGISTRY_PORT}")
  if [[ -n "$port_containers" ]]; then
    log "Force-removing containers binding to host port ${REGISTRY_PORT}..."
    docker rm -f $port_containers || true
  fi
}

delete_network() {
  if docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
    log "Removing k3d network ${NETWORK_NAME}..."
    docker network rm "${NETWORK_NAME}" || true
  else
    log "No k3d network ${NETWORK_NAME} found."
  fi
}

delete_volumes() {
  # Remove volumes created by k3d cluster
  local volumes
  volumes=$(docker volume ls --filter "name=k3d-${CLUSTER_NAME}" --format '{{.Name}}')
  if [[ -n "$volumes" ]]; then
    log "Removing Docker volumes related to cluster:"
    echo "$volumes"
    docker volume rm $volumes || true
  else
    log "No Docker volumes found for ${CLUSTER_NAME}."
  fi
}

check_no_leftovers() {
  local leftovers

  leftovers=$(docker ps -a --filter "name=${REGISTRY_CONTAINER_NAME_PREFIX}" --format '{{.Names}}')
  if [[ -n "$leftovers" ]]; then
    log "ERROR: Some registry containers still exist:"
    echo "$leftovers"
    exit 1
  fi

  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
    log "ERROR: Cluster ${CLUSTER_NAME} still listed in k3d."
    exit 1
  fi

  if k3d registry list | grep -q "^${REGISTRY_NAME}\b"; then
    log "ERROR: Registry ${REGISTRY_NAME} still listed in k3d."
    exit 1
  fi

  log "All k3d-related resources cleaned up successfully."
}

main() {
  log "Starting full k3d cleanup for cluster: ${CLUSTER_NAME}"
  delete_cluster
  delete_registry
  delete_network
  delete_volumes
  check_no_leftovers
  log "Cleanup complete."
}

main
