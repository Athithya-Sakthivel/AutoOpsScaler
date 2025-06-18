#!/usr/bin/env bash

# === CONFIG ===
export DEBIAN_FRONTEND=noninteractive


# Add local pip bin to PATH if not already
export PATH="$HOME/.local/bin:$PATH"
export PYTHONPATH=$(pwd)
source ~/.bashrc


KUBECTL_VERSION="v1.29.0"
EKSCTL_VERSION="v0.174.0"
FLUX_VERSION="v2.2.3"
HELM_VERSION="v3.14.3"
PULUMI_VERSION="3.112.0"
NODE_VERSION="20.x"
DOCKER_COMPOSE_VERSION="2.27.0"

# === FUNCTIONS ===

preconfigure() {
    echo "[*] Preconfiguring system to avoid interactive prompts..."
    sudo apt-get update -y
    sudo apt-get install -y debconf-utils
    echo "needrestart needrestart/restart string a" | sudo debconf-set-selections
    sudo sed -i 's/#\$nrconf{restart} = .*/\$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf || true
}

install_prereqs() {
    echo "[*] Installing base packages..."
    sudo apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq \
        build-essential \
        curl \
        unzip \
        wget \
        gnupg \
        lsb-release \
        software-properties-common \
        git \
        python3.10 \
        python3.10-venv \
        python3.10-dev \
        python3-pip \
        jq
}

install_python_venv_tools() {
    echo "[*] Ensuring Python 3.10 venv and pip..."
    PY_VER=$(python3.10 --version 2>/dev/null || true)
    if [[ -z "$PY_VER" ]]; then
        echo "[!] Python 3.10 not found. Please check OS version."
        exit 1
    fi
    python3.10 -m ensurepip --upgrade || true
    python3.10 -m pip install --upgrade pip setuptools wheel
}

install_aws_cli() {
    echo "[*] Installing AWS CLI v2..."
    if ! command -v aws &>/dev/null; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
        unzip -q /tmp/awscliv2.zip -d /tmp
        sudo /tmp/aws/install --update
        rm -rf /tmp/aws /tmp/awscliv2.zip
    else
        echo "[=] AWS CLI already installed."
    fi
}

install_kubectl() {
    echo "[*] Installing kubectl ${KUBECTL_VERSION}..."
    CURRENT_KUBECTL="$(kubectl version --client --output=json 2>/dev/null | jq -r .clientVersion.gitVersion || echo '')"
    if [[ "${CURRENT_KUBECTL}" != "${KUBECTL_VERSION}" ]]; then
        curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    else
        echo "[=] kubectl ${KUBECTL_VERSION} already installed."
    fi
}

install_eksctl() {
    echo "[*] Installing eksctl ${EKSCTL_VERSION}..."
    CURRENT_EKSCTL="$(eksctl version 2>/dev/null || echo '')"
    if [[ "${CURRENT_EKSCTL}" != "${EKSCTL_VERSION}" ]]; then
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/eksctl /usr/local/bin
    else
        echo "[=] eksctl ${EKSCTL_VERSION} already installed."
    fi
}

install_flux() {
  echo "Installing flux ${FLUX_VERSION}..."
  curl -LO "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz"
  tar -xzf "flux_${FLUX_VERSION}_linux_amd64.tar.gz"
  sudo mv flux /usr/local/bin/flux
  rm -f "flux_${FLUX_VERSION}_linux_amd64.tar.gz"
}

install_helm() {
    echo "[*] Installing helm ${HELM_VERSION}..."
    CURRENT_HELM="$(helm version --short --client 2>/dev/null || echo '')"
    if [[ "${CURRENT_HELM}" != "v${HELM_VERSION}" ]]; then
        curl -LO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
        tar -zxvf "helm-v${HELM_VERSION}-linux-amd64.tar.gz"
        sudo mv linux-amd64/helm /usr/local/bin/helm
        rm -rf linux-amd64 "helm-v${HELM_VERSION}-linux-amd64.tar.gz"
    else
        echo "[=] helm ${HELM_VERSION} already installed."
    fi
}

install_pulumi() {
    echo "[*] Installing Pulumi ${PULUMI_VERSION}..."
    CURRENT_PULUMI="$(pulumi version 2>/dev/null || echo '')"
    if [[ "${CURRENT_PULUMI}" != "${PULUMI_VERSION}" ]]; then
        curl -fsSL https://get.pulumi.com | sh -s -- --version ${PULUMI_VERSION}
        export PATH=$PATH:$HOME/.pulumi/bin
        grep -qxF 'export PATH=$PATH:$HOME/.pulumi/bin' ~/.bashrc || echo 'export PATH=$PATH:$HOME/.pulumi/bin' >> ~/.bashrc
    else
        echo "[=] Pulumi ${PULUMI_VERSION} already installed."
    fi
}

install_docker() {
    echo "[*] Installing Docker and Docker Compose ${DOCKER_COMPOSE_VERSION}..."
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        newgrp docker
    else
        echo "[=] Docker already installed."
    fi

    sudo usermod -aG docker "$USER" || true
    sudo apt-get remove docker-compose -y || true
    sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    newgrp docker

    echo "[*] Activating docker group permissions..."
    newgrp docker <<EONG
echo "[=] Docker group refreshed."
EONG
}

install_node_vite() {
    echo "[*] Installing Node.js ${NODE_VERSION} and Vite..."
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | sudo -E bash -
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq nodejs
    sudo npm install -g vite
}

# === MAIN ===

preconfigure
install_prereqs
install_python_venv_tools
install_aws_cli
install_kubectl
install_eksctl
install_flux
install_helm
install_pulumi
install_docker
install_node_vite

echo "[✓] All tools installed and pinned successfully. Non-interactive run complete."


