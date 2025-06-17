# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu Jammy (22.04)
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Mount current folder to /vagrant
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Always insert a unique SSH key for better security
  config.ssh.insert_key = true

  # VM resources
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 12
    vb.gui = false
  end

  # Forward commonly used ports
  [8265, 8001].each do |port|
    config.vm.network "forwarded_port", guest: port, host: port, auto_correct: true
  end

  # Basic provisioning
  config.vm.provision "shell", inline: <<-SHELL
    set -euxo pipefail
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      git \
      make \
      gh
  SHELL
end
