# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define "lockfile-tasks.puppet.vm" do |node|
    node.vm.box = "puppetlabs/centos-7.2-64-nocm"
    node.vm.hostname = "lockfile-tasks.puppet.vm"

    node.vm.provision "shell", inline: <<-SHELL
      sudo echo "vagrant" | passwd "vagrant" --stdin
      wget -O - https://raw.githubusercontent.com/petems/puppet-install-shell/master/install_puppet_5_agent.sh | sudo sh
    SHELL
  end

end

