Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  config.vm.network "private_network", ip: "192.168.56.51"
  # comment removed config.ssh.insert_key
  config.vm.boot_timeout = 1800

  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive

    echo "[*] Forcing safe apt mirror to avoid 404s..."
    sed -i 's|http://.*.ubuntu.com|http://archive.ubuntu.com|g' /etc/apt/sources.list
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    apt-get update -o Acquire::Retries=3

    echo "[*] Installing required packages (safe and idempotent)..."
    REQUIRED_PKGS=(
      curl unzip lsb-release sudo software-properties-common
      build-essential python3 python3-pip tree gh make lsof fuse-overlayfs
    )
    for pkg in "${REQUIRED_PKGS[@]}"; do
      dpkg -s "$pkg" >/dev/null 2>&1 || apt-get install -y --no-install-recommends "$pkg"
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

    echo "[*] Setting default login directory for vagrant..."
    grep -qxF 'cd /vagrant' /home/vagrant/.bashrc || echo 'cd /vagrant' >> /home/vagrant/.bashrc
    chown vagrant:vagrant /home/vagrant/.bashrc
    echo "[*] Cleaning up..."
    apt-get clean
    rm -rf /var/lib/apt/lists/*
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "11000"
    vb.cpus = 6
  end
end
