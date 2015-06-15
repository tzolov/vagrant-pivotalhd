# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

require 'set'
require 'rubygems'
require 'json'

# Node(s) to be used as a master. Convention is: 'phd<Number>.localdomain'. Exactly One master node must be provided
MASTER = ["phd1.localdomain"]

# Node(s) to be used as a Workers. Convention is: 'phd<Number>.localdomain'. At least one worker node is required
# The master node can be reused as a worker. 
WORKERS = ["phd1.localdomain", "phd2.localdomain", "phd3.localdomain"]

# Vagrant box name
#   bigdata/centos6.4_x86_64 - 40G disk space.
#   bigdata/centos6.4_x86_64_small - just 8G of disk space. Not enough for Hue!
VM_BOX = "bigdata/centos6.4_x86_64"

# Memory (MB) allocated for the master PHD VM
MASTER_PHD_MEMORY_MB = "2048"

# Memory (MB) allocated for every PHD node VM
WORKER_PHD_MEMORY_MB = "2048"

# Memory (MB) allocated for the AMBARI VM
AMBARI_MEMORY_MB = "768"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Compute the total number of nodes in the cluster 	    
  NUMBER_OF_CLUSTER_NODES = (MASTER + WORKERS).uniq.size
  
  # Create VM for every PHD node
  (1..NUMBER_OF_CLUSTER_NODES).each do |i|

    phd_vm_name = "phd#{i}"
    
    phd_host_name = "phd#{i}.localdomain"
    
    # Compute the memory
    vm_memory_mb = (MASTER.include? phd_host_name) ? MASTER_PHD_MEMORY_MB : WORKER_PHD_MEMORY_MB

    config.vm.define phd_vm_name.to_sym do |phd_conf|
      phd_conf.vm.box = VM_BOX
      phd_conf.vm.provider :virtualbox do |v|
        v.name = phd_vm_name
        v.customize ["modifyvm", :id, "--memory", vm_memory_mb]
      end
      phd_conf.vm.provider "vmware_fusion" do |v|
        v.name = phd_vm_name
        v.vmx["memsize"]  = vm_memory_mb
      end     	  

      phd_conf.vm.host_name = phd_host_name    
      phd_conf.vm.network :private_network, ip: "10.211.55.#{i+100}"	  

      phd_conf.vm.provision "shell" do |s|
        s.path = "scripts/prepare_host.sh"
        s.args = NUMBER_OF_CLUSTER_NODES
      end 
	  
      #Fix hostname FQDN
      phd_conf.vm.provision :shell, :inline => "hostname #{phd_host_name}"
    end
  end

  # Create Ambari VM, install Ambari and deploy a PHD cluster
  AMBARI_VM_NAME = "ambari"
  
  config.vm.define AMBARI_VM_NAME do |ambari|   
   
   ambari.vm.box = VM_BOX

   ambari.vm.provider :virtualbox do |v|
     v.name = AMBARI_VM_NAME
     v.customize ["modifyvm", :id, "--memory", AMBARI_MEMORY_MB]
   end

   ambari.vm.provider "vmware_fusion" do |v|
     v.name = AMBARI_VM_NAME
     v.vmx["memsize"]  = AMBARI_MEMORY_MB
   end  

   ambari.vm.hostname = "ambari.localdomain"
   ambari.vm.network :private_network, ip: "10.211.55.100"
   ambari.vm.network :forwarded_port, guest: 5443, host: 5443

   # Initialization common for all nodes
   ambari.vm.provision "shell" do |s|
     s.path = "scripts/prepare_host.sh"
     s.args = NUMBER_OF_CLUSTER_NODES
   end
   
   # Install Ambari 
   ambari.vm.provision "shell" do |s|
     s.path = "scripts/install_ambari.sh"
   end 

   # Register ambari-agents
   ambari.vm.provision "shell" do |s|
     s.path = "scripts/register_agents.sh"
     s.args = NUMBER_OF_CLUSTER_NODES
   end

   # Fix hostname FQDN
   ambari.vm.provision :shell, :inline => "hostname ambari.localdomain"

   # Install Ambari 
   ambari.vm.provision "shell" do |s|
     s.path = "scripts/deploy_cluster.sh"
	 s.args = "4-node-blueprint"
   end 
   
  end
end
