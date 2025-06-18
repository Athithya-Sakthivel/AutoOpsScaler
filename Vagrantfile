Vagrant.configure("2") do |config|
  # Increase boot timeout to 1 hour (3600 seconds)
  config.vm.boot_timeout = 3600

  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Use rsync for faster file access
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Keep the same SSH key for stable Remote SSH
  config.ssh.insert_key = false

  # Use a static private network IP for reliable access
  config.vm.network "private_network", ip: "192.168.56.12"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 6
    vb.gui = false

    # Ensure NAT DNS uses the host's resolver for stable internet DNS
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    # Fix DNS
    sudo sed -i 's/^#DNS=/DNS=8.8.8.8 1.1.1.1/' /etc/systemd/resolved.conf
    sudo sed -i 's/^#FallbackDNS=/FallbackDNS=8.8.4.4/' /etc/systemd/resolved.conf
    sudo systemctl restart systemd-resolved
    sudo rm -f /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

    # Basic tools
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

    # Install Docker with version pinning
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y

    # Check available Docker versions
    sudo apt-cache madison docker-ce

    # Install specific tested Docker version 
    sudo apt-get install -y \
      docker-ce=5:27.5.1-1~ubuntu.22.04~jammy \
      docker-ce-cli=5:27.5.1-1~ubuntu.22.04~jammy \
      containerd.io

    # Hold Docker packages to prevent auto-updates
    sudo apt-mark hold docker-ce docker-ce-cli containerd.io

    # Add vagrant user to docker group
    sudo usermod -aG docker vagrant

    echo "Docker installed and version pinned successfully."
  SHELL
end
