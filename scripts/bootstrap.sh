#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Installing base dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl ca-certificates unzip git gnupg2 lsb-release apt-transport-https software-properties-common \
    make sudo bash-completion procps iputils-ping iproute2 python3 python3-pip

apt-get clean && rm -rf /var/lib/apt/lists/*

echo "[INFO] Installing kubectl 1.27.9..."
curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.27.9/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl
kubectl version --client

echo "[INFO] Installing ArgoCD 2.8.4..."
curl -fsSLo /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.8.4/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
argocd version --client

echo "[INFO] Installing Minikube 1.30.1..."
curl -fsSLo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/v1.30.1/minikube-linux-amd64
chmod +x /usr/local/bin/minikube
minikube version

echo "[INFO] Installing Helm 3.13.3..."
curl -fsSL https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz | tar -xz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64
helm version

echo "[INFO] Installing Prometheus 2.48.1..."
curl -fsSL https://github.com/prometheus/prometheus/releases/download/v2.48.1/prometheus-2.48.1.linux-amd64.tar.gz | tar -xz
mv prometheus-2.48.1.linux-amd64/prometheus /usr/local/bin/prometheus
rm -rf prometheus-2.48.1.linux-amd64
prometheus --version

echo "[INFO] Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
apt-get update
apt-get install -y gh
gh --version

echo "[INFO] Installing Pulumi CLI 3.95.0..."
curl -fsSL https://get.pulumi.com/releases/sdk/pulumi-v3.95.0-linux-x64.tar.gz | tar -xz
mv pulumi/* /usr/local/bin/
rm -rf pulumi
pulumi version

echo "[INFO] Installing Pulumi AWS plugin v5.44.0..."
# You can pre-install this so `pulumi up` doesn’t pull on first run
pulumi plugin install resource aws v5.44.0 --yes
# Install required packages (safe and idempotent)
sudo apt update && sudo apt install -y unzip curl groff less

# Download AWS CLI v2.13.21 (64-bit Linux installer)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.13.21.zip" -o "awscliv2.zip"

# Unzip the installer
unzip -q awscliv2.zip

# Install or update (idempotent and safe)
sudo ./aws/install --update

# Verify exact version
aws --version

echo "[SUCCESS] Bootstrap completed successfully."
