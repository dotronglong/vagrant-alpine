# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "dotronglong/alpine"
  config.vm.box_check_update = false
  config.vm.network "private_network", ip: "192.168.33.11"
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "4096"
     vb.cpus = 2
  end
  #config.vm.synced_folder "./provisions/nginx/conf.d", "/etc/nginx/conf.d", type: "nfs"
  config.vm.provision "shell", path: "./provisions/php5.sh"
end
