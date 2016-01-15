# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

require 'set'
require 'rubygems'
require 'json'

###############################################################################
#   CONFIGURATION PARAMETERS
###############################################################################
# Edit the following parameters to configure your cluster deployment. 

# Set the Blueprint file name that defines the cluster to be deployed. 
# File must exist under the /blueprints subfolder!
# Sample HDP blueprint: BLUEPRINT_FILE_NAME = "hdp-hdfs-yarn-springxd-zk-blueprint.json"
# BLUEPRINT_FILE_NAME = "phd33-hdfs-hawq-blueprint.json"
BLUEPRINT_FILE_NAME = "blueprint.test.json"

# Set the Host-Mapping file name that maps the above Blueprint into physical nodes. 
# File must exist under the /blueprints subfolder!
# Sample HDP host mapping: HOST_MAPPING_FILE_NAME = "2-node-hdfs-yarn-springxd-zk-blueprint-hostmapping.json"
HOST_MAPPING_FILE_NAME = "2-node-test-hostmapping.json"

# Set the name of the cluster to be deployed
CLUSTER_NAME = "CLUSTER1"

# Specify the Vagrant box name to use. Tested options are:
# - bigdata/centos6.4_x86_64 - 40G disk space.
# - bigdata/centos6.4_x86_64_small - just 8G of disk space. 
# - bento/centos-6.7 - CentOS6.7 Vagrant box
VM_BOX = "bento/centos-6.7"

# Set the memory (MB) allocated for the AMBARI VM
AMBARI_NODE_VM_MEMORY_MB = "3064"

# Set the memory (MB) allocated for every PHD node VM
PHD_NODE_VM_MEMORY_MB = "2048"

# Set the Ambari host name prefix. The suffix is fixed to '.localdomain'.
# Note: THE FQDN NAME SHOULD NOT be in the phd[1-N].localdomain range.
AMBARI_HOSTNAME_PREFIX = "ambari"

# Set TRUE to deploy a cluster defined with BLUEPRINT_FILE_NAME and HOST_MAPPING_FILE_NAME.
# Set FALSE to stop the installation after the Aambari Server installation. 
DEPLOY_BLUEPRINT_CLUSTER = TRUE

###############################################################################
#    DON'T CHANGE THE CONTENT BELOW
###############################################################################
# Maps provisioning script to the supported stack
INSTALL_AMBARI_STACK = {
  "PHD3.0" => "provision/phd30_install_ambari.sh",
  "PHD3.3" => "provision/phd33_install_ambari.sh",
  "HDP2.2" => "provision/hdp22_install_ambari.sh",
  "HDP2.3" => "provision/hdp23_install_ambari.sh"
}

# Create an Ambari FQDN hostname from the prefix and the localdomain domain. 
AMBARI_HOSTNAME_FQDN = "#{AMBARI_HOSTNAME_PREFIX}.localdomain"

# Parse the blueprint spec
blueprint_spec = JSON.parse(open("blueprints/" + BLUEPRINT_FILE_NAME).read)
BLUEPRINT_NAME = blueprint_spec["Blueprints"]["blueprint_name"]
STACK_NAME = blueprint_spec['Blueprints']['stack_name']
STACK_VERSION = blueprint_spec['Blueprints']['stack_version']
AMBARI_PROVISION_SCRIPT = INSTALL_AMBARI_STACK[STACK_NAME + STACK_VERSION]

# Print deployment info
print "CLUSTER NAME: #{CLUSTER_NAME} \nBLUEPRINT NAME: #{BLUEPRINT_NAME} \n"
print "STACK: #{blueprint_spec['Blueprints']['stack_name']}-#{blueprint_spec['Blueprints']['stack_version']} \n"
print "BLUEPRINT FILE: #{BLUEPRINT_FILE_NAME} \nHOST-MAPPING FILE: #{HOST_MAPPING_FILE_NAME} \n"
print "Ambari Provision Script: #{AMBARI_PROVISION_SCRIPT}\n"

