#!/usr/bin/env bash
set -euo pipefail

# === CONFIG ===
K3D_VERSION="v5.6.3"     # Pin a stable known version
CLUSTER_NAME="my-local-cluster" # Change as needed
AGENTS=2                 # Number of worker nodes

# === FUNCTIONS ===

install_k3d() {
  echo "[*] Installing k3d ${K3D_VERSION}..."
  if ! command -v k3d >/dev/null 2>&1 || [[ "$(k3d --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')" != "${K3D_VERSION}" ]]; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=${K3D_VERSION} bash
  else
    echo "[=] k3d ${K3D_VERSION} already installed."
  fi
}

create_k3d_cluster() {
  echo "[*] Creating k3d cluster '${CLUSTER_NAME}' with ${AGENTS} agents..."
  if k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
    echo "[=] Cluster '${CLUSTER_NAME}' already exists."
  else
    k3d cluster create "${CLUSTER_NAME}" --agents ${AGENTS} --wait
  fi
}

set_kubectl_context() {
  echo "[*] Setting kubectl context to k3d-${CLUSTER_NAME}..."
  kubectl config use-context "k3d-${CLUSTER_NAME}"
}

display_cluster_info() {
  echo "[*] Current kubectl context:"
  kubectl config current-context
  echo
  echo "[*] Cluster nodes:"
  kubectl get nodes
  echo
  echo "[*] Cluster info:"
  kubectl cluster-info
}

# === RUN ===
install_k3d
create_k3d_cluster
set_kubectl_context
display_cluster_info

echo "[✓] k3d ${K3D_VERSION} installed, cluster '${CLUSTER_NAME}' ready, and kubectl configured."
