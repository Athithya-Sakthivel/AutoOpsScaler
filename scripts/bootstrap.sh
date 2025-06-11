#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

# Versions
AWSCLI_VERSION="2.15.29"
ARGOCD_VERSION="3.0.5"
ARGO_WORKFLOWS_VERSION="3.6.10"
KUBECTL_VERSION="v1.29.4"
HELM_VERSION="v3.12.1"
K3S_VERSION="v1.28.6+k3s1"
PULUMI_VERSION="v4.55.4"
KUBEVAL_VERSION="0.18.1"
KUBESCORE_VERSION="1.23.0"
KUBE_LINTER_VERSION="0.9.0"
SUPABASE_CLI_VERSION="1.65.3"
PROMETHEUS_VERSION="2.43.0"
OTELCOL_VERSION="0.88.0"
GRAFANA_VERSION="11.2.2"

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export PYTHONPATH=$(pwd)
source ~/.bashrc || true

# retry helper
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

download() {
  local url="$1" out="$2" tmp="${out}.part"
  retry bash -c "curl -fsSL \"$url\" -o \"$tmp\" && test -s \"$tmp\" && mv \"$tmp\" \"$out\""
}

echo "🔧 Installing apt dependencies..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  curl sudo unzip jq gnupg lsb-release software-properties-common yamllint > /dev/null

# AWS CLI
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

# kubectl
if ! command -v kubectl &>/dev/null; then
  echo "☸️  Installing kubectl ${KUBECTL_VERSION}..."
  download "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" kubectl
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
else
  echo "✔️  kubectl already installed"
fi

# helm
if ! command -v helm &>/dev/null; then
  echo "⛵ Installing Helm ${HELM_VERSION}..."
  download "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" helm.tar.gz
  tar -xzf helm.tar.gz linux-amd64/helm
  chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/local/bin/
  rm -rf linux-amd64 helm.tar.gz
else
  echo "✔️  helm already installed"
fi

# k3s
if ! command -v k3s &>/dev/null; then
  echo "🔗 Installing k3s ${K3S_VERSION}..."
  curl -sfL https://get.k3s.io | sudo INSTALL_K3S_VERSION=${K3S_VERSION} sh -
else
  echo "✔️  k3s already installed"
fi

# Argo CD CLI
if ! command -v argocd &>/dev/null; then
  echo "🎯 Installing Argo CD CLI ${ARGOCD_VERSION}..."
  download "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" argocd
  chmod +x argocd && sudo mv argocd /usr/local/bin/
else
  echo "✔️  argocd already installed"
fi

# Argo Workflows CLI
if ! command -v argo &>/dev/null; then
  echo "🎯 Installing Argo Workflows CLI ${ARGO_WORKFLOWS_VERSION}..."
  download "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_WORKFLOWS_VERSION}/argo-linux-amd64.gz" argo.gz
  gunzip argo.gz
  chmod +x argo && sudo mv argo /usr/local/bin/
else
  echo "✔️  argo already installed"
fi

# Pulumi
if ! command -v pulumi &>/dev/null; then
  echo "📦 Installing Pulumi CLI ${PULUMI_VERSION}..."
  download "https://get.pulumi.com/releases/sdk/pulumi-${PULUMI_VERSION}-linux-x64.tar.gz" pulumi.tar.gz
  tar -xzf pulumi.tar.gz pulumi-${PULUMI_VERSION}-linux-x64/bin/pulumi
  chmod +x pulumi && sudo mv pulumi /usr/local/bin/
  rm pulumi.tar.gz
else
  echo "✔️  pulumi already installed"
fi

# kubeval
if ! command -v kubeval &>/dev/null; then
  echo "🔍 Installing kubeval ${KUBEVAL_VERSION}..."
  download "https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" kv.tar.gz
  tar -xzf kv.tar.gz kubeval
  chmod +x kubeval && sudo mv kubeval /usr/local/bin/
  rm kv.tar.gz
else
  echo "✔️  kubeval already installed"
fi

# kube-score
if ! command -v kube-score &>/dev/null; then
  echo "🔍 Installing kube-score ${KUBESCORE_VERSION}..."
  download "https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64.tar.gz" ks.tar.gz
  tar -xzf ks.tar.gz kube-score
  chmod +x kube-score && sudo mv kube-score /usr/local/bin/
  rm ks.tar.gz
else
  echo "✔️  kube-score already installed"
fi

# kube-linter
if ! command -v kube-linter &>/dev/null; then
  echo "🔍 Installing kube-linter ${KUBE_LINTER_VERSION}..."
  download "https://github.com/stackrox/kube-linter/releases/download/v${KUBE_LINTER_VERSION}/kube-linter-linux-amd64.tar.gz" kl.tar.gz
  tar -xzf kl.tar.gz kube-linter
  chmod +x kube-linter && sudo mv kube-linter /usr/local/bin/
  rm kl.tar.gz
else
  echo "✔️  kube-linter already installed"
fi

# Supabase CLI
if ! command -v supabase &>/dev/null; then
  echo "🚀 Installing Supabase CLI ${SUPABASE_CLI_VERSION}..."
  download "https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/supabase_${SUPABASE_CLI_VERSION}_linux_amd64.tar.gz" sb.tar.gz
  tar -xzf sb.tar.gz supabase
  chmod +x supabase && sudo mv supabase /usr/local/bin/
  rm sb.tar.gz
else
  echo "✔️  supabase already installed"
fi

# Prometheus & promtool
if ! command -v promtool &>/dev/null || ! command -v prometheus &>/dev/null; then
  echo "📊 Installing Prometheus ${PROMETHEUS_VERSION}..."
  download "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" pm.tar.gz
  tar -xzf pm.tar.gz
  chmod +x prometheus-${PROMETHEUS_VERSION}.linux-amd64/{prometheus,promtool}
  sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/{prometheus,promtool} /usr/local/bin/
  rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64 pm.tar.gz
else
  echo "✔️  Prometheus & promtool already installed"
fi

# OpenTelemetry Collector
if ! command -v otelcol &>/dev/null; then
  echo "📡 Installing OpenTelemetry Collector ${OTELCOL_VERSION}..."
  download "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol_${OTELCOL_VERSION}_linux_amd64.tar.gz" oc.tar.gz
  tar -xzf oc.tar.gz otelcol
  chmod +x otelcol && sudo mv otelcol /usr/local/bin/
  rm oc.tar.gz
else
  echo "✔️  otelcol already installed"
fi

# Grafana CLI
if ! command -v grafana-cli &>/dev/null; then
  echo "📈 Installing Grafana CLI from Grafana ${GRAFANA_VERSION}..."
  download "https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz" gf.tar.gz
  tar -xzf gf.tar.gz grafana-${GRAFANA_VERSION}/bin/grafana-cli
  chmod +x grafana-${GRAFANA_VERSION}/bin/grafana-cli
  sudo mv grafana-${GRAFANA_VERSION}/bin/grafana-cli /usr/local/bin/
  rm -rf grafana-${GRAFANA_VERSION} gf.tar.gz
else
  echo "✔️  grafana-cli already installed"
fi

echo "✅ All CLI tools (including otelcol, prometheus, grafana-cli) installed!"
