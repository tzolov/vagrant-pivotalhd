# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

require 'set'
require 'rubygems'
require 'json'

# Set the name of the cluster to be deployed
CLUSTER_NAME = "PHD30C1"

# Provide the path to the blueprint file to use
BLUEPRINT_FILE = "blueprints/all-phd3-hawq-services-blueprint.json"

# Provide the path to the host-mapping file that uses the above blueprint 
# to deploy the cluster
HOST_MAPPING_FILE = "blueprints/4-node-all-services-hostmapping.json"

# Set the Ambari host name (THE FQDN NAME SHOULD NOT be in the phd[1-N].localdomain range)
AMBARI_HOSTNAME_PREFIX = "ambari"

# Specify the Vagrant box name to use. Tested options are:
#   bigdata/centos6.4_x86_64 - 40G disk space.
#   bigdata/centos6.4_x86_64_small - just 8G of disk space. Not enough for Hue!
VM_BOX = "bigdata/centos6.4_x86_64"

# Set the memory (MB) allocated for the AMBARI VM
AMBARI_MEMORY_MB = "768"

# Set the memory (MB) allocated for every PHD node VM
WORKER_PHD_MEMORY_MB = "2048"

###############################################################################
#    DON'T CHANGE THE CONTENT BELOW
###############################################################################

# Create an Ambari FQDN hostname from the prefix and the localdomain domain. 
AMBARI_HOSTNAME_FQDN = "#{AMBARI_HOSTNAME_PREFIX}.localdomain"

# Parse the blueprint spec
blueprint_spec = JSON.parse(open(BLUEPRINT_FILE).read)
BLUEPRINT_SPEC_NAME = blueprint_spec["Blueprints"]["blueprint_name"]
print "CLUSTER: #{CLUSTER_NAME} \n"
print "BLUEPRINT: #{BLUEPRINT_SPEC_NAME} \n"
print "STACK: #{blueprint_spec['Blueprints']['stack_name']}-#{blueprint_spec['Blueprints']['stack_version']} \n"

# Read the host-mapping file to extract the blueprint name and the 
# cluster node hostnames
host_mapping = JSON.parse(open(HOST_MAPPING_FILE).read)

# Extract the Blueprint name from the host mapping file
BLUEPRINT_NAME = host_mapping["blueprint"]

# Validate that the Blueprint set in the host mapping file aligns with the name of the blueprint provided
if (BLUEPRINT_SPEC_NAME != BLUEPRINT_NAME)
	print "Blueprint in the host mapping file:(#{BLUEPRINT_NAME}) doesn't match  provided blueprint spec: (#{BLUEPRINT_SPEC_NAME})! \n"
	exit
end

print "HOST-MAPPING FILE: #{HOST_MAPPING_FILE} \n"

# List of cluster node hostnames. Convention is: 'phd<Number>.localdomain'
NODES = Set.new([])

# Extract the cluster hostnames from the blueprint host mapping file
host_mapping["host_groups"].each do |group|
  group["hosts"].each do |host| NODES << host["fqdn"].strip end
end

# Ambari host can be use to deploy services but should not be part of the phd[1-n] range
# as it is provisioned differently 
NODES.delete(AMBARI_HOSTNAME_FQDN);

# Compute the total number of nodes in the cluster 	    
NUMBER_OF_CLUSTER_NODES = NODES.size

print "Number of cluster nodes (excluding Ambari): #{NUMBER_OF_CLUSTER_NODES} \n"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  # Provision VM for every PHD node
  (1..NUMBER_OF_CLUSTER_NODES).each do |i|

    phd_vm_name = "phd#{i}"
    
    phd_host_name = "phd#{i}.localdomain"
    
    # Compute the memory
    vm_memory_mb = WORKER_PHD_MEMORY_MB

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
        s.path = "provision/prepare_host.sh"
        s.args = [AMBARI_HOSTNAME_PREFIX, 
                  AMBARI_HOSTNAME_FQDN, 
                  NUMBER_OF_CLUSTER_NODES]
      end 
	  
      #Fix hostname FQDN
      phd_conf.vm.provision :shell, :inline => "hostname #{phd_host_name}"
    end
  end

  # Provision Ambari VM. Install Ambari Server and deploy a PHD cluster
  AMBARI_VM_NAME = AMBARI_HOSTNAME_PREFIX
  
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

   ambari.vm.hostname = AMBARI_HOSTNAME_FQDN
   ambari.vm.network :private_network, ip: "10.211.55.100"
   ambari.vm.network :forwarded_port, guest: 5443, host: 5443

   # Initialization common for all nodes
   ambari.vm.provision "shell" do |s|
     s.path = "provision/prepare_host.sh"
     s.args = [AMBARI_HOSTNAME_PREFIX, 
               AMBARI_HOSTNAME_FQDN, 
               NUMBER_OF_CLUSTER_NODES]
   end
   
   # Install Ambari Server
   ambari.vm.provision "shell" do |s|
     s.path = "provision/install_ambari.sh"
   end 

   # Register the Ambari Agents and all nodes
   ambari.vm.provision "shell" do |s|
     s.path = "provision/register_agents.sh"
     s.args = NUMBER_OF_CLUSTER_NODES
   end

   # Fix hostname FQDN
   ambari.vm.provision :shell, :inline => "hostname " + AMBARI_HOSTNAME_FQDN

   # Deploy Hadoop Cluster & Services
   ambari.vm.provision "shell" do |s|
     s.path = "provision/deploy_cluster.sh"
	 s.args = [AMBARI_HOSTNAME_FQDN, 
	           CLUSTER_NAME, 
	           BLUEPRINT_NAME, 
	           "/vagrant/" + BLUEPRINT_FILE, 
	           "/vagrant/" + HOST_MAPPING_FILE]
   end    
  end
end
