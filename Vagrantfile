# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # consul cluster
  clusterIPs = ["192.168.9.91", "192.168.9.92", "192.168.9.93"]
  requiredPorts = [8300, 8301, 8302, 8400, 8500, 8501, 8502, 8600, 3000]

  clusterIPs.each_with_index do |ip, index|
	  config.vm.define "consul-node-#{index}" do |cs|

      # using ubuntu 18.04
      cs.vm.box = "ubuntu/bionic64"
      # host ip
      cs.vm.network "private_network", ip: "#{ip}"

      #set hostname
      cs.vm.hostname = "node-#{index}"


      requiredPorts.each do |port|
        base = index * 1000
        cs.vm.network "forwarded_port", guest: "#{port}", host: "#{port + base}"
      end

      cs.vm.provision "shell" do |provisioner|
        provisioner.path = "./scripts/server.sh"
        provisioner.args = ["node-#{index}"]
      end


      cs.vm.provider "virtualbox" do |vb|
        vb.memory = 512
      end

    end
  end
end
