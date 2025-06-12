#!/usr/bin/env bash
# base_infra/cluster_bootstrap.sh — Idempotent local (k3s) bootstrap with observability stack

set -euo pipefail

ENVIRONMENT="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELM_RELEASE_NAME="observability"
NAMESPACE="monitoring"
CRD_URL_BASE="https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/setup"

usage() {
  echo "Usage: $0 <dev|prod>"
  exit 1
}

if [[ -z "$ENVIRONMENT" ]]; then
  echo "❌ No environment provided."
  usage
fi

install_k3s_if_needed() {
  if ! systemctl is-active --quiet k3s; then
    echo "🔧 Installing and starting k3s..."
    curl -sfL https://get.k3s.io | sh -s - --disable traefik
  else
    echo "✅ k3s is already running."
  fi
}

load_kubeconfig() {
  export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
  chmod 600 "$KUBECONFIG"
  echo "🔑 KUBECONFIG set to $KUBECONFIG"
}

apply_crds_once() {
  if ! kubectl get crd prometheuses.monitoring.coreos.com >/dev/null 2>&1; then
    echo "🔄 Installing Prometheus Operator CRDs (GitHub fallback)..."
    kubectl apply -f "${CRD_URL_BASE}/0prometheus-operator-crdCustomResourceDefinition.yaml"
  else
    echo "✅ Prometheus Operator CRDs already installed."
  fi
}

install_observability_stack() {
  echo "📦 Deploying Prometheus + Grafana..."

  kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
  helm repo update

  apply_crds_once

  helm upgrade --install "$HELM_RELEASE_NAME" prometheus-community/kube-prometheus-stack \
    --namespace "$NAMESPACE" \
    --set grafana.enabled=true \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30001 \
    --set prometheus.service.type=NodePort \
    --set prometheus.service.nodePort=30002 \
    --wait

  echo "✅ Observability stack is up."
  echo "🌐 Grafana:     http://localhost:30001 (admin/prom-operator)"
  echo "📊 Prometheus:  http://localhost:30002"
}

if [[ "$ENVIRONMENT" == "dev" ]]; then
  echo "🔧 Bootstrapping local dev environment..."
  install_k3s_if_needed
  load_kubeconfig
  install_observability_stack

elif [[ "$ENVIRONMENT" == "prod" ]]; then
  echo "⚠️  Production bootstrap is not implemented."
  exit 2

else
  echo "❌ Invalid environment: $ENVIRONMENT"
  usage
fi
