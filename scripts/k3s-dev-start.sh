#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/k3s.log"
K3S_BIN="/usr/local/bin/k3s"
K3S_CONFIG_DIR="/etc/rancher/k3s"
K3S_CONFIG_FILE="$K3S_CONFIG_DIR/k3s.yaml"
K3S_CONFIG_YAML="$K3S_CONFIG_DIR/config.yaml"
K3S_VERSION="${K3S_VERSION:-v1.29.2+k3s1}"

echo "🔍 Checking prerequisites..."

# Ensure k3s binary exists and is the correct version
if ! command -v k3s >/dev/null 2>&1 || [[ "$($K3S_BIN --version 2>/dev/null | head -1)" != *"$K3S_VERSION"* ]]; then
  echo "🔽 Downloading K3s $K3S_VERSION..."
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="server --disable traefik" INSTALL_K3S_SKIP_ENABLE=true sh -
fi

# Ensure config directory and files exist, clear any old config
sudo mkdir -p "$K3S_CONFIG_DIR"
sudo rm -f "$K3S_CONFIG_FILE" "$K3S_CONFIG_YAML"
sudo touch "$K3S_CONFIG_FILE"
sudo chmod 644 "$K3S_CONFIG_FILE"

# Remove old k3s state and logs for idempotency
echo "🧹 Removing old K3s state and logs..."
sudo pkill -f 'k3s server' || true
sudo pkill -f 'k3s-agent' || true
sudo pkill -f 'containerd' || true
sudo pkill -f 'kube-apiserver' || true
if sudo lsof -i :6443 | grep LISTEN; then
  sudo lsof -ti :6443 | xargs -r sudo kill -9
fi
sleep 2
sudo rm -rf /var/lib/rancher/k3s/agent/containerd/*
sudo rm -rf /var/lib/rancher/k3s/agent/etc/containerd/*
sudo rm -rf /var/lib/rancher/k3s/server/*
sudo rm -rf /etc/cni/net.d/*
sudo rm -f "$LOG_FILE"

# Try to use fuse-overlayfs, fallback to native if not available
SNAPSHOTTER="fuse-overlayfs"
if ! command -v fuse-overlayfs >/dev/null 2>&1; then
  SNAPSHOTTER="native"
  echo "⚠️  fuse-overlayfs not found, using native snapshotter."
fi

# Write K3s config to force snapshotter (this is what K3s actually reads)
echo "containerd-snapshotter: $SNAPSHOTTER" | sudo tee "$K3S_CONFIG_YAML" >/dev/null

echo "🚀 Starting K3s server in background (using config.yaml for snapshotter)..."
nohup sudo "$K3S_BIN" server --disable traefik > "$LOG_FILE" 2>&1 &

# Wait for k3s to be ready
echo "⏳ Waiting for K3s node to be ready..."
for i in {1..30}; do
  sleep 2
  if sudo "$K3S_BIN" kubectl get node >/dev/null 2>&1; then
    STATUS=$(sudo "$K3S_BIN" kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
    if [[ "$STATUS" == "True" ]]; then
      echo "✅ K3s node is ready!"
      sudo "$K3S_BIN" kubectl get nodes -o wide
      exit 0
    fi
  fi
  echo "  ...waiting ($i/30)"
done

echo "❌ K3s did not become ready in time. Check logs at $LOG_FILE"
exit 1