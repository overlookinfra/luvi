# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "genebean/centos-7-docker-ce"
  config.vm.provision "shell", inline: <<-EOF
    set -xe
    yum -y install git
    mkdir /root/workdir
    git clone https://github.com/genebean/luvi.git /root/workdir/luvi
    cd /root/workdir/luvi
    git checkout arm-updates
    make armv6l-build-box-regular
    make armv7l-build-box-regular
    cp /root/workdir/luvi/luvi-regular-Linux_armv* /vagrant/
  EOF

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end
end

