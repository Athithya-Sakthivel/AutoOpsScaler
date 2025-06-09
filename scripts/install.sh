#!/usr/bin/env bash

set -euo pipefail
sudo apt install python3-pip

IFS=$'\n\t' # strict IFS for safety

LOG_FILE="./setup_env.log"
exec > >(tee -i "$LOG_FILE") 2>&1 # redirect all output to log

retry() {
  local -r -i max_attempts=2
  local -r -i sleep_time=3
  local -i attempt_num=1
  until "$@"; do
    if (( attempt_num == max_attempts )); then
      echo "❌ Failed after $attempt_num attempts: $*" >&2
      return 1
    else
      echo "⚠️  Attempt $attempt_num failed. Retrying in $sleep_time seconds..."
      sleep $sleep_time
      ((attempt_num++))
    fi
  done
}

download_with_retry() {
  local url="$1"
  local output="$2"
  local tmp_file="${output}.part"
  retry bash -c "curl -fsSL \"$url\" -o \"$tmp_file\" && test -s \"$tmp_file\" && mv \"$tmp_file\" \"$output\""
}

echo "🚀 Updating system..."
retry sudo apt update -y

echo "📦 Installing system essentials..."
retry sudo apt install -y \
  build-essential curl wget git jq unzip software-properties-common \
  ca-certificates gnupg make libpq-dev libyaml-dev libssl-dev zlib1g-dev \
  libffi-dev libxml2-dev libxslt1-dev libjpeg-dev libblas-dev liblapack-dev \
  gfortran pkg-config tree gh yamllint tar gzip

echo "🐳 Installing Docker Engine..."
if ! command -v docker >/dev/null 2>&1; then
  retry sudo apt remove -y docker docker.io containerd runc || true
  retry sudo mkdir -p /etc/apt/keyrings
  retry curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  retry sudo apt update -y
  retry sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "🔧 Ensuring docker group access for $USER..."
if ! groups "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
fi

echo "☸️ Installing kubectl 1.27.3..."
if ! command -v kubectl >/dev/null 2>&1; then
  download_with_retry "https://dl.k8s.io/release/v1.27.3/bin/linux/amd64/kubectl" "kubectl"
  sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm -f kubectl
fi

echo "🧬 Installing k3s 1.27.3..."
if ! command -v k3s >/dev/null 2>&1; then
  retry curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.27.3+k3s1" sh -
fi

echo "🚀 Installing Argo CD CLI v2.6.4..."
if ! command -v argocd >/dev/null 2>&1; then
  download_with_retry "https://github.com/argoproj/argo-cd/releases/download/v2.6.4/argocd-linux-amd64" "argocd"
  chmod +x argocd && sudo mv argocd /usr/local/bin/argocd
fi

echo "🚀 Installing Argo Workflows CLI v3.5.1..."
if ! command -v argo >/dev/null 2>&1; then
  download_with_retry "https://github.com/argoproj/argo-workflows/releases/download/v3.5.1/argo-linux-amd64" "argo"
  chmod +x argo && sudo mv argo /usr/local/bin/argo
fi

echo "🧱 Installing Terraform 1.4.6..."
if ! command -v terraform >/dev/null 2>&1; then
  download_with_retry "https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip" "terraform.zip"
  unzip -o terraform.zip && sudo mv terraform /usr/local/bin/terraform && rm -f terraform.zip
fi

echo "📄 Installing ytt 0.50.6..."
if ! command -v ytt >/dev/null 2>&1; then
  download_with_retry "https://github.com/carvel-dev/ytt/releases/download/v0.50.6/ytt-linux-amd64" "ytt"
  chmod +x ytt && sudo mv ytt /usr/local/bin/ytt
fi

echo "📦 Installing kapp 0.44.0..."
if ! command -v kapp >/dev/null 2>&1; then
  download_with_retry "https://github.com/carvel-dev/kapp/releases/download/v0.44.0/kapp-linux-amd64" "kapp"
  chmod +x kapp && sudo mv kapp /usr/local/bin/kapp
fi

echo "🔍 Installing kubeconform v0.7.0..."
if ! command -v kubeconform >/dev/null 2>&1; then
  download_with_retry \
    "https://github.com/yannh/kubeconform/releases/download/v0.7.0/kubeconform-linux-amd64.tar.gz" \
    "kubeconform.tar.gz"
  tar -xzf kubeconform.tar.gz kubeconform
  sudo chmod +x kubeconform
  sudo mv kubeconform /usr/local/bin/kubeconform
  rm -f kubeconform.tar.gz
fi


echo "🔍 Installing kube-linter (v0.7.2)..."
if ! command -v kube-linter >/dev/null 2>&1; then
  download_with_retry \
    "https://github.com/stackrox/kube-linter/releases/download/v0.7.2/kube-linter-linux.tar.gz" \
    "kube-linter.tar.gz"
  tar -xzf kube-linter.tar.gz kube-linter
  sudo chmod +x kube-linter
  sudo mv kube-linter /usr/local/bin/kube-linter
  rm -f kube-linter.tar.gz
fi

echo "🔍 Installing kube-score v1.24.0..."
if ! command -v kube-score >/dev/null 2>&1; then
  download_with_retry \
    "https://github.com/zegl/kube-score/releases/download/v1.24.0/kube-score_1.24.0_linux_amd64.tar.gz" \
    "kube-score.tar.gz"
  tar -xzf kube-score.tar.gz kube-score
  sudo chmod +x kube-score
  sudo mv kube-score /usr/local/bin/kube-score
  rm -f kube-score.tar.gz
fi

echo "✅ Setup complete! Log: $LOG_FILE"
echo "ℹ️ Logout/login to apply docker group change."

