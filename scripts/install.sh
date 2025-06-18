#!/usr/bin/env bash
set -euo pipefail

# === CONFIG ===
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export PYTHONPATH="$(pwd)"
export PATH="$HOME/.local/bin:$PATH"

# === VERSIONS TO PIN ===
KUBECTL_VERSION="v1.29.0"
EKSCTL_VERSION="v0.174.0"
FLUX_VERSION="v2.2.3"
HELM_VERSION="v3.14.3"
PULUMI_VERSION="3.112.0"
NODE_VERSION="20.x"
DOCKER_COMPOSE_VERSION="2.20.2"
PYTHON_VERSION="3.11.8"

preconfigure() {
  echo "[*] Preconfiguring system to avoid interactive prompts..."
  sudo apt-get update -yq
  sudo apt-get install -yq debconf-utils
  for q in \
    "needrestart needrestart/restart boolean true" \
    "needrestart needrestart/restart-without-asking boolean true" \
    "needrestart needrestart/restart string a"; do
    echo "$q" | sudo debconf-set-selections
  done
  sudo sed -i 's/#\$nrconf{restart} = .*/\$nrconf{restart} = '\''a'\'';/' \
    /etc/needrestart/needrestart.conf || true
}

install_prereqs() {
  echo "[*] Installing base packages & pyenv build deps..."
  sudo apt-get update -yq
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential curl unzip wget gnupg lsb-release software-properties-common git \
    python3.10 python3.10-venv python3.10-dev python3-pip jq \
    make libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
}

install_pyenv() {
  echo "[*] Installing pyenv..."
  [ -d "$HOME/.pyenv" ] || git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  if ! grep -q 'export PYENV_ROOT' ~/.bashrc; then
    cat >> ~/.bashrc <<'EOF'

# pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
EOF
  fi
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
}

install_aws_cli() {
  echo "[*] Installing AWS CLI v2..."
  if ! command -v aws &>/dev/null; then
    rm -rf /tmp/aws /tmp/awscliv2.zip
    curl -fSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install --update
    rm -rf /tmp/aws /tmp/awscliv2.zip
  fi
}

install_kubectl() {
  echo "[*] Installing kubectl ${KUBECTL_VERSION}..."
  current="$(kubectl version --client --output=json 2>/dev/null | jq -r .clientVersion.gitVersion || echo)"
  if [[ "$current" != "$KUBECTL_VERSION" ]]; then
    rm -f kubectl
    curl -fSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o kubectl
    sudo install -m0755 kubectl /usr/local/bin/kubectl
    rm kubectl
  fi
}

install_eksctl() {
  echo "[*] Installing eksctl ${EKSCTL_VERSION}..."
  current="$(eksctl version 2>/dev/null || echo)"
  if [[ "$current" != "$EKSCTL_VERSION" ]]; then
    rm -f /tmp/eksctl.tar.gz
    curl -fSL \
      "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" \
      -o /tmp/eksctl.tar.gz
    tar -xzf /tmp/eksctl.tar.gz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin/eksctl
    rm /tmp/eksctl.tar.gz
  fi
}

install_flux() {
  echo "[*] Installing flux ${FLUX_VERSION}..."
  version="${FLUX_VERSION#v}"
  archive="flux_${version}_linux_amd64.tar.gz"
  rm -f "$archive" flux
  curl -fSL \
    "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/${archive}" \
    -o "$archive"
  tar -xzf "$archive"
  sudo mv flux /usr/local/bin/flux
  rm "$archive"
}

install_helm() {
  echo "[*] Installing helm ${HELM_VERSION}..."
  archive="helm-${HELM_VERSION}-linux-amd64.tar.gz"
  current="$(helm version --short --client 2>/dev/null || echo)"
  if [[ "$current" != "${HELM_VERSION}" ]]; then
    rm -rf "$archive" linux-amd64
    curl -fSL "https://get.helm.sh/${archive}" -o "$archive"
    tar -xzf "$archive"
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf "$archive" linux-amd64
  fi
}

install_pulumi() {
  echo "[*] Installing Pulumi ${PULUMI_VERSION}..."
  current="$(pulumi version 2>/dev/null || echo)"
  if [[ "$current" != "$PULUMI_VERSION" ]]; then
    curl -fSL https://get.pulumi.com | sh -s -- --version "${PULUMI_VERSION}" --yes
    export PATH="$PATH:$HOME/.pulumi/bin"
    grep -qxF 'export PATH=$PATH:$HOME/.pulumi/bin' ~/.bashrc || \
      echo 'export PATH=$PATH:$HOME/.pulumi/bin' >> ~/.bashrc
  fi
}

install_docker() {
  echo "[*] Installing Docker & Compose ${DOCKER_COMPOSE_VERSION}..."
  if ! command -v docker &>/dev/null; then
    curl -fSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh

  fi
  sudo usermod -aG docker "$USER" || true
  sudo apt-get remove -yq docker-compose || true
  sudo curl -fSL \
    "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  
}

install_node_vite() {
  echo "[*] Installing Node.js ${NODE_VERSION} & Vite..."
  curl -fSL "https://deb.nodesource.com/setup_${NODE_VERSION}" | sudo -E bash -
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq nodejs
  sudo npm install -g vite --no-progress
}

install_python() {
  echo "[*] Installing Python ${PYTHON_VERSION} via pyenv..."
  if ! pyenv versions --bare | grep -qx "${PYTHON_VERSION}"; then
    pyenv install "${PYTHON_VERSION}"
  fi
  [[ "$(pyenv global)" != "${PYTHON_VERSION}" ]] && pyenv global "${PYTHON_VERSION}"
}

# === MAIN ===
preconfigure
install_prereqs
install_pyenv
install_aws_cli
install_kubectl
install_eksctl
install_flux
install_helm
install_pulumi
install_docker
install_node_vite
install_python

echo
echo "[✓] All tools installed & pinned with zero interactive prompts."
echo "→ Open a new shell or run 'source ~/.bashrc' to use Python ${PYTHON_VERSION} by default."
