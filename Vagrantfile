# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  #  Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  #  Shared folder
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  #  Let Vagrant generate a fresh SSH key every run
  config.ssh.insert_key = true

  #  VM resources
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 12
    vb.gui = false
  end

  #  Port forwarding (autocorrect true ensures no conflicts)
  [
    8265,  # Ray dashboard
    8001,  # kubectl proxy
  ].each do |port|
    config.vm.network "forwarded_port", guest: port, host: port, auto_correct: true
  end

  #  Minimal provisioner
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
