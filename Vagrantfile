Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 (Jammy Jellyfish)
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Static private IP
  config.vm.network "private_network", ip: "192.168.56.51"

  # Disable automatic SSH key insertion
  config.ssh.insert_key = false

  # Extended boot timeout
  config.vm.boot_timeout = 1800

  # Provision block: strict idempotency, edge-case resilient
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive

    # Essential packages
    REQUIRED_PKGS=(
      curl unzip lsb-release sudo software-properties-common
      build-essential python3 python3-pip tree gh make lsof fuse-overlayfs
    )

    echo "[*] Ensuring all essential packages are installed..."
    for pkg in "${REQUIRED_PKGS[@]}"; do
      dpkg -s "$pkg" >/dev/null 2>&1 || apt-get install -y "$pkg"
    done

    echo "[*] Installing Docker if not present..."
    if ! command -v docker >/dev/null 2>&1; then
      curl -fsSL https://get.docker.com | sh
    else
      echo "[✔] Docker already installed."
    fi

    echo "[*] Adding 'vagrant' to docker group..."
    id -nG vagrant | grep -qw docker || usermod -aG docker vagrant

    echo "[*] Enabling and starting Docker..."
    systemctl is-enabled docker >/dev/null 2>&1 || systemctl enable docker
    systemctl is-active docker >/dev/null 2>&1 || systemctl start docker

    echo "[*] Cleaning up..."
    apt-get clean
    rm -rf /var/lib/apt/lists/*
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "11000"
    vb.cpus = 6
  end
end