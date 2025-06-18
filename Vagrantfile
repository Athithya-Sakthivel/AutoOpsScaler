Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Use rsync for faster file access
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Keep the same SSH key for stable Remote SSH
  config.ssh.insert_key = false

  # ✅ Use a static private network IP for reliable access
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 11000
    vb.cpus = 6
    vb.gui = false

    # ✅ Ensure NAT DNS uses the host's resolver for stable internet DNS
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "shell", inline: <<-SHELL
    # ✅ Make sure DNS uses Google's and Cloudflare's servers
    sudo sed -i 's/^#DNS=/DNS=8.8.8.8 1.1.1.1/' /etc/systemd/resolved.conf
    sudo sed -i 's/^#FallbackDNS=/FallbackDNS=8.8.4.4/' /etc/systemd/resolved.conf
    sudo systemctl restart systemd-resolved
    sudo rm -f /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

    # ✅ Install basic tools
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      git \
      make \
      gh
  SHELL
end
