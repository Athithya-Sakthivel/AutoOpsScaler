#!/usr/bin/env bash
set -euxo pipefail

# Constants
YTT_VERSION="v0.52.0"
KAPP_VERSION="v0.64.2"
AWSCLI_VERSION="2.15.29"
ARGOCD_VERSION="3.0.5"
ARGO_WORKFLOWS_VERSION="3.6.10"

export PATH="$HOME/.local/bin:$PATH" && source ~/.bashrc


# Retry helper function
retry() {
  local max_attempts=3
  local sleep_time=3
  local attempt=1
  until "$@"; do
    if (( attempt == max_attempts )); then
      echo "Command failed after $attempt attempts: $*" >&2
      return 1
    fi
    echo "Attempt $attempt failed. Retrying in $sleep_time seconds..."
    sleep $sleep_time
    ((attempt++))
  done
}

# Download with retry helper
download_with_retry() {
  local url="$1"
  local output="$2"
  local tmp="${output}.part"
  retry bash -c "curl -fsSL \"$url\" -o \"$tmp\" && test -s \"$tmp\" && mv \"$tmp\" \"$output\""
}

echo "Installing apt dependencies..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  curl sudo python3.10-venv unzip jq python3-pip gnupg software-properties-common > /dev/null

# Install AWS CLI
echo "Installing AWS CLI ${AWSCLI_VERSION}..."
if ! command -v aws >/dev/null; then
  cd /tmp
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o awscliv2.zip
  unzip -q awscliv2.zip
  sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
  rm -rf /tmp/aws*
else
  echo "AWS CLI already installed"
fi


# Install Argo CD CLI
echo "Installing Argo CD CLI v${ARGOCD_VERSION}..."
if ! command -v argocd >/dev/null; then
  cd /tmp
  download_with_retry "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" argocd
  chmod +x argocd
  sudo mv argocd /usr/local/bin/argocd
else
  echo "Argo CD CLI already installed"
fi

# Install Argo Workflows CLI
echo "Installing Argo Workflows CLI v${ARGO_WORKFLOWS_VERSION}..."
if ! command -v argo >/dev/null; then
  cd /tmp
  download_with_retry "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_WORKFLOWS_VERSION}/argo-linux-amd64.gz" argo.gz
  gunzip argo.gz
  chmod +x argo
  sudo mv argo /usr/local/bin/argo
else
  echo "Argo Workflows CLI already installed"
fi

# Install Carvel tools (ytt and kapp)
echo "Installing Carvel tools..."
if ! command -v ytt >/dev/null; then
  cd /tmp
  download_with_retry "https://github.com/carvel-dev/ytt/releases/download/${YTT_VERSION}/ytt-linux-amd64" ytt
  chmod +x ytt
  sudo mv ytt /usr/local/bin/ytt
else
  echo "ytt already installed"
fi

if ! command -v kapp >/dev/null; then
  cd /tmp
  download_with_retry "https://github.com/carvel-dev/kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64" kapp
  chmod +x kapp
  sudo mv kapp /usr/local/bin/kapp
else
  echo "kapp already installed"
fi

echo "Tool installation complete!"
