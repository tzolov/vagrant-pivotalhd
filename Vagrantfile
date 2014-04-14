# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

require 'set'

# PivotalHD cluster name
CLUSTER_NAME = "phd-c1"

# List of services to deploy. Note: hdfs,yarn and zookeeper services are compulsory! 
SERVICES = ["hdfs", "yarn", "hive", "pig", "zookeeper", "hbase", "gpxf", "hawq", "gfxd", "graphlab"]

# Node(s) to be used as a master. Convention is: 'phd<Number>.localdomain'. Exactly One master node must be provided
MASTER = ["phd1.localdomain"]

# Node(s) to be used as a Workers. Convention is: 'phd<Number>.localdomain'. At least one worker node is required
# The master node can be reused as a worker. 
WORKERS = ["phd1.localdomain", "phd2.localdomain"]

# Some commonly used PHD distributions are predefined below. Select one and assign it to PHD_DISTRIBUTION_TO_INSTALL 
# To install different packages versions put those packages in the Vagrantfile folder and define 
# a custom PHD_DISTRIBUTION_TO_INSTALL. For example: 
# PHD_DISTRIBUTION_TO_INSTALL=["PCC-<your version>", "PHD-<your version>", "PADS-<your version>", "PRTS-<your version>"]
#
# PCC and PHD are compulsory! To disable PADS and/or PRTS use "NA" in place of package name. (e.g. ["PCC-2.1.0-460", 
# "PHD-1.1.0.0-76", "NA", "NA"]).
# Note: When disabling packages be aware that the 'hawq' service requires the PADS package and the 'gfxd' 
#       service requires the PRTS package!

# Community PivotalHD 1.1.0
PHD_110_HAWQ_GFXD = ["PCC-2.1.0-460", "PHD-1.1.0.0-76", "PADS-1.1.3-31", "PRTS-1.0.0-8"]
# PivotalHD 1.1.1 distribution
PHD_111_HAWQ_GFXD = ["PCC-2.1.1-73", "PHD-1.1.1.0-82", "PADS-1.1.4-34", "PRTS-1.0.0-9"]
# PivotalHD 2.0 beta distribution
PHD_20_LATEST_HAWQ_GFXD = ["PCC-2.2.0-175", "PHD-2.0.0.0-144", "PADS-1.2.0.0-7425", "PRTS-1.0.0-14"]	

# Set the distribution to install
PHD_DISTRIBUTION_TO_INSTALL = PHD_20_LATEST_HAWQ_GFXD

# JDK to be installed
JAVA_RPM_PATH = "/vagrant/jdk-7u45-linux-x64.rpm"

# Vagrant box name
#   bigdata/centos6.4_x86_64 - 40G disk space.
#   bigdata/centos6.4_x86_64_small - just 8G of disk space. Not enough for Hue!
VM_BOX = "bigdata/centos6.4_x86_64"

# Memory (MB) allocated for every PHD node VM
PHD_MEMORY_MB = "1536"

# Memory (MB) allocated for the PCC VM
PCC_MEMORY_MB = "768"

# If set to FALSE it will install only PCC
DEPLOY_PHD_CLUSTER = TRUE

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Compute the total number of nodes in the cluster 	    
  NUMBER_OF_CLUSTER_NODES = (MASTER + WORKERS).uniq.size
  
  # Create VM for every PHD node
  (1..NUMBER_OF_CLUSTER_NODES).each do |i|

    phd_vm_name = "phd#{i}"

    config.vm.define phd_vm_name.to_sym do |phd_conf|
      phd_conf.vm.box = VM_BOX
      phd_conf.vm.provider :virtualbox do |v|
        v.name = phd_vm_name
        v.customize ["modifyvm", :id, "--memory", PHD_MEMORY_MB]
      end
      phd_conf.vm.provider "vmware_fusion" do |v|
        v.name = phd_vm_name
        v.vmx["memsize"]  = PHD_MEMORY_MB
      end     	  

      phd_conf.vm.host_name = "phd#{i}.localdomain"    
      phd_conf.vm.network :private_network, ip: "10.211.55.#{i+100}"	  

      phd_conf.vm.provision "shell" do |s|
        s.path = "prepare_all_nodes.sh"
        s.args = NUMBER_OF_CLUSTER_NODES
      end 
	  
      #Fix hostname FQDN
      phd_conf.vm.provision :shell, :inline => "hostname phd#{i}.localdomain"
    end
  end

  # Create PCC VM, install PCC and deploy a PHD cluster
  PCC_VM_NAME = "pcc"
  
  config.vm.define PCC_VM_NAME do |pcc|   
   
   pcc.vm.box = VM_BOX

   pcc.vm.provider :virtualbox do |v|
     v.name = PCC_VM_NAME
     v.customize ["modifyvm", :id, "--memory", PCC_MEMORY_MB]
   end

   pcc.vm.provider "vmware_fusion" do |v|
     v.name = PCC_VM_NAME
     v.vmx["memsize"]  = PCC_MEMORY_MB
   end  

   pcc.vm.hostname = "pcc.localdomain"
   pcc.vm.network :private_network, ip: "10.211.55.100"
   pcc.vm.network :forwarded_port, guest: 5443, host: 5443

   # Initialization common for all nodes
   pcc.vm.provision "shell" do |s|
     s.path = "prepare_all_nodes.sh"
     s.args = NUMBER_OF_CLUSTER_NODES
   end
   
   # Install PCC 
   pcc.vm.provision "shell" do |s|
     s.path = "pcc_install.sh"
     s.args = [JAVA_RPM_PATH] + PHD_DISTRIBUTION_TO_INSTALL
   end 

   # Deploy the PHD cluster
   if (DEPLOY_PHD_CLUSTER)

     # Compute the HDFS replication factor as a function of the number of DataNodes
     HDFS_REPLICATION_FACTOR = [3, WORKERS.uniq.size].min.to_s

     pcc.vm.provision "shell" do |s|
       s.path = "phd_cluster_deploy.sh"
       s.args = [CLUSTER_NAME, SERVICES.uniq.join(","), MASTER.uniq.join(","), WORKERS.uniq.join(","), PHD_MEMORY_MB, JAVA_RPM_PATH, HDFS_REPLICATION_FACTOR]
     end 
   end
   
   # Fix hostname FQDN
   pcc.vm.provision :shell, :inline => "hostname pcc.localdomain"	  
   
   # Fix a bug preventing PCC from showing MapReduce jobs with longer names
   pcc.vm.provision :shell, :inline => "psql -h localhost -p 10432 --username postgres -d gphdmgr -c 'ALTER TABLE app ALTER name TYPE text'"
  end
end
