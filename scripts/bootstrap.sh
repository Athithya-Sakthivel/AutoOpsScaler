#!/usr/bin/env bash
set -euxo pipefail

# 🌐 Fix missing locale environment variables
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8


# 🧰 Constants
YTT_VERSION="v0.52.0"
KAPP_VERSION="v0.64.2"
AWSCLI_VERSION="2.15.29"
ARGOCD_VERSION="v3.0.5"
ARGO_WORKFLOWS_VERSION="v3.6.10"
K3S_VERSION="v1.29.2+k3s1"

# 🛠 Create scripts directory
mkdir -p /workspaces/AutoOpsScaler/scripts

# 🔁 Retry helper
retry() {
  local -r max_attempts=3
  local -r sleep_time=3
  local attempt=1
  until "$@"; do
    if (( attempt == max_attempts )); then
      echo "❌ Command failed after $attempt attempts: $*" >&2
      exit 1
    fi
    echo "⚠️  Attempt $attempt failed. Retrying in $sleep_time seconds..."
    sleep $sleep_time
    ((attempt++))
  done
}

# 🛡 Download with retry
download_with_retry() {
  local url="$1" output="$2"
  local tmp="${output}.part"
  retry bash -c "curl -fsSL \"$url\" -o \"$tmp\" && test -s \"$tmp\" && mv \"$tmp\" \"$output\""
}

echo "📦 Installing apt dependencies..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  curl sudo python3.10-venv unzip jq python3-pip gnupg software-properties-common > /dev/null

# 🐋 K3s install (skip systemd)
echo "🐋 Installing K3s $K3S_VERSION..."
if ! command -v k3s >/dev/null; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="server --disable traefik" INSTALL_K3S_SKIP_ENABLE=true sh -
else
  echo "✅ K3s already installed"
fi

# 📝 Create startup script
cat <<'EOF' > /workspaces/AutoOpsScaler/scripts/k3s-dev-start.sh
#!/usr/bin/env bash
set -euo pipefail
echo "🔁 Starting K3s..."
nohup /usr/local/bin/k3s server --disable traefik > /var/log/k3s.log 2>&1 &
sleep 5
echo "✅ K3s should now be running"
EOF
chmod +x /workspaces/AutoOpsScaler/scripts/k3s-dev-start.sh

# ⚙️ Ensure config directory permissions
mkdir -p /etc/rancher/k3s
touch /etc/rancher/k3s/k3s.yaml || true
chmod 644 /etc/rancher/k3s/k3s.yaml || true

# 🚀 Install AWS CLI
echo "📦 Installing AWS CLI $AWSCLI_VERSION..."
if ! command -v aws >/dev/null; then
  cd /tmp
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o awscliv2.zip
  unzip -q awscliv2.zip
  ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
  rm -rf /tmp/aws*
else
  echo "✅ AWS CLI already installed"
fi

# 🚀 Argo CD CLI
echo "🚀 Installing Argo CD CLI $ARGOCD_VERSION..."
if ! command -v argocd >/dev/null; then
  download_with_retry "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" argocd
  chmod +x argocd
  sudo mv argocd /usr/local/bin/argocd
else
  echo "✅ Argo CD CLI already installed"
fi

# 🚀 Argo Workflows CLI
echo "🚀 Installing Argo Workflows CLI $ARGO_WORKFLOWS_VERSION..."
if ! command -v argo >/dev/null; then
  download_with_retry "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_WORKFLOWS_VERSION}/argo-linux-amd64.gz" argo.gz
  gunzip argo.gz
  chmod +x argo
  sudo mv argo /usr/local/bin/argo
else
  echo "✅ Argo Workflows CLI already installed"
fi

# 📦 Carvel tools
echo "📦 Installing Carvel tools..."
if ! command -v ytt >/dev/null; then
  download_with_retry \
    "https://github.com/carvel-dev/ytt/releases/download/${YTT_VERSION}/ytt-linux-amd64" ytt
  chmod +x ytt
  sudo mv ytt /usr/local/bin/ytt
else
  echo "✅ ytt already installed"
fi

if ! command -v kapp >/dev/null; then
  download_with_retry \
    "https://github.com/carvel-dev/kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64" kapp
  chmod +x kapp
  sudo mv kapp /usr/local/bin/kapp
else
  echo "✅ kapp already installed"
fi

echo "✅ Bootstrap complete!"
