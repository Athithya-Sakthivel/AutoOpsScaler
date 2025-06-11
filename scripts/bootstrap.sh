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
SUPABASE_CLI_VERSION="1.65.3"
PROMETHEUS_VERSION="2.43.0"


export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export PYTHONPATH="/vagrant"
source /home/vagrant/.bashrc || true

# ─── retry helper ────────────────────────────────────────────────────────────
retry() {
  local max=3 sleep=3 n=1
  until "$@"; do
    (( n == max )) && {
      echo "❌ [$*] failed after $n attempts" >&2
      return 1
    }
    echo "⚠️  attempt $n failed; retrying in ${sleep}s..."
    sleep $sleep
    ((n++))
  done
}

# ─── download helper ─────────────────────────────────────────────────────────
download() {
  set +u
  local url="$1" out="$2"
  set -u
  [[ -z "$url" || -z "$out" ]] && {
    echo "❌ download(url,out) requires two args" >&2
    return 1
  }
  local tmp="${out}.part"
  retry bash -c "curl -fsSL \"$url\" -o \"$tmp\" && test -s \"$tmp\" && mv \"$tmp\" \"$out\""
}

# ─── apt dependencies ────────────────────────────────────────────────────────
echo "🔧 Installing apt dependencies..."
sudo apt-get update -qq
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
  download "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" kubectl.sha256
  sha256sum --strict -c kubectl.sha256
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
  rm kubectl.sha256
else
  echo "✔️  kubectl already installed"
fi

# ─── Helm ────────────────────────────────────────────────────────────────────
if ! command -v helm &>/dev/null; then
  echo "⛵ Installing Helm ${HELM_VERSION}..."
  download "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" helm.tar.gz
  download "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256" helm.tar.gz.sha256
  sha256sum --strict -c helm.tar.gz.sha256
  tar -xzf helm.tar.gz linux-amd64/helm
  chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/local/bin/
  rm -rf linux-amd64 helm.tar.gz helm.tar.gz.sha256
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
  download "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64.sha256" argocd.sha256
  sha256sum --strict -c argocd.sha256
  chmod +x argocd && sudo mv argocd /usr/local/bin/
  rm argocd.sha256
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

# ─── Supabase CLI ─────────────────────────────────────────────────────────────
if ! command -v supabase &>/dev/null; then
  echo "🚀 Installing Supabase CLI ${SUPABASE_CLI_VERSION}..."
  download "https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/supabase_${SUPABASE_CLI_VERSION}_Linux_amd64.tar.gz" sb.tar.gz
  download "https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/supabase_${SUPABASE_CLI_VERSION}_Linux_amd64.tar.gz.sha256" sb.tar.gz.sha256
  sha256sum --strict -c sb.tar.gz.sha256
  tar -xzf sb.tar.gz supabase
  chmod +x supabase && sudo mv supabase /usr/local/bin/
  rm sb.tar.gz sb.tar.gz.sha256
else
  echo "✔️  supabase already installed"
fi

# ─── Prometheus & promtool ────────────────────────────────────────────────────
if ! command -v prometheus &>/dev/null || ! command -v promtool &>/dev/null; then
  echo "📊 Installing Prometheus ${PROMETHEUS_VERSION}..."
  download "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" pm.tar.gz
  download "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz.sha256" pm.tar.gz.sha256
  sha256sum --strict -c pm.tar.gz.sha256
  tar -xzf pm.tar.gz prometheus-${PROMETHEUS_VERSION}.linux-amd64/{prometheus,promtool}
  sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/{prometheus,promtool} /usr/local/bin/
  rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64 pm.tar.gz pm.tar.gz.sha256
else
  echo "✔️  Prometheus & promtool already installed"
fi
