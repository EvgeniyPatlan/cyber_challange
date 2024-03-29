Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.network "private_network", ip: "192.168.56.11"
  config.vm.network "forwarded_port", guest: 22, host: 2024, protocol: "tcp"
  config.vm.network "forwarded_port", guest: 80, host: 80, protocol: "tcp"
  config.vm.provision "shell", path: "bootstrap.sh"
end
