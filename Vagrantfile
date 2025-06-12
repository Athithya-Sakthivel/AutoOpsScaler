Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20231027.0.0"
  config.vm.network "private_network", ip: "192.168.56.51"

  # 🔓 Forward all important ports from guest → host
  config.vm.network "forwarded_port", guest: 30001, host: 30001  # Grafana
  config.vm.network "forwarded_port", guest: 30002, host: 30002  # Prometheus
  config.vm.network "forwarded_port", guest: 30080, host: 30080  # Karpenter webhook / future
  config.vm.network "forwarded_port", guest: 30443, host: 30443  # TLS webhook / test services
  config.vm.network "forwarded_port", guest: 32000, host: 32000  # Playwright/Scrapy dashboards
  config.vm.network "forwarded_port", guest: 31000, host: 31000  # NodePort app test svc
  config.vm.network "forwarded_port", guest: 30333, host: 30333  # ArgoCD UI (if local)

  config.ssh.insert_key = true
  config.vm.boot_timeout = 2500

  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive

    echo "[*] Switching to archive.ubuntu.com mirror..."
    sed -i 's|http://.*.ubuntu.com|http://archive.ubuntu.com|g' /etc/apt/sources.list
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    apt-get update -o Acquire::Retries=3

    echo "[*] Installing required packages..."
    REQUIRED_PKGS=(
      curl unzip lsb-release sudo software-properties-common
      build-essential python3 python3-pip tree gh make lsof fuse-overlayfs
    )
    for pkg in "${REQUIRED_PKGS[@]}"; do
      dpkg -s "$pkg" >/dev/null 2>&1 || apt-get install -y --no-install-recommends "$pkg"
    done

    echo "[*] Installing Docker..."
    if ! command -v docker >/dev/null 2>&1; then
      curl -fsSL https://get.docker.com | sh
    fi

    echo "[*] Adding user to docker group..."
    id -nG vagrant | grep -qw docker || usermod -aG docker vagrant

    echo "[*] Enabling Docker..."
    systemctl enable docker || true
    systemctl start docker || true

    echo "[*] Set vagrant default login dir..."
    grep -qxF 'cd /vagrant' /home/vagrant/.bashrc || echo 'cd /vagrant' >> /home/vagrant/.bashrc
    chown vagrant:vagrant /home/vagrant/.bashrc

    echo "[*] Clean apt cache..."
    apt-get clean
    rm -rf /var/lib/apt/lists/*
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "11000"
    vb.cpus = 6
  end
end
