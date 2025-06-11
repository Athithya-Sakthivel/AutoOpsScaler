Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 (Jammy Jellyfish)
  config.vm.box          = "ubuntu/jammy64"
  config.vm.box_version  = "20241002.0.0"

  # Static private IP
  config.vm.network "private_network", ip: "192.168.56.52"

  # Disable automatic SSH key insertion
  config.ssh.insert_key = false

  # Extended boot timeout
  config.vm.boot_timeout = 1800

  # Provision block: strict idempotency, edge-case resilient
  config.vm.provision "shell", inline: <<-SHELL
    #!/usr/bin/env bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive

    echo "[*] Redirecting security.ubuntu.com → archive.ubuntu.com to avoid 404s"
    sed -i 's|http://security.ubuntu.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list

    echo "[*] Updating APT metadata and upgrading existing packages…"
    apt-get update -y
    apt-get upgrade -y

    echo "[*] Ensuring all essential packages are installed…"
    REQUIRED_PKGS=(
      curl unzip lsb-release sudo software-properties-common
      build-essential libc-dev python3 python3-pip tree gh make lsof fuse-overlayfs
    )
    for pkg in "${REQUIRED_PKGS[@]}"; do
      if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "installed"; then
        apt-get install -y --no-install-recommends --fix-missing "$pkg"
      else
        echo "[✔] $pkg already installed."
      fi
    done

    echo "[*] Installing Docker if not present…"
    if ! command -v docker >/dev/null 2>&1; then
      curl -fsSL https://get.docker.com | sh
    else
      echo "[✔] Docker already installed."
    fi

    echo "[*] Adding 'vagrant' to docker group…"
    if ! id -nG vagrant | grep -qw docker; then
      usermod -aG docker vagrant
    else
      echo "[✔] 'vagrant' is already in the docker group."
    fi

    echo "[*] Enabling and starting Docker service…"
    if ! systemctl is-enabled docker >/dev/null 2>&1; then
      systemctl enable docker
    fi
    if ! systemctl is-active docker >/dev/null 2>&1; then
      systemctl start docker
    fi

    echo "[*] Setting default login directory to /vagrant for vagrant user…"
    PROFILE_LINE='cd /vagrant'
    if ! grep -qxF "$PROFILE_LINE" /home/vagrant/.bashrc; then
      echo "$PROFILE_LINE" >> /home/vagrant/.bashrc
      chown vagrant:vagrant /home/vagrant/.bashrc
    else
      echo "[✔] Default login directory already set."
    fi

    echo "[*] Cleaning up APT caches…"
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    echo "[✔] Provisioning complete."
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "11000"
    vb.cpus   = 6
  end
end