# Read the host-mapping file to extract the blueprint name and the cluster node hostnames
host_mapping = JSON.parse(open("blueprints/" + HOST_MAPPING_FILE_NAME).read)

# Extract the Blueprint name from the host mapping file
HOST_MAPPING_BLUEPRINT_NAME = host_mapping["blueprint"]

# Validate that the Blueprint set in the host mapping file aligns with the name of the blueprint provided
if (BLUEPRINT_NAME != HOST_MAPPING_BLUEPRINT_NAME)
  print "Host-Mapping blueprint name:(#{HOST_MAPPING_BLUEPRINT_NAME}) doesn't match the Blueprint: (#{BLUEPRINT_NAME})! \n"
  exit
end

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
    
    config.vm.define phd_vm_name.to_sym do |phd_conf|
      
      phd_conf.vm.box = VM_BOX
      
      phd_conf.vm.provider :virtualbox do |v|
        v.name = phd_vm_name
        v.customize ["modifyvm", :id, "--memory", PHD_NODE_VM_MEMORY_MB]
      end
      
      phd_conf.vm.provider "vmware_fusion" do |v|
        v.name = phd_vm_name
        v.vmx["memsize"]  = PHD_NODE_VM_MEMORY_MB
      end     	  

      phd_conf.vm.host_name = phd_host_name    
      phd_conf.vm.network :private_network, ip: "10.211.55.#{i + 100}"	  

      phd_conf.vm.provision "shell" do |s|
        s.path = "provision/prepare_host.sh"
        s.args = [AMBARI_HOSTNAME_PREFIX, AMBARI_HOSTNAME_FQDN, NUMBER_OF_CLUSTER_NODES]
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
     v.customize ["modifyvm", :id, "--memory", AMBARI_NODE_VM_MEMORY_MB]
   end

   ambari.vm.provider "vmware_fusion" do |v|
     v.name = AMBARI_VM_NAME
     v.vmx["memsize"]  = AMBARI_NODE_VM_MEMORY_MB
   end  

   ambari.vm.hostname = AMBARI_HOSTNAME_FQDN
   ambari.vm.network :private_network, ip: "10.211.55.100"
#   ambari.vm.network :forwarded_port, guest: 8080, host: 8080

   # Initialization common for all nodes
   ambari.vm.provision "shell" do |s|
     s.path = "provision/prepare_host.sh"
     s.args = [AMBARI_HOSTNAME_PREFIX, AMBARI_HOSTNAME_FQDN, NUMBER_OF_CLUSTER_NODES]
   end
   
   # Install Ambari Server
   ambari.vm.provision "shell" do |s|
     s.path = AMBARI_PROVISION_SCRIPT
   end 

   # Install Redis (Used as Spring XD transport)
   ambari.vm.provision "shell" do |s|
     s.path = "provision/install_redis.sh"
   end 

   # Register the Ambari Agents and all nodes
   ambari.vm.provision "shell" do |s|
     s.path = "provision/register_agents.sh"
     s.args = NUMBER_OF_CLUSTER_NODES
   end

   # Fix hostname FQDN
   ambari.vm.provision :shell, :inline => "hostname " + AMBARI_HOSTNAME_FQDN

   # Deploy Hadoop Cluster & Services as defined in the Blueprint/Host-Mapping files
   if (DEPLOY_BLUEPRINT_CLUSTER)
     ambari.vm.provision "shell" do |s|
       s.path = "provision/deploy_cluster.sh"
       s.args = [AMBARI_HOSTNAME_FQDN, CLUSTER_NAME, BLUEPRINT_NAME,
                 "/vagrant/blueprints/" + BLUEPRINT_FILE_NAME, 
                 "/vagrant/blueprints/" + HOST_MAPPING_FILE_NAME]
     end
   end
  end
end
