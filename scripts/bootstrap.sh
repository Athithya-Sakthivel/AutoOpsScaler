#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
  echo "Re-running as root with sudo"
  exec sudo bash "$0" "$@"
fi

APT_OPTS=(
  -o Dpkg::Options::="--force-confdef"
  -o Dpkg::Options::="--force-confold"
  -y
)

if [ ! -f /var/lib/apt/periodic/update-success-stamp ]; then
  apt-get update -y
fi

for pkg in unzip tree; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    apt-get install "${APT_OPTS[@]}" "$pkg"
  fi
done

if ! command -v gh &>/dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update -y
  apt-get install "${APT_OPTS[@]}" gh
fi

if ! command -v aws &>/dev/null; then
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install --update
  cd /
  rm -rf "$TMPDIR"
fi

if ! command -v docker &>/dev/null; then
  apt-get install "${APT_OPTS[@]}" apt-transport-https ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install "${APT_OPTS[@]}" docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  systemctl start docker

  # Add 'vagrant' user if exists to docker group
  if id -u vagrant &>/dev/null; then
    usermod -aG docker vagrant || true
  fi

  # Add current user to docker group if not root
  CURRENT_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
  if [[ -n "$CURRENT_USER" && "$CURRENT_USER" != "root" ]]; then
    usermod -aG docker "$CURRENT_USER" || true
  fi
fi

if ! command -v kubectl &>/dev/null; then
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

if ! command -v helm &>/dev/null; then
  curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

if ! command -v minikube &>/dev/null; then
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  install minikube /usr/local/bin/minikube
  rm minikube
fi

if ! kubectl get ns ray-system &>/dev/null; then
  kubectl create namespace ray-system
fi

helm repo add kuberay https://ray-project.github.io/kuberay-helm/ || true
helm repo update

if helm status ray-operator -n ray-system &>/dev/null; then
  helm upgrade ray-operator kuberay/kuberay-operator --namespace ray-system
else
  helm install ray-operator kuberay/kuberay-operator --namespace ray-system
fi

echo "✅ All tools installed successfully."
newgrp docker