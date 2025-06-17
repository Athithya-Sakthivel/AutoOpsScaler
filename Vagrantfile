Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # ⚡ Use rsync for faster file access
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Keep the same SSH key for stable Remote SSH
  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 8
    vb.gui = false
  end

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
