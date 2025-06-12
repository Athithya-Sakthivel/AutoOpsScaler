#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

# ─── Versions ───────────────────────────────────────────────────────────────
AWSCLI_VERSION="2.15.29"
KUBECTL_VERSION="v1.29.4"
HELM_VERSION="v3.12.1"
K3S_VERSION="v1.28.6+k3s1"
ARGOCD_VERSION="3.0.5"
PULUMI_VERSION="3.136.1"

# ─── helper: prepend to PATH if missing ──────────────────────────────────────
prepend_path() {
  local dir="$1"
  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *) PATH="${dir}:${PATH}" ;;
  esac
}

# ─── Environment setup ───────────────────────────────────────────────────────
prepend_path "$HOME/.local/bin"
prepend_path "/usr/local/bin"
export PATH
export PYTHONPATH="/vagrant"

# ─── Persist to ~/.bashrc once ───────────────────────────────────────────────
if ! grep -qxF 'prepend_path "$HOME/.local/bin"' ~/.bashrc; then
  cat >> ~/.bashrc << 'EOF'

# ensure custom bin dirs on front
prepend_path() {
  local dir="$1"
  case ":${PATH}:" in *":${dir}:"*) ;; *) PATH="${dir}:${PATH}" ;; esac
}
prepend_path "$HOME/.local/bin"
prepend_path "/usr/local/bin"
export PATH
EOF
fi

# ─── retry helper ────────────────────────────────────────────────────────────
retry() {
  local max=3 sleep=3 n=1
  until "$@"; do
    (( n == max )) && { echo "❌ [$*] failed after $n attempts" >&2; return 1; }
    echo "⚠️  attempt $n failed; retrying in ${sleep}s..."
    sleep $sleep
    ((n++))
  done
}

# ─── download helper ─────────────────────────────────────────────────────────
download() {
  local url="$1" out="$2" tmp="${out}.part"
  [[ -z "$url" || -z "$out" ]] && { echo "❌ download(url,out) needs two args" >&2; return 1; }
  retry curl -fsSL "$url" -o "$tmp"
  mv "$tmp" "$out"
}

# ─── apt dependencies ────────────────────────────────────────────────────────
echo "🔧 Installing apt dependencies..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  curl sudo unzip jq gnupg lsb-release software-properties-common yamllint > /dev/null

# ─── AWS CLI ─────────────────────────────────────────────────────────────────
if ! command -v aws &>/dev/null; then
  echo "☁️  Installing AWS CLI ${AWSCLI_VERSION}..."
  cd /tmp
  download "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" awscliv2.zip
  unzip -q awscliv2.zip
  sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
  rm -rf /tmp/aws*
else
  echo "✔️  AWS CLI already installed"
fi

# ─── kubectl ─────────────────────────────────────────────────────────────────
if ! command -v kubectl &>/dev/null; then
  echo "☸️  Installing kubectl ${KUBECTL_VERSION}..."
  download "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" kubectl
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
else
  echo "✔️  kubectl already installed"
fi

# ─── Helm ────────────────────────────────────────────────────────────────────
if ! command -v helm &>/dev/null; then
  echo "⛵ Installing Helm ${HELM_VERSION}..."
  download "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" helm.tar.gz
  tar -xzf helm.tar.gz linux-amd64/helm
  chmod +x linux-amd64/helm
  sudo mv linux-amd64/helm /usr/local/bin/
  rm -rf linux-amd64 helm.tar.gz
else
  echo "✔️  helm already installed"
fi

# ─── k3s ──────────────────────────────────────────────────────────────────────
if ! command -v k3s &>/dev/null; then
  echo "🔗 Installing k3s ${K3S_VERSION}..."
  curl -sfL https://get.k3s.io | sudo INSTALL_K3S_VERSION=${K3S_VERSION} sh -
else
  echo "✔️  k3s already installed"
fi

# ─── Argo CD CLI ──────────────────────────────────────────────────────────────
if ! command -v argocd &>/dev/null; then
  echo "🎯 Installing Argo CD CLI ${ARGOCD_VERSION}..."
  download "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" argocd
  chmod +x argocd
  sudo mv argocd /usr/local/bin/
else
  echo "✔️  argocd already installed"
fi

# ─── Pulumi ───────────────────────────────────────────────────────────────────
if ! command -v pulumi &>/dev/null; then
  echo "📦 Installing Pulumi CLI v${PULUMI_VERSION}..."
  curl -fsSL https://get.pulumi.com | sh -s -- --version "${PULUMI_VERSION}"
  sudo mv ~/.pulumi/bin/pulumi /usr/local/bin/
else
  echo "✔️  pulumi already installed"
fi

chmod +x scripts/win2vagrant.sh
