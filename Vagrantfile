Vagrant.configure("2") do |config|
  # Extend boot timeout for large images or slow hardware
  config.vm.boot_timeout = 3600

  # Use official Ubuntu Jammy 22.04 box, pinned version for consistency
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Use rsync for file sync (faster for large file sets than VirtualBox shared folders)
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Use stable SSH key for consistent remote SSH (keeps VS Code Remote SSH stable)
  config.ssh.insert_key = false

  # Use a static private network IP to avoid DHCP conflicts
  config.vm.network "private_network", ip: "192.168.56.12"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 6
    vb.gui = false

    # Use host DNS resolver for stable external DNS
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "shell", inline: <<-SHELL
    set -eux

    # Fix DNS configuration permanently
    sudo sed -i 's/^#DNS=/DNS=8.8.8.8 1.1.1.1/' /etc/systemd/resolved.conf || true
    sudo sed -i 's/^#FallbackDNS=/FallbackDNS=8.8.4.4/' /etc/systemd/resolved.conf || true
    sudo systemctl restart systemd-resolved
    sudo rm -f /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

    # Install base developer tools
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

    # Setup Docker APT repository securely, avoiding /dev/tty issue with --batch
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --batch -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y

    # Install tested pinned Docker version
    sudo apt-get install -y \
      docker-ce=5:27.5.1-1~ubuntu.22.04~jammy \
      docker-ce-cli=5:27.5.1-1~ubuntu.22.04~jammy \
      containerd.io

    # Prevent Docker from being auto-updated by APT
    sudo apt-mark hold docker-ce docker-ce-cli containerd.io

    # Add vagrant user to docker group only if not already present
    if ! id vagrant | grep -q docker; then
      sudo usermod -aG docker vagrant
    fi

    echo "Docker installed, version pinned, user permissions updated."
  SHELL
end
