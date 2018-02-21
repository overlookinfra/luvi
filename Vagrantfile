# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "genebean/centos-7-docker-ce"
  config.vm.provision "shell", privileged: false, inline: <<-EOF
    set -xe
    sudo yum -y install git
    mkdir -p /home/vagrant/ws/src/luvi
    rsync --delete -rt /vagrant/ /home/vagrant/ws/src/luvi/
    cd /home/vagrant/ws/src/luvi
    make armv6l-build-box-regular
    cp /home/vagrant/ws/src/luvi/luvi-regular-Linux_armv6l /vagrant/
  EOF

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end
end

