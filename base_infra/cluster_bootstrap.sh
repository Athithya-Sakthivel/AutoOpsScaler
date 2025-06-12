# base_infra/cluster_bootstrap.sh
# Bootstrap script for local (k3s) and future AWS clusters

#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELM_RELEASE_NAME="observability"
NAMESPACE="monitoring"

usage() {
  echo "Usage: $0 <dev|prod>"
  exit 1
}

if [[ -z "$ENVIRONMENT" ]]; then
  echo "❌ No environment provided."
  usage
fi

install_k3s_if_needed() {
  if ! command -v k3s &> /dev/null; then
    echo "🔧 Installing native k3s..."
    curl -sfL https://get.k3s.io | sh -s - --disable traefik
  else
    echo "✅ k3s already installed."
  fi
}

load_kubeconfig() {
  export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
  chmod 600 "$KUBECONFIG"
  echo "🔑 KUBECONFIG set to $KUBECONFIG"
}

install_observability_stack() {
  echo "📦 Deploying Prometheus + Grafana to native k3s..."

  kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  helm upgrade --install "$HELM_RELEASE_NAME" prometheus-community/kube-prometheus-stack \
    --namespace "$NAMESPACE" \
    --set grafana.enabled=true \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30001 \
    --set prometheus.service.type=NodePort \
    --set prometheus.service.nodePort=30002 \
    --wait

  echo "✅ Observability stack deployed."
  echo "🌐 Grafana:     http://localhost:30001 (admin/prom-operator)"
  echo "📊 Prometheus:  http://localhost:30002"
}

if [[ "$ENVIRONMENT" == "dev" ]]; then
  echo "🔧 Bootstrapping native k3s cluster for development..."

  install_k3s_if_needed
  load_kubeconfig
  install_observability_stack

elif [[ "$ENVIRONMENT" == "prod" ]]; then
  echo "⚠️  Production bootstrap is not yet implemented (requires Pulumi + AWS)"
  exit 2

else
  echo "❌ Invalid environment: $ENVIRONMENT"
  usage
fi
