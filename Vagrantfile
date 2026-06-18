# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

LAB_DOMAIN = "lab.example.com"
BASE_BOX   = "generic/rhel9"   # change here if you build your own RHEL 9.6 box

LAB_NODES = {
  "controller" => { ip: "192.168.56.10" },
  "reposerver" => { ip: "192.168.56.11" },
  "servera"    => { ip: "192.168.56.21" },
  "serverb"    => { ip: "192.168.56.22" },
  "serverc"    => { ip: "192.168.56.23" },
  "serverd"    => { ip: "192.168.56.24" },
  "servere"    => { ip: "192.168.56.25" }
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box_check_update = false

  LAB_NODES.each do |name, opts|
    config.vm.define name do |node|
      node.vm.box = BASE_BOX
      node.vm.hostname = "#{name}.#{LAB_DOMAIN}"

      # Private host-only network
      node.vm.network "private_network",
                      ip: opts[:ip],
                      virtualbox__intnet: true

      node.vm.provider "virtualbox" do |vb|
        vb.name   = "RH_ENG_2026_#{name}"
        vb.memory = 2048
        vb.cpus   = 2
      end

      # Sync repo into /vagrant on the guest (default)
      node.vm.synced_folder ".", "/vagrant"

      # Base provisioning for all nodes
      node.vm.provision "shell",
                        path: "provision/bootstrap.sh",
                        args: [name, opts[:ip]]

      # Extra provisioning only for controller
      if name == "controller"
        node.vm.provision "shell",
                          path: "provision/controller.sh",
                          privileged: true
      end
    end
  end
end
