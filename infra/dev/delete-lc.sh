#!/usr/bin/env bash
set -euo pipefail

echo "[*] Cleaning up all k3d clusters, nodes, containers, networks, and binary..."

# 1) Delete all k3d clusters
if command -v k3d >/dev/null 2>&1; then
  CLUSTERS=$(k3d cluster list -o json | jq -r '.[].name')
  if [ -n "$CLUSTERS" ]; then
    for CLUSTER in $CLUSTERS; do
      echo "[*] Deleting cluster: $CLUSTER"
      k3d cluster delete "$CLUSTER"
    done
  else
    echo "[=] No k3d clusters found."
  fi
else
  echo "[=] k3d not installed, skipping cluster deletion."
fi

# 2) Remove leftover k3d Docker containers
echo "[*] Removing k3d containers (if any)..."
docker ps -a --filter "name=k3d-" --format '{{.ID}}' | xargs -r docker rm -f

# 3) Remove leftover k3d Docker networks
echo "[*] Removing k3d networks (if any)..."
docker network ls --filter "name=k3d-" --format '{{.ID}}' | xargs -r docker network rm

# 4) Remove k3d binary
echo "[*] Removing k3d binary..."
if command -v k3d >/dev/null 2>&1; then
  K3D_PATH=$(command -v k3d)
  sudo rm -f "$K3D_PATH"
  echo "[*] Removed: $K3D_PATH"
else
  echo "[=] k3d binary not found."
fi

echo "[✓] All k3d resources and binary removed."
