# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Embedded provisioning script common for all cluster hosts and PCC.
$phd_provision_script = <<SCRIPT
#!/bin/bash

# Install the packages required for all cluster and admin nodes 
yum -y install postgresql-devel nc expect ed ntp dmidecode pciutils

# Set timezone and run NTP (set to Europe - Amsterdam time).
/etc/init.d/ntpd stop; mv /etc/localtime /etc/localtime.bak; ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime; /etc/init.d/ntpd start

cat > /etc/hosts <<EOF 
127.0.0.1     localhost.localdomain    localhost
::1           localhost6.localdomain6  localhost6
 
10.211.55.100 pcc.localdomain  pcc
10.211.55.101 phd1.localdomain phd1
10.211.55.102 phd2.localdomain phd2
10.211.55.103 phd3.localdomain phd3

EOF

SCRIPT

# Community distributed PivotalHD 1.1.0
PHD_110 = ["PCC-2.1.0-460", "PHD-1.1.0.0-76", "NA", "NA"]
PHD_110_HAWQ = ["PCC-2.1.0-460", "PHD-1.1.0.0-76", "PADS-1.1.3-31", "NA"]
PHD_110_HAWQ_GFXD = ["PCC-2.1.0-460", "PHD-1.1.0.0-76", "PADS-1.1.3-31", "PRTS-1.0.0-8"]

# Internal PivotalHD 1.1.1 distribution
PHD_111 = ["PCC-2.1.1-73", "PHD-1.1.1.0-82", "NA", "NA"]
PHD_111_HAWQ = ["PCC-2.1.1-73", "PHD-1.1.1.0-82", "PADS-1.1.4-34", "NA"]
PHD_111_HAWQ_GFXD = ["PCC-2.1.1-73", "PHD-1.1.1.0-82", "PADS-1.1.4-34", "PRTS-1.0.0-9"]

# Internal PivotalHD 2.0 beta distribution
PHD_20_BETA2 = ["PCC-2.2.0-170", "PHD-2.0.0.0-144", "NA", "NA"]
PHD_20_BETA2_HAWQ = ["PCC-2.2.0-170", "PHD-2.0.0.0-144", "NA", "NA"]	
PHD_20_BETA2_HAWQ_GFXD = ["PCC-2.2.0-170", "PHD-2.0.0.0-144", "PADS-1.2.0.0-7252", "PRTS-1.0.0-14"]	



Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define :phd1 do |phd1|
   phd1.vm.box = "CentOS-6.4-x86_64"
   phd1.vm.provider :virtualbox do |v|
    v.name = "phd1"
    v.customize ["modifyvm", :id, "--memory", "1536"]
   end
   phd1.vm.provider "vmware_fusion" do |v|
    v.name = "phd1"
    v.vmx["memsize"]  = "1536"
   end         
   phd1.vm.hostname = "phd1.localdomain"
   phd1.vm.network :private_network, ip: "10.211.55.101"
   phd1.vm.provision :shell, :inline => $phd_provision_script
   phd1.vm.provision :shell, :inline => "hostname phd1.localdomain"
  end

  config.vm.define :phd2 do |phd2|
   phd2.vm.box = "CentOS-6.4-x86_64"
   phd2.vm.provider :virtualbox do |v|
    v.name = "phd2"
    v.customize ["modifyvm", :id, "--memory", "1536"]
   end
   phd2.vm.provider "vmware_fusion" do |v|
    v.name = "phd2"
    v.vmx["memsize"]  = "1536"
   end       
   phd2.vm.hostname = "phd2.localdomain"
   phd2.vm.network :private_network, ip: "10.211.55.102"
   phd2.vm.provision :shell, :inline => $phd_provision_script
   phd2.vm.provision :shell, :inline => "hostname phd2.localdomain"
  end

  config.vm.define :phd3 do |phd3|
   phd3.vm.box = "CentOS-6.4-x86_64"
   phd3.vm.provider :virtualbox do |v|
    v.name = "phd3"
    v.customize ["modifyvm", :id, "--memory", "1536"]
   end
   phd3.vm.provider "vmware_fusion" do |v|
    v.name = "phd3"
    v.vmx["memsize"]  = "1536"
   end       
   phd3.vm.hostname = "phd3.localdomain"
   phd3.vm.network :private_network, ip: "10.211.55.103"
   phd3.vm.provision :shell, :inline => $phd_provision_script
   phd3.vm.provision :shell, :inline => "hostname phd3.localdomain"
  end

  config.vm.define :pcc do |pcc|
   pcc.vm.box = "CentOS-6.4-x86_64"
   pcc.vm.provider :virtualbox do |v|
    v.name = "pcc"
    v.customize ["modifyvm", :id, "--memory", "1024"]
   end
   pcc.vm.provider "vmware_fusion" do |v|
    v.name = "pcc"
    v.vmx["memsize"]  = "1024"
   end  
   pcc.vm.hostname = "pcc.localdomain"
   pcc.vm.network :private_network, ip: "10.211.55.100"
   pcc.vm.network :forwarded_port, guest: 5443, host: 5443
   pcc.vm.provision :shell, :inline => $phd_provision_script
   pcc.vm.provision "shell" do |s|
      s.path = "pcc_provision_phd.sh"
      s.args = PHD_110_HAWQ_GFXD
   end 
   pcc.vm.provision :shell, :inline => "hostname pcc.localdomain"	  
   pcc.vm.provision :shell, :inline => "psql -h localhost -p 10432 --username postgres -d gphdmgr -c 'ALTER TABLE app ALTER name TYPE text'"
  end
end
