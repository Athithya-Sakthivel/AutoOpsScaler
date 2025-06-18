Vagrant.configure("2") do |config|
  # Long timeout for large images or slower hardware
  config.vm.boot_timeout = 3600

  # Use stable Ubuntu Jammy 22.04 box, pinned version for reproducibility
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Use rsync for reliable file sync
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Keep same SSH key for stable Remote SSH from VSCode
  config.ssh.insert_key = false

  # Use a static IP for predictable SSH and docker ports
  config.vm.network "private_network", ip: "192.168.56.18"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 6
    vb.gui = false

    # Make NAT DNS use host resolver for stable DNS
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "shell", inline: <<-SHELL

    #  Fix DNS permanently
    sudo sed -i 's/^#DNS=/DNS=8.8.8.8 1.1.1.1/' /etc/systemd/resolved.conf || true
    sudo sed -i 's/^#FallbackDNS=/FallbackDNS=8.8.4.4/' /etc/systemd/resolved.conf || true
    sudo systemctl restart systemd-resolved
    sudo rm -f /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

    #  Install base build tools
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      git \
      make \
      gh \
      ca-certificates \
      gnupg \
      lsb-release

    #  Setup Docker repo keyring idempotently
    sudo mkdir -p /etc/apt/keyrings

    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
      # Download key and dearmor only once
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --batch -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    #  Add Docker repo, replace if exists (idempotent)
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y

    #  Install specific tested Docker version
    DOCKER_VERSION="5:27.5.1-1~ubuntu.22.04~jammy"

    # Install only if not already installed with exact version
    if ! dpkg -l | grep -q "docker-ce.*${DOCKER_VERSION}"; then
      sudo apt-get install -y \
        docker-ce=${DOCKER_VERSION} \
        docker-ce-cli=${DOCKER_VERSION} \
        containerd.io
    fi

    #  Hold packages to prevent automatic upgrades
    sudo apt-mark hold docker-ce docker-ce-cli containerd.io

    #  Add vagrant to docker group if not already in it
    if ! id vagrant | grep -q docker; then
      sudo usermod -aG docker vagrant
    fi

    echo " Docker installed, version pinned, DNS fixed, user permissions configured."
  SHELL
end
