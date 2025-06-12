#!/usr/bin/env bash
set -euo pipefail

# delete-dev-cluster.sh — Remove all k3s artifacts for a clean dev bootstrap

#----------------------------------------
# Paths & variables
K3S_UNINSTALL_SCRIPT="/usr/local/bin/k3s-uninstall.sh"
SYSTEMD_SERVICE="/etc/systemd/system/k3s.service"
SYSTEMD_ENV="/etc/systemd/system/k3s.service.env"
SYMLINKS=(
  /usr/local/bin/k3s
  /usr/local/bin/kubectl
  /usr/local/bin/crictl
  /usr/local/bin/ctr
  /usr/local/bin/k3s-killall.sh
)
DATA_DIRS=(
  /etc/rancher/k3s
  /var/lib/rancher/k3s
  /var/lib/kubelet
  /run/k3s
)

#----------------------------------------
echo "🗑️  Deleting existing k3s dev cluster..."

# stop & disable service
if systemctl is-active --quiet k3s; then
  echo "⏹️  Stopping k3s service..."
  sudo systemctl stop k3s
fi
if systemctl is-enabled --quiet k3s; then
  echo "🚫 Disabling k3s service..."
  sudo systemctl disable k3s
fi

# run official uninstall if available
if [[ -x "$K3S_UNINSTALL_SCRIPT" ]]; then
  echo "🔄 Running k3s-uninstall.sh..."
  sudo "$K3S_UNINSTALL_SCRIPT"
else
  echo "⚠️  k3s-uninstall.sh not found, proceeding with manual cleanup..."
fi

# remove systemd unit & env
for f in "$SYSTEMD_SERVICE" "$SYSTEMD_ENV"; do
  if [[ -f "$f" ]]; then
    echo "🗃️  Removing $f"
    sudo rm -f "$f"
  fi
done

# remove symlinks
for link in "${SYMLINKS[@]}"; do
  if [[ -L "$link" ]]; then
    echo "🔗 Removing symlink $link"
    sudo rm -f "$link"
  fi
done

# remove data directories
for dir in "${DATA_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    echo "📂 Deleting directory $dir"
    sudo rm -rf "$dir"
  fi
done

# reload systemd
echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "✅ k3s dev cluster cleanup complete."
