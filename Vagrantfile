Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 (Jammy Jellyfish)
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Set a static IP to avoid conflicts
  config.vm.network "private_network", ip: "192.168.56.50"

  # Disable automatic SSH key insertion
  config.ssh.insert_key = false

  # Provision with essential tools, Docker, and permissions
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y \
      curl \
      unzip \
      lsb-release \
      sudo \
      software-properties-common \
      build-essential \
      python3 \
      python3-pip \
      tree \
      gh \
      make \
      lsof \
      fuse-overlayfs

    # Install Docker (latest from Docker's official repo)
    curl -fsSL https://get.docker.com | sh

    # Add vagrant user to docker group for non-root docker usage
    usermod -aG docker vagrant

    # Enable and start Docker service
    systemctl enable docker
    systemctl start docker

    apt-get clean
    rm -rf /var/lib/apt/lists/*
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "11000"
    vb.cpus = 6
  end
end
