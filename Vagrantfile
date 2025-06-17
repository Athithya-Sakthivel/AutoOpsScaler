# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu Jammy (22.04)
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Mount the current host working directory to /vagrant
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Avoid SSH key regeneration
  config.ssh.insert_key = false

  # VM resources
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 12
    vb.gui = false
  end

  # LLMOps: forward essential ports
  [
    8265,  # Ray Dashboard
    8001,  # kubectl proxy

  ].each do |port|
    config.vm.network "forwarded_port", guest: port, host: port, auto_correct: true
  end

  # Idempotent shell provisioning
  config.vm.provision "shell", inline: <<-SHELL
    set -euxo pipefail
    cd /vagrant

    # Update and install base tools
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      git \
      make
  SHELL
end
