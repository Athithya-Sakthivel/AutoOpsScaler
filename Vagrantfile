Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 3600
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Pulumi plugin sync (slower in vagrant)
  config.vm.synced_folder ".pulumi-host-plugins", "/home/vagrant/.pulumi-host-plugins", type: "rsync", create: true
  config.ssh.insert_key = false
  config.vm.network "private_network", ip: "192.168.56.18"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 6
    vb.gui = false
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -euxo pipefail

    # Fix DNS permanently
    sudo sed -i 's/^#DNS=/DNS=8.8.8.8 1.1.1.1/' /etc/systemd/resolved.conf || true
    sudo sed -i 's/^#FallbackDNS=/FallbackDNS=8.8.4.4/' /etc/systemd/resolved.conf || true
    sudo systemctl restart systemd-resolved
    sudo rm -f /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

    # Base tools
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends \
      build-essential curl git make gh ca-certificates gnupg lsb-release

    # Docker install (pinned)
    DOCKER_VERSION="5:27.5.1-1~ubuntu.22.04~jammy"
    sudo mkdir -p /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    if ! dpkg -l | grep -q "docker-ce.*${DOCKER_VERSION}"; then
      sudo apt-get install -y \
        docker-ce=${DOCKER_VERSION} \
        docker-ce-cli=${DOCKER_VERSION} \
        containerd.io
    fi
    sudo apt-mark hold docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker vagrant

    # Pulumi plugins
    mkdir -p ~/.pulumi/plugins
    cp -r ~/.pulumi-host-plugins/* ~/.pulumi/plugins/ || true
    echo "✔️ Pulumi plugins injected."
  SHELL
end
